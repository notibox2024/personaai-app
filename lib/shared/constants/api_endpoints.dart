import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Enum định nghĩa các môi trường
enum ApiEnvironment {
  development,
  local,
  staging,
  custom,
  production,
}

/// Constants cho API endpoints trong các environment khác nhau
class ApiEndpoints {
  // Private constructor để ngăn khởi tạo
  const ApiEndpoints._();
  
  // Logger instance cho class
  static final Logger _logger = Logger();

  // ============== DEVELOPMENT URLs ==============
  /// URL backend API cho development (Spring Boot)
  static const String devBackendApiUrl = 'http://192.168.2.62:8097';
  
  /// URL data API cho development (postgREST)
  static const String devDataApiUrl = 'http://192.168.2.62:3300';

  // ============== LOCAL DEVELOPMENT URLs ==============
  /// URL backend API cho local development
  static const String localBackendApiUrl = 'http://localhost:8097';
  
  /// URL data API cho local development  
  static const String localDataApiUrl = 'http://localhost:3300';

  // ============== STAGING URLs ==============
  /// URL backend API cho staging
  static const String stagingBackendApiUrl = 'https://api-staging.example.com';
  
  /// URL data API cho staging
  static const String stagingDataApiUrl = 'https://data-staging.example.com';

  // ============== CUSTOM DEVELOPMENT URLs ==============
  /// Cho phép developers set URL riêng cho testing
  /// Thay đổi các giá trị này để test với server riêng
  static const String customBackendApiUrl = 'http://192.168.1.100:8097';
  static const String customDataApiUrl = 'http://192.168.1.100:3300';

  // ============== ENVIRONMENT DETECTION ==============

  /// Môi trường hiện tại - thay đổi để switch environment trong development
  /// Trong production, luôn sử dụng remote config
  static const ApiEnvironment currentEnvironment = ApiEnvironment.development;

  // ============== URL GETTERS ==============
  
  /// Lấy backend URL theo environment hiện tại
  static String getBackendUrl() {
    // Trong production build, luôn return null để force sử dụng remote config
    if (kReleaseMode) {
      throw UnsupportedError('Production build must use remote config');
    }

    switch (currentEnvironment) {
      case ApiEnvironment.development:
        return devBackendApiUrl;
      case ApiEnvironment.local:
        return localBackendApiUrl;
      case ApiEnvironment.staging:
        return stagingBackendApiUrl;
      case ApiEnvironment.custom:
        return customBackendApiUrl;
      case ApiEnvironment.production:
        throw UnsupportedError('Production environment must use remote config');
    }
  }

  /// Lấy data URL theo environment hiện tại
  static String getDataUrl() {
    // Trong production build, luôn return null để force sử dụng remote config
    if (kReleaseMode) {
      throw UnsupportedError('Production build must use remote config');
    }

    switch (currentEnvironment) {
      case ApiEnvironment.development:
        return devDataApiUrl;
      case ApiEnvironment.local:
        return localDataApiUrl;
      case ApiEnvironment.staging:
        return stagingDataApiUrl;
      case ApiEnvironment.custom:
        return customDataApiUrl;
      case ApiEnvironment.production:
        throw UnsupportedError('Production environment must use remote config');
    }
  }

  // ============== UTILITY METHODS ==============
  
  /// Check xem có đang ở development mode không
  static bool get isDevelopmentMode {
    return kDebugMode || kProfileMode;
  }

  /// Check xem có đang ở production mode không
  static bool get isProductionMode {
    return kReleaseMode;
  }

  /// Lấy thông tin environment hiện tại
  static String get currentEnvironmentName {
    if (isProductionMode) return 'production';
    return currentEnvironment.toString().split('.').last;
  }

  /// Lấy cả 2 URL cho logging/debug
  static Map<String, String> getCurrentUrls() {
    if (isProductionMode) {
      return {
        'backend': 'remote_config',
        'data': 'remote_config',
        'environment': 'production'
      };
    }

    return {
      'backend': getBackendUrl(),
      'data': getDataUrl(),
      'environment': currentEnvironmentName,
    };
  }

  // ============== DEVELOPMENT HELPERS ==============
  
  /// Helper cho developers để nhanh chóng switch environment
  /// Chỉ hoạt động trong development mode
  static void printAvailableEnvironments() {
    if (!isDevelopmentMode) return;
    
    _logger.i('=== Available Development Environments ===');
    _logger.i('Current: $currentEnvironmentName');
    _logger.i('');
    _logger.i('Development URLs:');
    _logger.i('  Backend: $devBackendApiUrl');
    _logger.i('  Data: $devDataApiUrl');
    _logger.i('');
    _logger.i('Local URLs:');
    _logger.i('  Backend: $localBackendApiUrl');
    _logger.i('  Data: $localDataApiUrl');
    _logger.i('');
    _logger.i('Staging URLs:');
    _logger.i('  Backend: $stagingBackendApiUrl');
    _logger.i('  Data: $stagingDataApiUrl');
    _logger.i('');
    _logger.i('Custom URLs:');
    _logger.i('  Backend: $customBackendApiUrl');
    _logger.i('  Data: $customDataApiUrl');
    _logger.i('');
    _logger.i('To change environment, update ApiEndpoints.currentEnvironment');
    _logger.i('=========================================');
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Lấy host từ URL
  static String getHostFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}:${uri.port}';
    } catch (e) {
      return url;
    }
  }
} 