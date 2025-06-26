/// Model lưu trữ thông tin phiên đăng nhập
class UserSession {
  final String userId;
  final String email;
  final String? displayName;
  final String? avatar;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime loginAt;
  final bool rememberMe;

  const UserSession({
    required this.userId,
    required this.email,
    this.displayName,
    this.avatar,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.loginAt,
    this.rememberMe = false,
  });

  /// Tạo instance từ JSON
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'],
      avatar: json['avatar'],
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresAt: DateTime.parse(json['expires_at']),
      loginAt: DateTime.parse(json['login_at']),
      rememberMe: json['remember_me'] ?? false,
    );
  }

  /// Convert thành Map
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'avatar': avatar,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'login_at': loginAt.toIso8601String(),
      'remember_me': rememberMe,
    };
  }

  /// Kiểm tra token có hết hạn không
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Kiểm tra token sắp hết hạn (trong vòng 5 phút)
  bool get isNearExpiry {
    final now = DateTime.now();
    final fiveMinutesLater = now.add(const Duration(minutes: 5));
    return fiveMinutesLater.isAfter(expiresAt);
  }

  /// Thời gian còn lại đến khi hết hạn
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Copy với thông tin mới
  UserSession copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? avatar,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? loginAt,
    bool? rememberMe,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      loginAt: loginAt ?? this.loginAt,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  String toString() {
    return 'UserSession(userId: $userId, email: $email, isExpired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSession &&
        other.userId == userId &&
        other.email == email &&
        other.accessToken == accessToken;
  }

  @override
  int get hashCode {
    return Object.hash(userId, email, accessToken);
  }
} 