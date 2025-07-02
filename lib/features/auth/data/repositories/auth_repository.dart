import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/login_request.dart';
import '../models/auth_response.dart';
import '../models/refresh_token_request.dart';
import '../models/logout_request.dart';
import '../models/token_validation_response.dart';
import '../models/user_session.dart';
import '../services/fcm_token_service.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/token_manager.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/constants/remote_config_keys.dart';

/// Enhanced Repository xử lý authentication với real API calls
class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  late final ApiService _apiService;
  late final TokenManager _tokenManager;
  final FcmTokenService _fcmTokenService = FcmTokenService();
  final logger = Logger();
  
  UserSession? _currentSession;
  bool _isInitialized = false;

  /// Initialize repository dependencies
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('AuthRepository already initialized');
      return;
    }
    
    _apiService = ApiService();
    _tokenManager = TokenManager();
    
    _isInitialized = true;
    
    // Load existing session if available
    await _loadExistingSession();
  }

  /// Load existing session from storage
  Future<void> _loadExistingSession() async {
    try {
      final hasValidSession = await _tokenManager.hasValidSession();
      if (hasValidSession) {
        final authResponse = await _tokenManager.getCurrentAuthResponse();
        final userMetadata = await _tokenManager.getUserMetadata();
        
        if (authResponse != null && userMetadata['user_id'] != null) {
          _currentSession = UserSession(
            userId: userMetadata['user_id'] as String,
            email: '${userMetadata['username']}@personaai.com',
            displayName: 'User ${userMetadata['username']}',
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
            loginAt: DateTime.parse(userMetadata['last_login'] ?? DateTime.now().toIso8601String()),
            rememberMe: userMetadata['auto_login_enabled'] ?? false,
          );
          
          logger.i('Existing session loaded for user: ${userMetadata['username']}');
        }
      }
    } catch (e) {
      logger.w('Failed to load existing session: $e');
    }
  }

  /// Đăng nhập với username và password - Real API Call
  Future<AuthResult<AuthResponse>> login(LoginRequest request) async {
    try {
      // Validate request
      if (!request.isValid) {
        return AuthResult.failure(
          request.usernameError ?? request.passwordError ?? 'Dữ liệu không hợp lệ'
        );
      }

      // Switch to backend API mode
      await _apiService.switchToBackendApi();
      
      // Call login API
      final response = await _apiService.post('/api/v1/auth/login', data: request.toJson());
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Save tokens
        await _tokenManager.saveTokens(authResponse);
        
        // Save user metadata
        await _tokenManager.saveUserMetadata(
          userId: 'user_${request.username}',
          username: request.username,
          autoLoginEnabled: true,
        );
        
        // Create user session
        _currentSession = UserSession(
          userId: 'user_${request.username}',
          email: '${request.username}@personaai.com',
          displayName: 'User ${request.username}',
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          expiresAt: authResponse.expiresAt,
          loginAt: DateTime.now(),
          rememberMe: true,
        );
        
        // Update FCM token after successful login (async, không block login flow)
        _fcmTokenService.updateTokenAfterLogin();
        
        logger.i('Login successful for user: ${request.username}');
        return AuthResult.success(authResponse);
        
      } else {
        final errorMessage = response.data['message'] ?? 'Đăng nhập thất bại';
        logger.w('Login failed: $errorMessage');
        return AuthResult.failure(errorMessage);
      }
      
    } on DioException catch (e) {
      String errorMessage;
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác';
      } else if (e.response?.statusCode == 429) {
        errorMessage = 'Quá nhiều lần thử. Vui lòng thử lại sau';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Kết nối timeout. Vui lòng kiểm tra mạng';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server không phản hồi. Vui lòng thử lại';
      } else {
        errorMessage = e.response?.data['message'] ?? 'Lỗi kết nối đến server';
      }
      
      logger.e('Login error: ${e.message}');
      return AuthResult.failure(errorMessage);
      
    } catch (e) {
      logger.e('Unexpected login error: $e');
      return AuthResult.failure('Đã xảy ra lỗi không xác định');
    }
  }

  /// Refresh token - Real API Call
  Future<AuthResult<AuthResponse>> refreshToken() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure('Không có refresh token');
      }

      // Switch to backend API mode
      await _apiService.switchToBackendApi();
      
      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _apiService.post('/api/v1/auth/refresh', data: request.toJson());
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Save new tokens
        await _tokenManager.saveTokens(authResponse);
        
        // Update current session
        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
          );
        }
        
        logger.i('Token refresh successful');
        return AuthResult.success(authResponse);
        
      } else {
        logger.w('Token refresh failed: ${response.statusCode}');
        await _clearSession();
        return AuthResult.failure('Token refresh thất bại');
      }
      
    } on DioException catch (e) {
      logger.e('Token refresh error: ${e.message}');
      await _clearSession();
      return AuthResult.failure('Phiên đăng nhập đã hết hạn');
      
    } catch (e) {
      logger.e('Unexpected refresh error: $e');
      return AuthResult.failure('Lỗi làm mới token');
    }
  }

  /// Đăng xuất - Real API Call
  Future<AuthResult<void>> logout() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      
      if (refreshToken != null) {
        // Switch to backend API mode
        await _apiService.switchToBackendApi();
        
        try {
          final request = LogoutRequest(refreshToken: refreshToken);
          await _apiService.post('/api/v1/auth/logout', data: request.toJson());
          logger.i('Logout API call successful');
        } catch (e) {
          // Continue with local logout even if API call fails
          logger.w('Logout API call failed, continuing with local logout: $e');
        }
      }
      
      // Clear local session regardless of API call result
      await _clearSession();
      logger.i('Local logout successful');
      
      return AuthResult.success(null);
      
    } catch (e) {
      logger.e('Logout error: $e');
      // Still clear local session on error
      await _clearSession();
      return AuthResult.failure('Có lỗi khi đăng xuất');
    }
  }

  /// Validate token - Real API Call
  Future<TokenValidationResponse> validateToken() async {
    try {
      final token = await _tokenManager.getAccessToken();
      if (token == null) {
        return TokenValidationResponse.invalid(message: 'Không có access token');
      }

      // Switch to backend API mode
      await _apiService.switchToBackendApi();
      
      final response = await _apiService.post('/api/v1/auth/validate', data: {
        'accessToken': token,
      });
      
      if (response.statusCode == 200) {
        return TokenValidationResponse.fromJson(response.data);
      } else {
        return TokenValidationResponse.invalid(message: 'Token validation failed');
      }
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return TokenValidationResponse.invalid(message: 'Token không hợp lệ');
      }
      return TokenValidationResponse.invalid(message: 'Lỗi validation token');
      
    } catch (e) {
      logger.e('Token validation error: $e');
      return TokenValidationResponse.invalid(message: 'Lỗi kiểm tra token');
    }
  }

  /// Clear session locally
  Future<void> _clearSession() async {
    try {
      await _tokenManager.clearTokens();
      _currentSession = null;
    } catch (e) {
      logger.e('Error clearing session: $e');
    }
  }

  /// Current user session (getter)
  UserSession? get currentSession => _currentSession;
  
  /// Check if user is logged in
  bool get isLoggedIn => _currentSession != null && !_currentSession!.isExpired;

  /// Update current session (để cập nhật với thông tin profile)
  void updateCurrentSession(UserSession updatedSession) {
    _currentSession = updatedSession;
    logger.d('Current session updated with new information');
  }

  /// Check if should auto-refresh token
  Future<bool> shouldAutoRefresh() async {
    if (!isLoggedIn) return false;
    
    final shouldRefresh = await _tokenManager.shouldRefreshToken();
    final autoRefreshEnabled = FirebaseService().getConfigBool(
      RemoteConfigKeys.enableAutoRefresh, 
      defaultValue: true
    );
    
    return shouldRefresh && autoRefreshEnabled;
  }

  /// Demo validation methods (kept for backward compatibility)
  String? validateUsername(String username) {
    if (username.isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (username.length < 3) return 'Tên đăng nhập tối thiểu 3 ký tự';
    if (username.length > 50) return 'Tên đăng nhập tối đa 50 ký tự';
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    if (password.length > 100) return 'Mật khẩu tối đa 100 ký tự';
    return null;
  }

  /// Get auth status
  Future<AuthStatus> getAuthStatus() async {
    if (!isLoggedIn) return AuthStatus.unauthenticated;
    
    final shouldRefresh = await shouldAutoRefresh();
    if (shouldRefresh) return AuthStatus.needsRefresh;
    
    return AuthStatus.authenticated;
  }
}

/// Auth result wrapper
class AuthResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const AuthResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory AuthResult.success(T data) {
    return AuthResult._(success: true, data: data);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}

/// Auth status enum
enum AuthStatus {
  authenticated,
  unauthenticated,
  needsRefresh,
} 