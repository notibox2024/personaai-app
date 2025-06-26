/// Model cho dữ liệu đăng nhập
class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  /// Convert thành Map để gửi API
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'remember_me': rememberMe,
    };
  }

  /// Tạo instance từ Map
  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      rememberMe: json['remember_me'] ?? false,
    );
  }

  /// Copy với thông tin mới
  LoginRequest copyWith({
    String? email,
    String? password,
    bool? rememberMe,
  }) {
    return LoginRequest(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  String toString() {
    return 'LoginRequest(email: $email, rememberMe: $rememberMe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.email == email &&
        other.password == password &&
        other.rememberMe == rememberMe;
  }

  @override
  int get hashCode {
    return Object.hash(email, password, rememberMe);
  }
} 