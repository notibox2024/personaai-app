/// Model cho response validation token
class TokenValidationResponse {
  final bool valid;
  final String message;

  const TokenValidationResponse({
    required this.valid,
    required this.message,
  });

  /// Tạo instance từ JSON response
  factory TokenValidationResponse.fromJson(Map<String, dynamic> json) {
    return TokenValidationResponse(
      valid: json['valid'] ?? false,
      message: json['message'] ?? '',
    );
  }

  /// Convert thành Map
  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'message': message,
    };
  }

  /// Factory constructors cho common cases
  factory TokenValidationResponse.valid({
    String message = 'Token hợp lệ',
  }) {
    return TokenValidationResponse(
      valid: true,
      message: message,
    );
  }

  factory TokenValidationResponse.invalid({
    String message = 'Token không hợp lệ',
  }) {
    return TokenValidationResponse(
      valid: false,
      message: message,
    );
  }

  @override
  String toString() {
    return 'TokenValidationResponse(valid: $valid, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenValidationResponse &&
        other.valid == valid &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(valid, message);
  }
} 