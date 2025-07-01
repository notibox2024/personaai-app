/// Model cho Auth Response từ backend API theo spec
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType; // "Bearer"
  final int expiresIn; // seconds
  final int refreshExpiresIn; // seconds
  final String scope;
  final String sessionState;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshExpiresIn,
    required this.scope,
    required this.sessionState,
    required this.issuedAt,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });

  /// Tạo instance từ JSON response
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final issuedAt = json['issued_at'] != null 
        ? DateTime.parse(json['issued_at'])
        : DateTime.now();
    
    final expiresAt = json['expires_at'] != null
        ? DateTime.parse(json['expires_at'])
        : issuedAt.add(Duration(seconds: json['expires_in'] ?? 300));
    
    final refreshExpiresAt = json['refresh_expires_at'] != null
        ? DateTime.parse(json['refresh_expires_at'])
        : issuedAt.add(Duration(seconds: json['refresh_expires_in'] ?? 1800));

    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 300,
      refreshExpiresIn: json['refresh_expires_in'] ?? 1800,
      scope: json['scope'] ?? 'openid profile email',
      sessionState: json['session_state'] ?? '',
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      refreshExpiresAt: refreshExpiresAt,
    );
  }

  /// Convert thành Map
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_expires_in': refreshExpiresIn,
      'scope': scope,
      'session_state': sessionState,
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'refresh_expires_at': refreshExpiresAt.toIso8601String(),
    };
  }

  /// Helper methods
  bool get isAccessTokenExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  bool get isRefreshTokenExpired {
    return DateTime.now().isAfter(refreshExpiresAt);
  }

  bool get shouldRefreshToken {
    // Refresh if expires in less than 2 minutes
    return DateTime.now().add(const Duration(minutes: 2)).isAfter(expiresAt);
  }

  Duration get accessTokenTimeLeft {
    final now = DateTime.now();
    return expiresAt.isAfter(now) ? expiresAt.difference(now) : Duration.zero;
  }

  Duration get refreshTokenTimeLeft {
    final now = DateTime.now();
    return refreshExpiresAt.isAfter(now) ? refreshExpiresAt.difference(now) : Duration.zero;
  }

  /// Copy với token mới (dùng cho refresh)
  AuthResponse copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
    int? refreshExpiresIn,
    String? scope,
    String? sessionState,
    DateTime? issuedAt,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
  }) {
    return AuthResponse(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      refreshExpiresIn: refreshExpiresIn ?? this.refreshExpiresIn,
      scope: scope ?? this.scope,
      sessionState: sessionState ?? this.sessionState,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    );
  }

  @override
  String toString() {
    return 'AuthResponse(tokenType: $tokenType, expiresIn: $expiresIn, scope: $scope)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResponse &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.sessionState == sessionState;
  }

  @override
  int get hashCode {
    return Object.hash(accessToken, refreshToken, sessionState);
  }
} 