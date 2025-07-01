import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'device_info_service.dart';
import 'token_manager.dart';
import 'firebase_service.dart';
import '../constants/remote_config_keys.dart';
import '../../features/auth/data/models/auth_response.dart';
import '../../features/auth/data/models/refresh_token_request.dart';

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
  final List<Completer<Response>> _pendingRequests = [];
  String? _currentMode; // 'backend' or 'data'
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
    
    // Get config from Firebase Remote Config
    final backendUrl = FirebaseService().getConfigString(
      RemoteConfigKeys.backendApiUrl, 
      defaultValue: 'http://192.168.2.62:8097'
    );
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
    
    if (kDebugMode) {
      logger.i('ApiService initialized with base URL: ${_dio.options.baseUrl}');
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
          
          if (_currentMode == 'data') {
            // Data API always needs token
            needsToken = true;
          } else if (_currentMode == 'backend') {
            // Backend API needs token except for auth endpoints
            final path = options.path;
            final isAuthEndpoint = path.startsWith('/api/v1/auth/');
            needsToken = !isAuthEndpoint;
          }
          
          if (needsToken) {
            final token = await _tokenManager.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              if (kDebugMode) {
                logger.d('Added auth token for ${options.method} ${options.path}');
              }
            } else if (kDebugMode) {
              logger.w('No access token available for ${options.method} ${options.path}');
            }
          } else if (kDebugMode) {
            logger.d('Skipping auth token for ${options.method} ${options.path} (auth endpoint)');
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
        // Only handle 401 errors for data API calls
        if (error.response?.statusCode == 401 && _currentMode == 'data') {
          if (!_isRefreshing) {
            await _handle401Error(error, handler);
            return;
          } else {
            // If already refreshing, queue this request
            await _queueRequest(error, handler);
            return;
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
      
      // Try to refresh token
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        // No refresh token, redirect to login
        _clearAuthAndRedirect();
        return handler.next(error);
      }
      
      // Switch to backend API mode to refresh token
      final originalMode = _currentMode;
      await switchToBackendApi();
      
      try {
        // Call refresh token endpoint
        final response = await _dio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
        });
        
        if (response.statusCode == 200) {
          final authResponse = AuthResponse.fromJson(response.data);
          await _tokenManager.saveTokens(authResponse);
          
          // Switch back to original mode
          if (originalMode == 'data') {
            await switchToDataApi();
          }
          
          // Retry the original request
          final requestOptions = error.requestOptions;
          final token = await _tokenManager.getAccessToken();
          if (token != null) {
            requestOptions.headers['Authorization'] = 'Bearer $token';
          }
          
          final retryResponse = await _dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        } else {
          throw Exception('Token refresh failed: ${response.statusCode}');
        }
      } catch (refreshError) {
        logger.e('Token refresh failed: $refreshError');
        _clearAuthAndRedirect();
        return handler.next(error);
      }
    } catch (e) {
      logger.e('Error handling 401: $e');
      return handler.next(error);
    } finally {
      _isRefreshing = false;
      _processPendingRequests();
    }
  }

  /// Queue request while token is being refreshed
  Future<void> _queueRequest(DioException error, ErrorInterceptorHandler handler) async {
    final completer = Completer<Response>();
    _pendingRequests.add(completer);
    
    try {
      final response = await completer.future;
      return handler.resolve(response);
    } catch (e) {
      return handler.next(error);
    }
  }

  /// Process pending requests after token refresh
  void _processPendingRequests() async {
    final token = await _tokenManager.getAccessToken();
    
    for (final completer in _pendingRequests) {
      try {
        // This would need the original request options
        // For now, we'll just complete with an error
        completer.completeError(DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Request failed after token refresh',
        ));
      } catch (e) {
        completer.completeError(e);
      }
    }
    
    _pendingRequests.clear();
  }

  /// Clear authentication and redirect to login
  void _clearAuthAndRedirect() async {
    try {
      await _tokenManager.clearTokens();
      // TODO: Navigate to login page
      logger.i('Authentication cleared, should redirect to login');
    } catch (e) {
      logger.e('Error clearing auth: $e');
    }
  }

  /// Switch to backend API mode
  Future<void> switchToBackendApi() async {
    final backendUrl = FirebaseService().getConfigString(
      RemoteConfigKeys.backendApiUrl,
      defaultValue: 'http://192.168.2.62:8097'
    );
    
    _dio.options.baseUrl = backendUrl;
    _currentMode = 'backend';
    
    if (kDebugMode) {
      logger.i('Switched to backend API: $backendUrl');
    }
  }

  /// Switch to data API mode
  Future<void> switchToDataApi() async {
    final dataUrl = FirebaseService().getConfigString(
      RemoteConfigKeys.dataApiUrl,
      defaultValue: 'http://192.168.2.62:3300'
    );
    
    _dio.options.baseUrl = dataUrl;
    _currentMode = 'data';
    
    if (kDebugMode) {
      logger.i('Switched to data API: $dataUrl');
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