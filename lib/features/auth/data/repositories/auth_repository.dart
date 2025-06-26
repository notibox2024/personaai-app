import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_session.dart';

/// Repository xử lý các chức năng xác thực
class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();
  UserSession? _currentSession;

  /// Đăng nhập với email và mật khẩu
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      // Mô phỏng API call (thay thế bằng API thực tế)
      await Future.delayed(const Duration(seconds: 2));

      // Kiểm tra thông tin đăng nhập demo
      if (_isValidDemoCredentials(request.email, request.password)) {
        final now = DateTime.now();
        final expiresAt = now.add(const Duration(hours: 24));
        
        // Tạo session
        _currentSession = UserSession(
          userId: 'demo_user_001',
          email: request.email,
          displayName: 'Người dùng Demo',
          accessToken: 'demo_access_token_${now.millisecondsSinceEpoch}',
          refreshToken: 'demo_refresh_token_${now.millisecondsSinceEpoch}',
          expiresAt: expiresAt,
          loginAt: now,
          rememberMe: request.rememberMe,
        );

        return LoginResponse.success(
          accessToken: _currentSession!.accessToken,
          refreshToken: _currentSession!.refreshToken,
          userData: {
            'user_id': _currentSession!.userId,
            'email': _currentSession!.email,
            'display_name': _currentSession!.displayName,
          },
          expiresAt: expiresAt,
        );
      } else {
        return LoginResponse.failure(
          message: 'Email hoặc mật khẩu không chính xác',
        );
      }
         } on Exception catch (e) {
       return LoginResponse.failure(
         message: 'Lỗi kết nối: ${e.toString()}',
       );
    } catch (e) {
      return LoginResponse.failure(
        message: 'Đã xảy ra lỗi không xác định',
      );
    }
  }

  /// Đăng xuất
  Future<bool> logout() async {
    try {
      // Mô phỏng API call để invalidate token
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentSession = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh token
  Future<LoginResponse> refreshToken() async {
    if (_currentSession == null) {
      return LoginResponse.failure(message: 'Không có phiên đăng nhập');
    }

    try {
      // Mô phỏng API call
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      final newExpiresAt = now.add(const Duration(hours: 24));
      
      _currentSession = _currentSession!.copyWith(
        accessToken: 'refreshed_token_${now.millisecondsSinceEpoch}',
        expiresAt: newExpiresAt,
      );

      return LoginResponse.success(
        accessToken: _currentSession!.accessToken,
        refreshToken: _currentSession!.refreshToken,
        expiresAt: newExpiresAt,
      );
    } catch (e) {
      return LoginResponse.failure(
        message: 'Không thể làm mới token',
      );
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  bool get isLoggedIn => _currentSession != null && !_currentSession!.isExpired;

  /// Lấy session hiện tại
  UserSession? get currentSession => _currentSession;

  /// Kiểm tra thông tin đăng nhập demo
  bool _isValidDemoCredentials(String email, String password) {
    // Demo credentials
    const validCredentials = [
      {'email': 'demo@kienlongbank.com', 'password': '123456'},
      {'email': 'admin@kienlongbank.com', 'password': 'admin123'},
      {'email': 'test@kienlongbank.com', 'password': 'test123'},
    ];

    return validCredentials.any((cred) => 
      cred['email'] == email && cred['password'] == password
    );
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Lấy thông báo lỗi validate
  String? validateEmail(String email) {
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!isValidEmail(email)) return 'Email không hợp lệ';
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!isValidPassword(password)) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }
} 