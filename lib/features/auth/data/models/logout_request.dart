/// Model cho request đăng xuất
class LogoutRequest {
  final String refreshToken;

  const LogoutRequest({
    required this.refreshToken,
  });

  /// Validation
  String? get refreshTokenError {
    if (refreshToken.isEmpty) return 'Refresh token không được để trống';
    return null;
  }

  bool get isValid => refreshTokenError == null;

  /// Convert thành Map để gửi API
  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }

  /// Tạo instance từ Map
  factory LogoutRequest.fromJson(Map<String, dynamic> json) {
    return LogoutRequest(
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  @override
  String toString() {
    return 'LogoutRequest(refreshToken: ${refreshToken.substring(0, 20)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogoutRequest && other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return refreshToken.hashCode;
  }
} 