import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý tất cả các API calls sử dụng Dio
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final CancelToken _cancelToken = CancelToken();

  /// Khởi tạo Dio với cấu hình cơ bản
  void initialize({
    String baseUrl = 'https://api.personaai.com', // Thay đổi theo API thực tế
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 5),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
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
  }

  /// Thiết lập các interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('🚀 REQUEST: ${options.method} ${options.uri}');
            print('📝 Headers: ${options.headers}');
            if (options.data != null) {
              print('📦 Data: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
            print('📄 Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('❌ ERROR: ${error.message}');
            print('🔍 Type: ${error.type}');
            if (error.response != null) {
              print('📊 Status: ${error.response?.statusCode}');
              print('📄 Data: ${error.response?.data}');
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Thêm LogInterceptor cho debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
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