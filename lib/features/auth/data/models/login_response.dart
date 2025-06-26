/// Model cho phản hồi từ API đăng nhập
class LoginResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? userData;
  final DateTime? expiresAt;

  const LoginResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.userData,
    this.expiresAt,
  });

  /// Tạo instance từ JSON response
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      userData: json['user_data'] as Map<String, dynamic>?,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
    );
  }

  /// Convert thành Map
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_data': userData,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Tạo response thành công
  factory LoginResponse.success({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? userData,
    DateTime? expiresAt,
    String message = 'Đăng nhập thành công',
  }) {
    return LoginResponse(
      success: true,
      message: message,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userData: userData,
      expiresAt: expiresAt,
    );
  }

  /// Tạo response lỗi
  factory LoginResponse.failure({
    required String message,
  }) {
    return LoginResponse(
      success: false,
      message: message,
    );
  }

  @override
  String toString() {
    return 'LoginResponse(success: $success, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginResponse &&
        other.success == success &&
        other.message == message &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return Object.hash(success, message, accessToken, refreshToken);
  }
} 