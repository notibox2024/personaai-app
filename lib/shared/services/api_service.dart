import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'device_info_service.dart';
import 'token_manager.dart';
import 'firebase_service.dart';
import '../constants/remote_config_keys.dart';
import '../constants/api_endpoints.dart';
import '../../features/auth/data/models/auth_response.dart';
import '../../features/auth/data/models/refresh_token_request.dart';

/// Callback type for navigation when authentication is required
typedef AuthRequiredCallback = void Function();

/// Pending request item for queuing during token refresh
class PendingRequestItem {
  final DioException originalError;
  final ErrorInterceptorHandler handler;
  final DateTime queuedAt;

  PendingRequestItem({
    required this.originalError,
    required this.handler,
    required this.queuedAt,
  });
}

/// Enhanced API Service với interceptors cho authentication và device headers
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  late final DeviceInfoService _deviceInfoService;
  late final TokenManager _tokenManager;
  final CancelToken _cancelToken = CancelToken();
  final logger = Logger();
  
  // State management
  bool _isRefreshing = false;
  final List<PendingRequestItem> _pendingRequests = [];
  String? _currentMode; // 'backend' or 'data'
  
  // Navigation callback for auth required scenarios
  AuthRequiredCallback? _onAuthRequired;
  
  // Constants
  static const Duration _pendingRequestTimeout = Duration(minutes: 2);
  static const String _refreshEndpointPath = '/api/v1/auth/refresh';
  
  // Auth endpoints that should NOT trigger token refresh when 401
  static const List<String> _authEndpoints = [
    '/api/v1/auth/login',
    '/api/v1/auth/logout', 
    '/api/v1/auth/refresh',
    '/api/v1/auth/register',
    '/api/v1/auth/forgot-password',
    '/api/v1/auth/reset-password',
    '/api/v1/auth/verify-otp',
  ];
  
  /// Initialize ApiService với enhanced configuration
  Future<void> initialize({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) async {
    // Initialize dependencies
    _deviceInfoService = DeviceInfoService();
    _tokenManager = TokenManager();
    
    // Get backend URL based on environment
    String backendUrl;
    if (ApiEndpoints.isProductionMode) {
      // Production: sử dụng remote config
      backendUrl = FirebaseService().getConfigString(
        RemoteConfigKeys.backendApiUrl, 
        defaultValue: 'http://192.168.2.62:8097'
      );
    } else {
      // Development: sử dụng constants
      backendUrl = ApiEndpoints.getBackendUrl();
    }
    
    final timeoutSeconds = FirebaseService().getConfigInt(
      RemoteConfigKeys.apiTimeoutSeconds, 
      defaultValue: 30
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? backendUrl,
        connectTimeout: connectTimeout ?? Duration(seconds: timeoutSeconds),
        receiveTimeout: receiveTimeout ?? Duration(seconds: timeoutSeconds + 15),
        sendTimeout: sendTimeout ?? Duration(seconds: timeoutSeconds - 5),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
        receiveDataWhenStatusError: true,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    _setupInterceptors();
    
    // Set default mode to backend API
    _currentMode = 'backend';
    
    if (kDebugMode) {
      final envInfo = ApiEndpoints.isProductionMode ? 'remote config' : ApiEndpoints.currentEnvironmentName;
      logger.i('ApiService initialized with base URL: ${_dio.options.baseUrl} (from $envInfo)');
      logger.i('Default API mode set to: $_currentMode');
      
      // Print environment info for developers
      if (ApiEndpoints.isDevelopmentMode) {
        final urls = ApiEndpoints.getCurrentUrls();
        logger.i('Current environment URLs:');
        logger.i('  Backend: ${urls['backend']}');
        logger.i('  Data: ${urls['data']}');
        logger.i('  Environment: ${urls['environment']}');
        logger.i('To change URLs, update ApiEndpoints.currentEnvironment');
      }
    }
  }

  /// Setup 4 interceptors theo thứ tự: Device Headers → Auth Token → Error Handling → Logging
  void _setupInterceptors() {
    // 1. Device Headers Interceptor (always first)
    _dio.interceptors.add(_createDeviceHeadersInterceptor());
    
    // 2. Auth Token Interceptor
    _dio.interceptors.add(_createAuthTokenInterceptor());
    
    // 3. Error Handling Interceptor (401 retry)
    _dio.interceptors.add(_createErrorHandlingInterceptor());
    
    // 4. Logging Interceptor (debug only, always last)
    if (kDebugMode) {
      _dio.interceptors.add(_createLoggingInterceptor());
    }
  }

  /// 1. Device Headers Interceptor
  Interceptor _createDeviceHeadersInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Add device headers to all requests
          final deviceHeaders = await _deviceInfoService.getAllHeaders();
          options.headers.addAll(deviceHeaders);
          
          if (kDebugMode && deviceHeaders.isNotEmpty) {
            logger.d('Added ${deviceHeaders.length} device headers');
          }
        } catch (e) {
          // Don't block request if device headers fail
          logger.w('Failed to add device headers: $e');
        }
        
        return handler.next(options);
      },
    );
  }

  /// 2. Auth Token Interceptor
  Interceptor _createAuthTokenInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Determine if this endpoint needs auth token
          bool needsToken = false;
          String modeInfo = '';
          
          if (_currentMode == 'data') {
            // Data API always needs token
            needsToken = true;
            modeInfo = 'data API';
          } else if (_currentMode == 'backend') {
            // Backend API needs token except for auth endpoints
            needsToken = !_isAuthEndpoint(options.path);
            modeInfo = needsToken ? 'backend API' : 'auth endpoint';
          } else {
            // Default to backend mode if not set (fallback)
            needsToken = !_isAuthEndpoint(options.path);
            modeInfo = needsToken ? 'default backend API' : 'auth endpoint';
            if (kDebugMode) {
              logger.w('API mode not set, defaulting to backend for ${options.path}');
            }
          }
          
          if (needsToken) {
            final token = await _tokenManager.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              if (kDebugMode) {
                logger.d('Added auth token for ${options.method} ${options.path} ($modeInfo)');
              }
            } else if (kDebugMode) {
              logger.w('No access token available for ${options.method} ${options.path} ($modeInfo)');
            }
          } else if (kDebugMode) {
            logger.d('Skipping auth token for ${options.method} ${options.path} ($modeInfo)');
          }
        } catch (e) {
          logger.w('Failed to add auth token: $e');
        }
        
        return handler.next(options);
      },
    );
  }

  /// 3. Error Handling Interceptor (401 retry with refresh)
  Interceptor _createErrorHandlingInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Only handle 401 errors for data API calls or non-auth backend endpoints
        if (error.response?.statusCode == 401) {
          final requestPath = error.requestOptions.path;
          
          // Check if this is an auth endpoint that should NOT trigger refresh
          if (_isAuthEndpoint(requestPath)) {
            if (requestPath.contains(_refreshEndpointPath)) {
              logger.e('Refresh endpoint returned 401 - clearing auth and redirecting to login');
            } else {
              logger.w('Auth endpoint returned 401: $requestPath - not triggering refresh');
            }
            _clearAuthAndRedirect();
            return handler.next(error);
          }
          
          // Handle different scenarios based on current mode
          bool shouldHandle = false;
          if (_currentMode == 'data') {
            shouldHandle = true; // Data API always needs token
          } else if (_currentMode == 'backend') {
            shouldHandle = true; // Non-auth backend endpoints need token refresh
          } else {
            // Default to backend mode behavior if not set
            shouldHandle = true;
            if (kDebugMode) {
              logger.w('API mode not set during 401 handling, defaulting to backend behavior');
            }
          }
          
          if (shouldHandle) {
            if (!_isRefreshing) {
              await _handle401Error(error, handler);
              return;
            } else {
              // If already refreshing, queue this request
              await _queueRequest(error, handler);
              return;
            }
          }
        }
        
        return handler.next(error);
      },
    );
  }

  /// 4. Logging Interceptor (debug only) - with sensitive data masking
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        logger.i('🚀 ${options.method} ${options.uri}');
        logger.d('📝 Headers: ${_maskSensitiveHeaders(options.headers)}');
        if (options.data != null) {
          logger.d('📦 Data: ${_maskSensitiveData(options.data)}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        logger.i('✅ ${response.statusCode} ${response.requestOptions.uri}');
        logger.d('📄 Response: ${_maskSensitiveData(response.data)}');
        return handler.next(response);
      },
      onError: (error, handler) {
        logger.e('❌ ${error.response?.statusCode} ${error.requestOptions.uri}');
        logger.e('🔍 Error: ${error.message}');
        if (error.response?.data != null) {
          logger.e('📄 Error Data: ${_maskSensitiveData(error.response?.data)}');
        }
        return handler.next(error);
      },
    );
  }

  /// Mask sensitive data in headers
  Map<String, dynamic> _maskSensitiveHeaders(Map<String, dynamic> headers) {
    final maskedHeaders = Map<String, dynamic>.from(headers);
    
    // Sensitive headers to mask
    const sensitiveHeaderKeys = [
      'authorization',
      'Authorization',
      'AUTHORIZATION',
      'x-api-key',
      'X-API-Key',
      'x-auth-token',
      'X-Auth-Token',
    ];
    
    for (final key in sensitiveHeaderKeys) {
      if (maskedHeaders.containsKey(key)) {
        final value = maskedHeaders[key]?.toString() ?? '';
        if (value.isNotEmpty) {
          // Show only first 10 chars and last 4 chars for tokens
          if (value.length > 20) {
            maskedHeaders[key] = '${value.substring(0, 10)}***...***${value.substring(value.length - 4)}';
          } else {
            maskedHeaders[key] = '***MASKED***';
          }
        }
      }
    }
    
    return maskedHeaders;
  }

  /// Mask sensitive data in request/response body
  dynamic _maskSensitiveData(dynamic data) {
    if (data == null) return null;
    
    // Handle Map/JSON objects
    if (data is Map<String, dynamic>) {
      final maskedData = Map<String, dynamic>.from(data);
      
      // Sensitive fields to mask
      const sensitiveFields = [
        'password',
        'Password',
        'PASSWORD',
        'newPassword',
        'oldPassword',
        'confirmPassword',
        'currentPassword',
        'accessToken',
        'access_token',
        'refreshToken',
        'refresh_token',
        'token',
        'Token',
        'TOKEN',
        'apiKey',
        'api_key',
        'secret',
        'Secret',
        'SECRET',
        'pin',
        'Pin',
        'PIN',
        'otp',
        'Otp',
        'OTP',
        'ssn',
        'socialSecurityNumber',
        'creditCardNumber',
        'cardNumber',
        'cvv',
        'cvc',
      ];
      
      for (final field in sensitiveFields) {
        if (maskedData.containsKey(field)) {
          final value = maskedData[field]?.toString() ?? '';
          if (value.isNotEmpty) {
            // Different masking strategies based on field type
            if (['password', 'Password', 'PASSWORD', 'newPassword', 'oldPassword', 
                 'confirmPassword', 'currentPassword', 'pin', 'Pin', 'PIN',
                 'otp', 'Otp', 'OTP', 'cvv', 'cvc'].contains(field)) {
              maskedData[field] = '***HIDDEN***';
            } else if (['accessToken', 'access_token', 'refreshToken', 'refresh_token',
                      'token', 'Token', 'TOKEN', 'apiKey', 'api_key'].contains(field)) {
              // Show partial token for debugging
              if (value.length > 20) {
                maskedData[field] = '${value.substring(0, 8)}***...***${value.substring(value.length - 4)}';
              } else {
                maskedData[field] = '***TOKEN***';
              }
            } else {
              // For other sensitive fields
              maskedData[field] = '***MASKED***';
            }
          }
        }
      }
      
      // Recursively mask nested objects
      for (final key in maskedData.keys) {
        if (maskedData[key] is Map || maskedData[key] is List) {
          maskedData[key] = _maskSensitiveData(maskedData[key]);
        }
      }
      
      return maskedData;
    }
    
    // Handle List/Array
    if (data is List) {
      return data.map((item) => _maskSensitiveData(item)).toList();
    }
    
    // Return primitive types as-is
    return data;
  }

  /// Handle 401 errors with token refresh
  Future<void> _handle401Error(DioException error, ErrorInterceptorHandler handler) async {
    try {
      _isRefreshing = true;
      logger.i('Handling 401 error - attempting token refresh');
      
      // Try to refresh token
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        logger.w('No refresh token available');
        _clearAuthAndRedirect();
        return handler.next(error);
      }
      
      // Switch to backend API mode to refresh token
      final originalMode = _currentMode;
      await switchToBackendApi();
      
      try {
        // Call refresh token endpoint
        final request = RefreshTokenRequest(refreshToken: refreshToken);
        final response = await _dio.post(_refreshEndpointPath, data: request.toJson());
        
        if (response.statusCode == 200) {
          final authResponse = AuthResponse.fromJson(response.data);
          await _tokenManager.saveTokens(authResponse);
          
          logger.i('Token refresh successful');
          
          // Switch back to original mode
          if (originalMode == 'data') {
            await switchToDataApi();
          } else if (originalMode != null) {
            _currentMode = originalMode;
          }
          
          // Retry the original request with new token
          final success = await _retryOriginalRequest(error, handler);
          if (!success) {
            logger.w('Failed to retry original request after token refresh');
            return handler.next(error);
          }
          
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            message: 'Token refresh failed with status: ${response.statusCode}',
            response: response,
          );
        }
      } catch (refreshError) {
        logger.e('Token refresh failed: $refreshError');
        _clearAuthAndRedirect();
        return handler.next(error);
      }
    } catch (e) {
      logger.e('Error handling 401: $e');
      _clearAuthAndRedirect();
      return handler.next(error);
    } finally {
      _isRefreshing = false;
      await _processPendingRequests();
    }
  }

  /// Retry original request with new token
  Future<bool> _retryOriginalRequest(DioException error, ErrorInterceptorHandler handler) async {
    try {
      final requestOptions = error.requestOptions.copyWith();
      final token = await _tokenManager.getAccessToken();
      
      if (token != null) {
        requestOptions.headers['Authorization'] = 'Bearer $token';
      }
      
      final retryResponse = await _dio.fetch(requestOptions);
      handler.resolve(retryResponse);
      return true;
    } catch (retryError) {
      logger.e('Failed to retry original request: $retryError');
      return false;
    }
  }

  /// Queue request while token is being refreshed
  Future<void> _queueRequest(DioException error, ErrorInterceptorHandler handler) async {
    final pendingItem = PendingRequestItem(
      originalError: error,
      handler: handler,
      queuedAt: DateTime.now(),
    );
    
    _pendingRequests.add(pendingItem);
    logger.d('Queued request: ${error.requestOptions.method} ${error.requestOptions.path}');
    
    // Clean up old pending requests to prevent memory leaks
    _cleanupOldPendingRequests();
  }

  /// Clean up old pending requests that have been waiting too long
  void _cleanupOldPendingRequests() {
    final now = DateTime.now();
    final toRemove = <PendingRequestItem>[];
    
    for (final item in _pendingRequests) {
      final waitTime = now.difference(item.queuedAt);
      if (waitTime > _pendingRequestTimeout) {
        toRemove.add(item);
        logger.w('Removing expired pending request: ${item.originalError.requestOptions.path}');
        
        // Complete with timeout error
        item.handler.next(DioException(
          requestOptions: item.originalError.requestOptions,
          message: 'Request timeout while waiting for token refresh',
          type: DioExceptionType.receiveTimeout,
        ));
      }
    }
    
    for (final item in toRemove) {
      _pendingRequests.remove(item);
    }
  }

  /// Process pending requests after token refresh
  Future<void> _processPendingRequests() async {
    if (_pendingRequests.isEmpty) return;
    
    logger.i('Processing ${_pendingRequests.length} pending requests');
    final token = await _tokenManager.getAccessToken();
    
    // Process all pending requests
    final requestsToProcess = List<PendingRequestItem>.from(_pendingRequests);
    _pendingRequests.clear();
    
    for (final item in requestsToProcess) {
      try {
        final requestOptions = item.originalError.requestOptions.copyWith();
        
        // Add new token if available
        if (token != null) {
          requestOptions.headers['Authorization'] = 'Bearer $token';
        }
        
        // Retry the request
        final retryResponse = await _dio.fetch(requestOptions);
        item.handler.resolve(retryResponse);
        
        logger.d('Successfully retried: ${requestOptions.method} ${requestOptions.path}');
        
      } catch (retryError) {
        logger.e('Failed to retry pending request: $retryError');
        
        // If retry fails, pass the original error
        if (retryError is DioException && retryError.response?.statusCode == 401) {
          // Still 401 after refresh - auth is completely invalid
          item.handler.next(item.originalError);
        } else {
          // Other error during retry
          item.handler.next(retryError is DioException ? retryError : item.originalError);
        }
      }
    }
    
    logger.i('Finished processing pending requests');
  }

  /// Clear authentication and redirect to login
  void _clearAuthAndRedirect() async {
    try {
      logger.w('Clearing authentication and redirecting to login');
      await _tokenManager.clearTokens();
      
      // Clear any pending requests
      final pendingRequests = List<PendingRequestItem>.from(_pendingRequests);
      _pendingRequests.clear();
      
      // Complete pending requests with auth error
      for (final item in pendingRequests) {
        item.handler.next(DioException(
          requestOptions: item.originalError.requestOptions,
          message: 'Authentication required',
          response: Response(
            requestOptions: item.originalError.requestOptions,
            statusCode: 401,
            statusMessage: 'Authentication required',
          ),
        ));
      }
      
      // Trigger navigation callback
      if (_onAuthRequired != null) {
        _onAuthRequired!();
      } else {
        logger.w('No auth required callback set - cannot redirect to login');
      }
      
    } catch (e) {
      logger.e('Error clearing auth: $e');
    }
  }

  /// Switch to backend API mode
  Future<void> switchToBackendApi() async {
    String backendUrl;
    if (ApiEndpoints.isProductionMode) {
      // Production: sử dụng remote config
      backendUrl = FirebaseService().getConfigString(
        RemoteConfigKeys.backendApiUrl,
        defaultValue: 'http://192.168.2.62:8097'
      );
    } else {
      // Development: sử dụng constants
      backendUrl = ApiEndpoints.getBackendUrl();
    }
    
    _dio.options.baseUrl = backendUrl;
    _currentMode = 'backend';
    
    if (kDebugMode) {
      final envInfo = ApiEndpoints.isProductionMode ? 'remote config' : ApiEndpoints.currentEnvironmentName;
      logger.i('Switched to backend API: $backendUrl (from $envInfo)');
    }
  }

  /// Switch to data API mode
  Future<void> switchToDataApi() async {
    String dataUrl;
    if (ApiEndpoints.isProductionMode) {
      // Production: sử dụng remote config
      dataUrl = FirebaseService().getConfigString(
        RemoteConfigKeys.dataApiUrl,
        defaultValue: 'http://192.168.2.62:3300'
      );
    } else {
      // Development: sử dụng constants
      dataUrl = ApiEndpoints.getDataUrl();
    }
    
    _dio.options.baseUrl = dataUrl;
    _currentMode = 'data';
    
    if (kDebugMode) {
      final envInfo = ApiEndpoints.isProductionMode ? 'remote config' : ApiEndpoints.currentEnvironmentName;
      logger.i('Switched to data API: $dataUrl (from $envInfo)');
    }
  }

  /// Set base URL manually
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
    if (kDebugMode) {
      logger.i('Base URL set to: $url');
    }
  }

  /// Thêm Authorization token vào headers
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Xóa Authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String? filename,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filename ?? filePath.split('/').last,
        ),
        if (data != null) ...data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken ?? _cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken ?? _cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Hủy tất cả requests
  void cancelRequests([String? reason]) {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel(reason ?? 'Request cancelled');
    }
  }

  /// Xử lý lỗi API
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Kết nối bị timeout',
          statusCode: null,
          type: ApiExceptionType.connectionTimeout,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Gửi dữ liệu bị timeout',
          statusCode: null,
          type: ApiExceptionType.sendTimeout,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Nhận dữ liệu bị timeout',
          statusCode: null,
          type: ApiExceptionType.receiveTimeout,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: error.response?.data?['message'] ?? 'Lỗi từ server',
          statusCode: error.response?.statusCode,
          type: ApiExceptionType.serverError,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request đã bị hủy',
          statusCode: null,
          type: ApiExceptionType.cancelled,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Không có kết nối internet',
          statusCode: null,
          type: ApiExceptionType.noConnection,
        );
      default:
        return ApiException(
          message: error.message ?? 'Lỗi không xác định',
          statusCode: null,
          type: ApiExceptionType.unknown,
        );
    }
  }

  /// Check if a request path is an auth endpoint that should not trigger token refresh
  bool _isAuthEndpoint(String requestPath) {
    return _authEndpoints.any((endpoint) => requestPath.contains(endpoint));
  }

  /// Set callback cho khi cần authentication (redirect to login)
  void setAuthRequiredCallback(AuthRequiredCallback? callback) {
    _onAuthRequired = callback;
    if (kDebugMode) {
      logger.d('Auth required callback ${callback != null ? 'set' : 'cleared'}');
    }
  }
}

/// Custom exception cho API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  const ApiException({
    required this.message,
    this.statusCode,
    required this.type,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Loại lỗi API
enum ApiExceptionType {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  serverError,
  cancelled,
  noConnection,
  unknown,
} 