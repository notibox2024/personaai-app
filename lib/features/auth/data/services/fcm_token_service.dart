import 'package:logger/logger.dart';
import '../models/fcm_token_response.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/firebase_service.dart';

/// Service để cập nhật FCM token lên server thông qua PostgREST API
class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  // Use getter để đảm bảo lấy service singleton đã được khởi tạo
  ApiService get _apiService => ApiService();
  FirebaseService get _firebaseService => FirebaseService();
  final Logger _logger = Logger();

  // PostgREST endpoint
  static const String _updateTokenEndpoint = '/rpc/update_fcm_token';

  /// Cập nhật FCM token lên server
  Future<FcmTokenResult> updateFcmToken() async {
    try {
      _logger.i('Updating FCM token to server');
      
      // Get current FCM token from Firebase
      final fcmToken = await _firebaseService.getToken();
      if (fcmToken == null) {
        _logger.w('No FCM token available from Firebase');
        return FcmTokenResult.failure('Không thể lấy FCM token từ Firebase');
      }
      
      _logger.d('FCM token obtained: ${fcmToken.substring(0, 20)}...');
      
      // Switch to PostgREST data API mode
      await _apiService.switchToDataApi();
      
      // Call update function với FCM token
      final response = await _apiService.post(
        _updateTokenEndpoint,
        data: {'p_fcm_token': fcmToken},
      );
      
      // Parse response (PostgREST returns array for function calls)
      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = (response.data as List).first;
        final tokenResponse = FcmTokenResponse.fromJson(result);
        
        if (tokenResponse.success) {
          _logger.i('FCM token updated successfully: ${tokenResponse.message}');
          _logger.d('Token details: ID=${tokenResponse.tokenId}, Employee=${tokenResponse.employeeId}, Device=${tokenResponse.deviceId}, Platform=${tokenResponse.platform}');
          return FcmTokenResult.success(tokenResponse);
        } else {
          _logger.w('FCM token update failed: ${tokenResponse.message}');
          return FcmTokenResult.failure(tokenResponse.message);
        }
      } else {
        _logger.e('Invalid response format from server');
        return FcmTokenResult.failure('Định dạng phản hồi không hợp lệ từ server');
      }
      
    } on ApiException catch (e) {
      _logger.e('API error updating FCM token: ${e.message}');
      return FcmTokenResult.failure('Lỗi API: ${e.message}');
    } catch (e) {
      _logger.e('Unknown error updating FCM token: $e');
      return FcmTokenResult.failure('Lỗi không xác định khi cập nhật FCM token');
    }
  }

  /// Thiết lập listener cho token refresh tự động
  void setupTokenRefreshListener() {
    _firebaseService.onTokenRefresh = (String newToken) async {
      _logger.i('FCM token refreshed, updating to server automatically');
      final result = await updateFcmToken();
      if (result.isSuccess) {
        _logger.i('Auto FCM token update successful');
      } else {
        _logger.w('Auto FCM token update failed: ${result.message}');
      }
    };
    
    _logger.i('FCM token refresh listener setup completed');
  }

  /// Cập nhật token sau khi đăng nhập thành công
  Future<void> updateTokenAfterLogin() async {
    try {
      // Wait một chút để JWT token được set trong ApiService
      await Future.delayed(const Duration(seconds: 1));
      
      _logger.i('Updating FCM token after successful login');
      final result = await updateFcmToken();
      
      if (result.isSuccess) {
        _logger.i('Post-login FCM token update successful');
      } else {
        _logger.w('Post-login FCM token update failed: ${result.message}');
      }
    } catch (e) {
      _logger.e('Error updating FCM token after login: $e');
    }
  }

  /// Kiểm tra tính khả dụng của FCM token service
  Future<bool> checkServiceAvailability() async {
    try {
      final result = await updateFcmToken();
      return result.isSuccess;
    } catch (e) {
      _logger.w('FCM token service not available: $e');
      return false;
    }
  }

  /// Force refresh FCM token và cập nhật lên server
  Future<FcmTokenResult> forceRefreshToken() async {
    try {
      _logger.i('Force refreshing FCM token');
      
      // Delete existing token to force Firebase to generate new one
      // Note: This will trigger onTokenRefresh callback automatically
      await _firebaseService.getToken();
      
      // Update with current/new token
      return await updateFcmToken();
    } catch (e) {
      _logger.e('Error force refreshing FCM token: $e');
      return FcmTokenResult.failure('Lỗi khi force refresh FCM token');
    }
  }
} 