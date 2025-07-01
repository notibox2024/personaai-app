/// Model cho dữ liệu đăng nhập theo API spec
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  /// Validation theo API spec
  String? get usernameError {
    if (username.isEmpty) return 'Tên đăng nhập không được để trống';
    if (username.length < 3) return 'Tên đăng nhập phải có ít nhất 3 ký tự';
    if (username.length > 50) return 'Tên đăng nhập không được vượt quá 50 ký tự';
    return null;
  }

  String? get passwordError {
    if (password.isEmpty) return 'Mật khẩu không được để trống';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    if (password.length > 100) return 'Mật khẩu không được vượt quá 100 ký tự';
    return null;
  }

  /// Kiểm tra dữ liệu hợp lệ
  bool get isValid => usernameError == null && passwordError == null;

  /// Convert thành Map để gửi API
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  /// Tạo instance từ Map
  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  /// Copy với thông tin mới
  LoginRequest copyWith({
    String? username,
    String? password,
  }) {
    return LoginRequest(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'LoginRequest(username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode {
    return Object.hash(username, password);
  }
} 