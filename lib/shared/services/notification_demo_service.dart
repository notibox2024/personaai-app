import '../../features/notifications/data/models/notification_item.dart';
import '../../features/notifications/data/repositories/local_notification_repository.dart';

/// Service để tạo demo notifications
class NotificationDemoService {
  static final _instance = NotificationDemoService._internal();
  factory NotificationDemoService() => _instance;
  NotificationDemoService._internal();
  
  late LocalNotificationRepository _repository;
  
  void initialize() {
    _repository = LocalNotificationRepository();
  }
  
  Future<void> addDemoNotifications() async {
    final now = DateTime.now();
    
    final demoNotifications = [
      NotificationItem(
        id: 'demo_001',
        title: 'Nhắc nhở chấm công',
        message: 'Bạn chưa chấm công vào hôm nay. Vui lòng chấm công trước 9:00 AM.',
        type: NotificationType.attendance,
        status: NotificationStatus.unread,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(minutes: 30)),
        senderName: 'Hệ thống HR',
        isActionable: true,
        actionUrl: '/attendance/check-in',
      ),
      
      NotificationItem(
        id: 'demo_002',
        title: 'Khóa học mới đã được thêm',
        message: 'Khóa học "Kỹ năng giao tiếp hiệu quả" đã được thêm vào chương trình đào tạo.',
        type: NotificationType.training,
        status: NotificationStatus.unread,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 2)),
        senderName: 'Phòng Đào tạo',
        isActionable: true,
        actionUrl: '/training/register',
      ),
      
      NotificationItem(
        id: 'demo_003',
        title: 'KHẨN CẤP: Sự cố hệ thống',
        message: 'Hệ thống đang gặp sự cố, vui lòng kiên nhẫn.',
        type: NotificationType.urgent,
        status: NotificationStatus.unread,
        priority: NotificationPriority.urgent,
        createdAt: now.subtract(const Duration(hours: 1)),
        senderName: 'IT Support',
        isActionable: true,
      ),
    ];
    
    for (final notification in demoNotifications) {
      try {
        await _repository.insertNotification(notification);
      } catch (e) {
        // Ignore if already exists
      }
    }
  }
} 