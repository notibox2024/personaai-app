import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/auth/data/services/fcm_token_service.dart';
import '../../lib/features/auth/data/models/fcm_token_response.dart';

void main() {
  group('FcmTokenService Tests', () {
    late FcmTokenService fcmTokenService;

    setUp(() {
      fcmTokenService = FcmTokenService();
    });

    test('should create FCM token service instance', () {
      expect(fcmTokenService, isNotNull);
      expect(fcmTokenService, isA<FcmTokenService>());
    });

    test('FcmTokenResponse should parse JSON correctly', () {
      // Test JSON parsing
      final json = {
        'success': true,
        'message': 'FCM token được cập nhật thành công',
        'token_id': 123,
        'employee_id': 456,
        'device_id': 'test-device-123',
        'platform': 'android',
      };

      final response = FcmTokenResponse.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'FCM token được cập nhật thành công');
      expect(response.tokenId, 123);
      expect(response.employeeId, 456);
      expect(response.deviceId, 'test-device-123');
      expect(response.platform, 'android');
    });

    test('FcmTokenResult.success should create successful result', () {
      final tokenResponse = FcmTokenResponse(
        success: true,
        message: 'Success',
        tokenId: 123,
        employeeId: 456,
        deviceId: 'device123',
        platform: 'android',
      );

      final result = FcmTokenResult.success(tokenResponse);

      expect(result.isSuccess, true);
      expect(result.message, 'Success');
      expect(result.data, tokenResponse);
    });

    test('FcmTokenResult.failure should create failed result', () {
      const errorMessage = 'Token update failed';
      final result = FcmTokenResult.failure(errorMessage);

      expect(result.isSuccess, false);
      expect(result.message, errorMessage);
      expect(result.data, isNull);
    });

    test('FcmTokenResponse equality should work correctly', () {
      const response1 = FcmTokenResponse(
        success: true,
        message: 'Success',
        tokenId: 123,
        employeeId: 456,
        deviceId: 'device123',
        platform: 'android',
      );

      const response2 = FcmTokenResponse(
        success: true,
        message: 'Success',
        tokenId: 123,
        employeeId: 456,
        deviceId: 'device123',
        platform: 'android',
      );

      const response3 = FcmTokenResponse(
        success: false,
        message: 'Failed',
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });

    test('FcmTokenResponse should convert to JSON correctly', () {
      const response = FcmTokenResponse(
        success: true,
        message: 'Success',
        tokenId: 123,
        employeeId: 456,
        deviceId: 'device123',
        platform: 'android',
      );

      final json = response.toJson();

      expect(json['success'], true);
      expect(json['message'], 'Success');
      expect(json['token_id'], 123);
      expect(json['employee_id'], 456);
      expect(json['device_id'], 'device123');
      expect(json['platform'], 'android');
    });
  });
} 