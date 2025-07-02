/// Response model cho function mobile_api.update_fcm_token
class FcmTokenResponse {
  final bool success;
  final String message;
  final int? tokenId;
  final int? employeeId;
  final String? deviceId;
  final String? platform;

  const FcmTokenResponse({
    required this.success,
    required this.message,
    this.tokenId,
    this.employeeId,
    this.deviceId,
    this.platform,
  });

  factory FcmTokenResponse.fromJson(Map<String, dynamic> json) {
    return FcmTokenResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tokenId: json['token_id'],
      employeeId: json['employee_id'],
      deviceId: json['device_id'],
      platform: json['platform'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token_id': tokenId,
      'employee_id': employeeId,
      'device_id': deviceId,
      'platform': platform,
    };
  }

  @override
  String toString() {
    return 'FcmTokenResponse(success: $success, message: $message, tokenId: $tokenId, employeeId: $employeeId, deviceId: $deviceId, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FcmTokenResponse &&
      other.success == success &&
      other.message == message &&
      other.tokenId == tokenId &&
      other.employeeId == employeeId &&
      other.deviceId == deviceId &&
      other.platform == platform;
  }

  @override
  int get hashCode {
    return success.hashCode ^
      message.hashCode ^
      tokenId.hashCode ^
      employeeId.hashCode ^
      deviceId.hashCode ^
      platform.hashCode;
  }
}

/// Result wrapper cho FCM token operations
class FcmTokenResult {
  final bool isSuccess;
  final String message;
  final FcmTokenResponse? data;

  const FcmTokenResult._({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  /// Tạo result thành công với data
  factory FcmTokenResult.success(FcmTokenResponse data) {
    return FcmTokenResult._(
      isSuccess: true,
      message: data.message,
      data: data,
    );
  }

  /// Tạo result thất bại với error message
  factory FcmTokenResult.failure(String message) {
    return FcmTokenResult._(
      isSuccess: false,
      message: message,
    );
  }

  @override
  String toString() {
    return 'FcmTokenResult(isSuccess: $isSuccess, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FcmTokenResult &&
      other.isSuccess == isSuccess &&
      other.message == message &&
      other.data == data;
  }

  @override
  int get hashCode => isSuccess.hashCode ^ message.hashCode ^ data.hashCode;
}

/// Exception cho FCM Token operations
class FcmTokenException implements Exception {
  final String message;
  final FcmTokenExceptionType type;
  final Object? originalException;

  const FcmTokenException({
    required this.message,
    required this.type,
    this.originalException,
  });

  @override
  String toString() => 'FcmTokenException: $message (Type: $type)';
}

/// Loại lỗi FCM Token
enum FcmTokenExceptionType {
  firebaseError,
  apiError,
  networkError,
  tokenNotFound,
  authenticationError,
  serverError,
  unknown,
} 