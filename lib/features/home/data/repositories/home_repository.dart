import '../../../../shared/shared_exports.dart';
import '../models/employee_info.dart';
import '../models/attendance_info.dart';
import '../models/monthly_stats.dart';
import '../models/notification_item.dart';
import '../models/upcoming_event.dart';

/// Repository quản lý dữ liệu cho trang chủ
class HomeRepository {
  final ApiService _apiService = ApiService();

  /// Lấy thông tin nhân viên
  Future<EmployeeInfo> getEmployeeInfo() async {
    try {
      final response = await _apiService.get('/employee/profile');
      
      // Parse dữ liệu từ API response
      return EmployeeInfo.fromJson(response.data);
    } on ApiException catch (e) {
      // Xử lý lỗi API cụ thể
      throw Exception('Không thể lấy thông tin nhân viên: ${e.message}');
    } catch (e) {
      // Xử lý lỗi khác
      throw Exception('Lỗi không xác định khi lấy thông tin nhân viên');
    }
  }

  /// Lấy thông tin chấm công hôm nay
  Future<AttendanceInfo> getTodayAttendance() async {
    try {
      final response = await _apiService.get('/attendance/today');
      
      return AttendanceInfo.fromJson(response.data);
    } on ApiException catch (e) {
      throw Exception('Không thể lấy thông tin chấm công: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy thông tin chấm công');
    }
  }

  /// Lấy thống kê tháng hiện tại
  Future<MonthlyStats> getMonthlyStats() async {
    try {
      final response = await _apiService.get('/stats/monthly');
      
      return MonthlyStats.fromJson(response.data);
    } on ApiException catch (e) {
      throw Exception('Không thể lấy thống kê tháng: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy thống kê tháng');
    }
  }

  /// Lấy danh sách thông báo
  Future<List<NotificationItem>> getNotifications({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      
      final List<dynamic> data = response.data['notifications'] ?? [];
      return data.map((json) => NotificationItem.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw Exception('Không thể lấy danh sách thông báo: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách thông báo');
    }
  }

  /// Lấy danh sách sự kiện sắp tới
  Future<List<UpcomingEvent>> getUpcomingEvents({
    int limit = 5,
  }) async {
    try {
      final response = await _apiService.get(
        '/events/upcoming',
        queryParameters: {
          'limit': limit,
        },
      );
      
      final List<dynamic> data = response.data['events'] ?? [];
      return data.map((json) => UpcomingEvent.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw Exception('Không thể lấy danh sách sự kiện: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy danh sách sự kiện');
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.put(
        '/notifications/$notificationId/read',
        data: {'isRead': true},
      );
    } on ApiException catch (e) {
      throw Exception('Không thể đánh dấu thông báo đã đọc: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi đánh dấu thông báo');
    }
  }

  /// Gửi feedback hoặc yêu cầu hỗ trợ
  Future<void> sendFeedback({
    required String subject,
    required String message,
    String? category,
  }) async {
    try {
      await _apiService.post(
        '/feedback',
        data: {
          'subject': subject,
          'message': message,
          if (category != null) 'category': category,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on ApiException catch (e) {
      throw Exception('Không thể gửi feedback: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi gửi feedback');
    }
  }

  /// Làm mới tất cả dữ liệu trang chủ
  Future<Map<String, dynamic>> refreshHomeData() async {
    try {
      // Gọi nhiều API song song để tối ưu hiệu suất
      final results = await Future.wait([
        getEmployeeInfo(),
        getTodayAttendance(),
        getMonthlyStats(),
        getNotifications(limit: 5),
        getUpcomingEvents(limit: 3),
      ]);

      return {
        'employee': results[0] as EmployeeInfo,
        'attendance': results[1] as AttendanceInfo,
        'monthlyStats': results[2] as MonthlyStats,
        'notifications': results[3] as List<NotificationItem>,
        'events': results[4] as List<UpcomingEvent>,
      };
    } catch (e) {
      throw Exception('Không thể làm mới dữ liệu trang chủ: $e');
    }
  }
} 