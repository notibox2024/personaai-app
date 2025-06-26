import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import '../lib/shared/services/firebase_service.dart';
import '../lib/shared/services/background_message_handler.dart';
import '../lib/features/notifications/data/models/notification_item.dart';
import '../lib/features/notifications/data/repositories/local_notification_repository.dart';
import '../lib/shared/database/database_helper.dart';

void main() {
  group('Firebase Service Tests', () {
    late LocalNotificationRepository repository;
    
    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    });
    
    setUp(() async {
      // Delete any existing test database
      await DatabaseHelper.instance.deleteDatabase();
      repository = LocalNotificationRepository();
    });
    
    tearDown(() async {
      await DatabaseHelper.instance.deleteDatabase();
    });

    group('Background Message Handler', () {
      test('should validate notification data structure', () {
        // Valid data
        final validData = {
          'title': 'Test Notification',
          'body': 'Test message',
          'type': 'attendance',
          'priority': 'high',
        };
        
        expect(BackgroundNotificationService.isValidNotificationData(validData), isTrue);
        
        // Invalid data - missing title
        final invalidData1 = {
          'body': 'Test message',
          'type': 'attendance',
        };
        
        expect(BackgroundNotificationService.isValidNotificationData(invalidData1), isFalse);
        
        // Invalid data - empty title
        final invalidData2 = {
          'title': '',
          'body': 'Test message',
        };
        
        expect(BackgroundNotificationService.isValidNotificationData(invalidData2), isFalse);
        
        // Invalid notification type
        final invalidData3 = {
          'title': 'Test',
          'body': 'Test message',
          'type': 'invalid_type',
        };
        
        expect(BackgroundNotificationService.isValidNotificationData(invalidData3), isFalse);
      });
      
      test('should create notification from data', () {
        final data = {
          'id': 'test_123',
          'title': 'Test Notification',
          'body': 'This is a test message',
          'type': 'training',
          'priority': 'urgent',
          'action_url': '/training/register',
          'sender_name': 'Test Sender',
          'is_actionable': 'true',
        };
        
        final notification = BackgroundNotificationService.createNotificationFromData(data);
        
        expect(notification.id, equals('test_123'));
        expect(notification.title, equals('Test Notification'));
        expect(notification.message, equals('This is a test message'));
        expect(notification.type, equals(NotificationType.training));
        expect(notification.priority, equals(NotificationPriority.urgent));
        expect(notification.actionUrl, equals('/training/register'));
        expect(notification.senderName, equals('Test Sender'));
        expect(notification.isActionable, isTrue);
      });
      
      test('should get notification statistics', () async {
        // Add test notifications
        final notifications = [
          NotificationItem(
            id: 'notif_1',
            title: 'Test 1',
            message: 'Message 1',
            type: NotificationType.attendance,
            priority: NotificationPriority.high,
            createdAt: DateTime.now(),
          ),
          NotificationItem(
            id: 'notif_2',
            title: 'Test 2',
            message: 'Message 2',
            type: NotificationType.training,
            priority: NotificationPriority.normal,
            createdAt: DateTime.now(),
            status: NotificationStatus.read,
          ),
        ];
        
        for (final notification in notifications) {
          await repository.insertNotification(notification);
        }
        
        final stats = await BackgroundNotificationService.getNotificationStats();
        
        expect(stats['total_notifications'], equals(2));
        expect(stats['unread_notifications'], equals(1));
        expect(stats['counts_by_type']['attendance'], equals(1));
        expect(stats['counts_by_type']['training'], equals(1));
        expect(stats.containsKey('last_updated'), isTrue);
      });
      
      test('should process missed notifications', () async {
        final now = DateTime.now();
        
        // Add recent unread notifications
        final recentNotifications = [
          NotificationItem(
            id: 'recent_1',
            title: 'Recent 1',
            message: 'Recent message 1',
            type: NotificationType.general,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          NotificationItem(
            id: 'recent_2',
            title: 'Recent 2',
            message: 'Recent message 2',
            type: NotificationType.attendance,
            createdAt: now.subtract(const Duration(hours: 4)),
          ),
        ];
        
        // Add old notification (should not be included)
        final oldNotification = NotificationItem(
          id: 'old_1',
          title: 'Old notification',
          message: 'Old message',
          type: NotificationType.general,
          createdAt: now.subtract(const Duration(days: 2)),
        );
        
        for (final notification in [...recentNotifications, oldNotification]) {
          await repository.insertNotification(notification);
        }
        
        final missedNotifications = await BackgroundNotificationService.processMissedNotifications();
        
        expect(missedNotifications.length, equals(2));
        expect(missedNotifications.any((n) => n.id == 'recent_1'), isTrue);
        expect(missedNotifications.any((n) => n.id == 'recent_2'), isTrue);
        expect(missedNotifications.any((n) => n.id == 'old_1'), isFalse);
      });
      
      test('should perform background cleanup', () async {
        final now = DateTime.now();
        
        // Add old archived notifications (should be cleaned up)
        final oldArchivedNotifications = [
          NotificationItem(
            id: 'old_archived_1',
            title: 'Old Archived 1',
            message: 'Message 1',
            type: NotificationType.general,
            status: NotificationStatus.archived,
            createdAt: now.subtract(const Duration(days: 35)),
          ),
          NotificationItem(
            id: 'old_archived_2',
            title: 'Old Archived 2',
            message: 'Message 2',
            type: NotificationType.training,
            status: NotificationStatus.archived,
            createdAt: now.subtract(const Duration(days: 40)),
          ),
        ];
        
        // Add recent notifications (should not be cleaned up)
        final recentNotifications = [
          NotificationItem(
            id: 'recent_1',
            title: 'Recent 1',
            message: 'Recent message',
            type: NotificationType.attendance,
            status: NotificationStatus.read,
            createdAt: now.subtract(const Duration(days: 10)),
          ),
          NotificationItem(
            id: 'recent_unread',
            title: 'Recent Unread',
            message: 'Unread message',
            type: NotificationType.urgent,
            createdAt: now.subtract(const Duration(days: 35)),
          ),
        ];
        
        for (final notification in [...oldArchivedNotifications, ...recentNotifications]) {
          await repository.insertNotification(notification);
        }
        
        // Verify initial count
        final initialCount = await repository.getTotalCount();
        expect(initialCount, equals(4));
        
        // Perform cleanup
        await BackgroundNotificationService.performBackgroundCleanup();
        
        // Verify cleanup results
        final finalCount = await repository.getTotalCount();
        expect(finalCount, equals(2)); // Only recent notifications should remain
        
        // Verify specific notifications remain
        final remainingNotifications = await repository.getFilteredNotifications(limit: 10);
        final remainingIds = remainingNotifications.map((n) => n.id).toSet();
        
        expect(remainingIds.contains('recent_1'), isTrue);
        expect(remainingIds.contains('recent_unread'), isTrue);
        expect(remainingIds.contains('old_archived_1'), isFalse);
        expect(remainingIds.contains('old_archived_2'), isFalse);
      });
    });
    
    group('Message Processing', () {
      test('should parse RemoteMessage correctly', () {
        // This would require mocking RemoteMessage which is complex
        // For now, we test the data parsing logic indirectly through createNotificationFromData
        
        final testData = {
          'title': 'Firebase Notification',
          'body': 'This is from Firebase',
          'type': 'leave',
          'priority': 'high',
          'action_url': '/leave/view',
          'sender_id': 'manager_123',
          'sender_name': 'John Manager',
          'is_actionable': 'true',
          'created_at': DateTime.now().millisecondsSinceEpoch.toString(),
          'metadata': '{"employee_id": "emp_456", "department": "IT"}',
        };
        
        final notification = BackgroundNotificationService.createNotificationFromData(testData);
        
        expect(notification.title, equals('Firebase Notification'));
        expect(notification.message, equals('This is from Firebase'));
        expect(notification.type, equals(NotificationType.leave));
        expect(notification.priority, equals(NotificationPriority.high));
        expect(notification.actionUrl, equals('/leave/view'));
        expect(notification.senderId, equals('manager_123'));
        expect(notification.senderName, equals('John Manager'));
        expect(notification.isActionable, isTrue);
        expect(notification.metadata, isA<Map<String, dynamic>>());
        expect(notification.metadata!['employee_id'], equals('emp_456'));
      });
      
      test('should handle invalid data gracefully', () {
        final invalidData = {
          'title': 'Test',
          'body': 'Test message',
          'type': 'invalid_type',
          'priority': 'invalid_priority',
          'created_at': 'invalid_timestamp',
          'metadata': 'invalid_json',
          'is_actionable': 'invalid_boolean',
        };
        
        final notification = BackgroundNotificationService.createNotificationFromData(invalidData);
        
        // Should fallback to default values
        expect(notification.type, equals(NotificationType.general));
        expect(notification.priority, equals(NotificationPriority.normal));
        expect(notification.metadata, isNull);
        expect(notification.isActionable, isFalse);
      });
    });
    
    group('Integration Tests', () {
      test('should handle complete notification flow', () async {
        // Simulate receiving a notification
        final testData = {
          'title': 'Integration Test',
          'body': 'Testing complete flow',
          'type': 'system',
          'priority': 'urgent',
          'action_url': '/system/maintenance',
          'sender_name': 'System Admin',
          'is_actionable': 'true',
        };
        
        // Create notification
        final notification = BackgroundNotificationService.createNotificationFromData(testData);
        
        // Save to database
        await repository.insertNotification(notification);
        
        // Verify it was saved
        final savedNotification = await repository.getNotification(notification.id);
        expect(savedNotification, isNotNull);
        expect(savedNotification!.title, equals('Integration Test'));
        
        // Check unread count
        final unreadCount = await repository.getUnreadCount();
        expect(unreadCount, equals(1));
        
        // Mark as read
        await repository.updateNotificationStatus(notification.id, NotificationStatus.read);
        
        // Verify read status
        final updatedNotification = await repository.getNotification(notification.id);
        expect(updatedNotification!.status, equals(NotificationStatus.read));
        
        // Check unread count after read
        final newUnreadCount = await repository.getUnreadCount();
        expect(newUnreadCount, equals(0));
      });
    });
  });
} 