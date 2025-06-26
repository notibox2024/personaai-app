import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:personaai/shared/database/database_helper.dart';
import 'package:personaai/features/notifications/data/repositories/local_notification_repository.dart';
import 'package:personaai/features/notifications/data/models/notification_item.dart';
import 'package:personaai/features/notifications/data/models/notification_extensions.dart';

void main() {
  group('Notification Database Tests', () {
    late LocalNotificationRepository repository;
    
    setUpAll(() {
      // Initialize SQLite for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });
    
    setUp(() {
      repository = LocalNotificationRepository();
    });
    
    tearDown(() async {
      // Clean up after each test
      await DatabaseHelper.instance.deleteDatabase();
    });
    
    test('should create database and tables successfully', () async {
      // Act & Assert - database should be created without errors
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
      
      // Check database info
      final info = await DatabaseHelper.instance.getDatabaseInfo();
      expect(info['tables'], contains('notifications'));
      expect(info['database_name'], equals('personaai.db'));
    });
    
    test('should insert and retrieve notification', () async {
      // Arrange
      final notification = NotificationItem(
        id: 'test_001',
        title: 'Test Notification',
        message: 'This is a test notification',
        type: NotificationType.general,
        createdAt: DateTime.now(),
        isActionable: true,
        actionUrl: '/general/details',
      );
      
      // Act
      await repository.insertNotification(notification);
      final retrieved = await repository.getNotification('test_001');
      
      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test_001'));
      expect(retrieved.title, equals('Test Notification'));
      expect(retrieved.type, equals(NotificationType.general));
      expect(retrieved.status, equals(NotificationStatus.unread));
    });
    
    test('should update notification status', () async {
      // Arrange
      final notification = NotificationItem(
        id: 'test_002',
        title: 'Test Notification 2',
        message: 'Another test notification',
        type: NotificationType.attendance,
        createdAt: DateTime.now(),
      );
      
      await repository.insertNotification(notification);
      
      // Act
      await repository.updateNotificationStatus(
        'test_002',
        NotificationStatus.read,
      );
      
      // Assert
      final updated = await repository.getNotification('test_002');
      expect(updated!.status, equals(NotificationStatus.read));
      expect(updated.readAt, isNotNull);
    });
    
    test('should filter notifications correctly', () async {
      // Arrange
      final notifications = [
        NotificationItem(
          id: 'att_001',
          title: 'Attendance Reminder',
          message: 'Please check in',
          type: NotificationType.attendance,
          priority: NotificationPriority.high,
          createdAt: DateTime.now(),
        ),
        NotificationItem(
          id: 'train_001',
          title: 'Training Available',
          message: 'New course available',
          type: NotificationType.training,
          priority: NotificationPriority.normal,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        NotificationItem(
          id: 'urgent_001',
          title: 'Urgent Notice',
          message: 'System maintenance',
          type: NotificationType.urgent,
          priority: NotificationPriority.urgent,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      
      await repository.insertNotifications(notifications);
      
      // Act - filter by type
      final attendanceNotifications = await repository.getFilteredNotifications(
        types: {NotificationType.attendance},
      );
      
      // Assert
      expect(attendanceNotifications.length, equals(1));
      expect(attendanceNotifications.first.type, equals(NotificationType.attendance));
      
      // Act - filter by priority
      final urgentNotifications = await repository.getFilteredNotifications(
        priority: NotificationPriority.urgent,
      );
      
      // Assert
      expect(urgentNotifications.length, equals(1));
      expect(urgentNotifications.first.priority, equals(NotificationPriority.urgent));
    });
    
    test('should get correct counts', () async {
      // Arrange
      final notifications = [
        NotificationItem(
          id: 'count_001',
          title: 'Unread 1',
          message: 'Test',
          type: NotificationType.general,
          createdAt: DateTime.now(),
          status: NotificationStatus.unread,
        ),
        NotificationItem(
          id: 'count_002',
          title: 'Unread 2',
          message: 'Test',
          type: NotificationType.general,
          createdAt: DateTime.now(),
          status: NotificationStatus.unread,
        ),
        NotificationItem(
          id: 'count_003',
          title: 'Read 1',
          message: 'Test',
          type: NotificationType.general,
          createdAt: DateTime.now(),
          status: NotificationStatus.read,
        ),
      ];
      
      await repository.insertNotifications(notifications);
      
      // Act & Assert
      final totalCount = await repository.getTotalCount();
      expect(totalCount, equals(3));
      
      final unreadCount = await repository.getUnreadCount();
      expect(unreadCount, equals(2));
    });
    
    test('should test dynamic action button text', () {
      // Arrange & Act
      final attendanceNotification = NotificationItem(
        id: 'action_001',
        title: 'Check-in Reminder',
        message: 'Time to check in',
        type: NotificationType.attendance,
        createdAt: DateTime.now(),
        isActionable: true,
        actionUrl: '/attendance/check-in',
      );
      
      final trainingNotification = NotificationItem(
        id: 'action_002',
        title: 'Course Available',
        message: 'Register for new course',
        type: NotificationType.training,
        createdAt: DateTime.now(),
        isActionable: true,
        actionUrl: '/training/register',
      );
      
      final fallbackNotification = NotificationItem(
        id: 'action_003',
        title: 'General Notice',
        message: 'Some general notice',
        type: NotificationType.general,
        createdAt: DateTime.now(),
        isActionable: true,
        actionUrl: '/invalid/url',
      );
      
      // Assert
      expect(attendanceNotification.actionButtonText, equals('Chấm công vào'));
      expect(trainingNotification.actionButtonText, equals('Đăng ký khóa học'));
      expect(fallbackNotification.actionButtonText, equals('Xem chi tiết'));
    });
    

  });
} 