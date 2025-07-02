import 'package:logger/logger.dart';
import '../models/user_profile.dart';
import '../../../../shared/services/api_service.dart';

/// Service để lấy thông tin user profile từ data API
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  // Use getter để đảm bảo lấy ApiService singleton đã được khởi tạo
  ApiService get _apiService => ApiService();
  final Logger _logger = Logger();

  // Data API endpoint
  static const String _getCurrentUserProfileEndpoint = '/rpc/get_current_user_profile';

  /// Lấy thông tin profile của user hiện tại từ data API
  Future<UserProfile> getCurrentUserProfile() async {
    try {
      _logger.i('Fetching current user profile from data API');
      
      // Switch to data API mode (postgREST)
      await _apiService.switchToDataApi();
      
      // Gọi data API với authentication (JWT token sẽ được tự động thêm)
      final response = await _apiService.post(_getCurrentUserProfileEndpoint);
      
      // Response là một array, lấy phần tử đầu tiên
      if (response.data is List && (response.data as List).isNotEmpty) {
        final userData = (response.data as List).first;
        final userProfile = UserProfile.fromJson(userData);
        
        _logger.i('User profile fetched successfully: ${userProfile.fullName} (${userProfile.empCode})');
        return userProfile;
      } else {
        throw UserProfileException(
          message: 'Không tìm thấy thông tin user profile',
          type: UserProfileExceptionType.notFound,
        );
      }
      
    } on ApiException catch (e) {
      _logger.e('Data API error when fetching user profile: ${e.message}');
      throw UserProfileException(
        message: 'Không thể lấy thông tin profile: ${e.message}',
        type: UserProfileExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      _logger.e('Unknown error when fetching user profile: $e');
      throw UserProfileException(
        message: 'Lỗi không xác định khi lấy thông tin profile',
        type: UserProfileExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Kiểm tra tính khả dụng của data API
  Future<bool> checkDataApiAvailability() async {
    try {
      await getCurrentUserProfile();
      return true;
    } catch (e) {
      _logger.w('Data API not available for user profile: $e');
      return false;
    }
  }

  /// Refresh thông tin user profile
  Future<UserProfile?> refreshUserProfile() async {
    try {
      return await getCurrentUserProfile();
    } catch (e) {
      _logger.w('Failed to refresh user profile: $e');
      return null;
    }
  }
}

/// Custom exception cho User Profile service
class UserProfileException implements Exception {
  final String message;
  final UserProfileExceptionType type;
  final Object? originalException;

  const UserProfileException({
    required this.message,
    required this.type,
    this.originalException,
  });

  @override
  String toString() => 'UserProfileException: $message (Type: $type)';
}

/// Loại lỗi User Profile
enum UserProfileExceptionType {
  notFound,
  apiError,
  unauthorized,
  unknown,
} 