import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../../features/notifications/data/repositories/local_notification_repository.dart';
import '../../features/notifications/data/models/notification_item.dart';
import '../../features/notifications/data/models/notification_extensions.dart';
import 'dart:convert';

/// Top-level function để handle background FCM messages
/// Required để chạy khi app ở background hoặc terminated state
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (kDebugMode) {
      print('Handling background message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
    
    // Initialize database if needed
    await DatabaseHelper.instance.database;
    
    // Convert message to NotificationItem
    final notificationItem = _convertRemoteMessageToNotificationItem(message);
    
    // Save to local database
    final repository = LocalNotificationRepository();
    await repository.insertNotification(notificationItem);
    
    if (kDebugMode) {
      print('Background message saved to database: ${notificationItem.id}');
    }
    
  } catch (e) {
    if (kDebugMode) {
      print('Error handling background message: $e');
    }
    // Log error but don't throw - background handlers should be robust
  }
}

/// Convert RemoteMessage to NotificationItem (background handler version)
NotificationItem _convertRemoteMessageToNotificationItem(RemoteMessage message) {
  final data = message.data;
  final notification = message.notification;
  
  // Parse notification type
  final typeString = data['type'] ?? 'general';
  final type = _parseNotificationType(typeString);
  
  // Parse priority
  final priorityString = data['priority'] ?? 'normal';
  final priority = _parseNotificationPriority(priorityString);
  
  // Parse created_at timestamp (server should provide this)
  DateTime createdAt = DateTime.now();
  if (data.containsKey('created_at')) {
    try {
      final timestamp = int.parse(data['created_at']);
      createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      // Use current time if parsing fails
      createdAt = DateTime.now();
    }
  }
  
  // Parse metadata
  Map<String, dynamic>? metadata;
  if (data.containsKey('metadata')) {
    try {
      metadata = jsonDecode(data['metadata']) as Map<String, dynamic>;
    } catch (e) {
      metadata = null;
    }
  }
  
  return NotificationItem(
    id: message.messageId ?? _generateNotificationId(),
    title: notification?.title ?? data['title'] ?? 'Thông báo',
    message: notification?.body ?? data['body'] ?? '',
    type: type,
    priority: priority,
    createdAt: createdAt,
    actionUrl: data['action_url'],
    metadata: metadata,
    imageUrl: notification?.android?.imageUrl ?? data['image_url'],
    senderId: data['sender_id'],
    senderName: data['sender_name'],
    isActionable: data['is_actionable'] == 'true' || data['is_actionable'] == '1',
  );
}

/// Parse notification type from string (background handler version)
NotificationType _parseNotificationType(String typeString) {
  try {
    return NotificationType.values.firstWhere(
      (type) => type.name == typeString,
    );
  } catch (e) {
    return NotificationType.general;
  }
}

/// Parse notification priority from string (background handler version)  
NotificationPriority _parseNotificationPriority(String priorityString) {
  try {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.name == priorityString,
    );
  } catch (e) {
    return NotificationPriority.normal;
  }
}

/// Generate unique notification ID if not provided (background handler version)
String _generateNotificationId() {
  return 'fcm_bg_${DateTime.now().millisecondsSinceEpoch}';
}

/// Background Service Helper Class
/// Provides utilities for background notification processing
class BackgroundNotificationService {
  static const String _channelId = 'personaai_background';
  static const String _channelName = 'PersonaAI Background Notifications';
  
  /// Initialize background notification service
  static Future<void> initialize() async {
    // Register the background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    if (kDebugMode) {
      print('Background notification service initialized');
    }
  }
  
  /// Process missed notifications when app starts
  /// Call this when app initializes to handle any notifications received while app was closed
  static Future<List<NotificationItem>> processMissedNotifications() async {
    try {
      final repository = LocalNotificationRepository();
      
      // Get recent unread notifications (last 24 hours)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      
      final recentNotifications = await repository.getFilteredNotifications(
        statuses: {NotificationStatus.unread},
        limit: 50,
      );
      
      // Filter notifications received while app was closed
      final missedNotifications = recentNotifications.where((notification) {
        return notification.createdAt.isAfter(cutoffTime);
      }).toList();
      
      if (kDebugMode) {
        print('Found ${missedNotifications.length} missed notifications');
      }
      
      return missedNotifications;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error processing missed notifications: $e');
      }
      return [];
    }
  }
  
  /// Cleanup old notifications in background
  static Future<void> performBackgroundCleanup() async {
    try {
      final repository = LocalNotificationRepository();
      
      // Clean up read notifications older than 30 days
      final deletedCount = await repository.cleanupOldNotifications(
        retentionDays: 30,
      );
      
      if (kDebugMode) {
        print('Background cleanup: removed $deletedCount old notifications');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in background cleanup: $e');
      }
    }
  }
  
  /// Update notification badge count
  static Future<void> updateBadgeCount() async {
    try {
      final repository = LocalNotificationRepository();
      final unreadCount = await repository.getUnreadCount();
      
      // Update badge count (implementation depends on platform)
      // iOS: Use flutter_app_badger or similar
      // Android: Handle in notification channel
      
      if (kDebugMode) {
        print('Updated badge count: $unreadCount');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error updating badge count: $e');
      }
    }
  }
  
  /// Get notification statistics for analytics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final repository = LocalNotificationRepository();
      
      final totalCount = await repository.getTotalCount();
      final unreadCount = await repository.getUnreadCount();
      final countsByType = await repository.getCountsByType();
      
      return {
        'total_notifications': totalCount,
        'unread_notifications': unreadCount,
        'counts_by_type': countsByType.map((key, value) => MapEntry(key.name, value)),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification stats: $e');
      }
      return {
        'error': e.toString(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Validate notification data structure
  static bool isValidNotificationData(Map<String, dynamic> data) {
    // Check required fields
    final requiredFields = ['title', 'body'];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null || data[field].toString().isEmpty) {
        return false;
      }
    }
    
    // Validate notification type if provided
    if (data.containsKey('type')) {
      final typeString = data['type'] as String;
      try {
        NotificationType.values.firstWhere((type) => type.name == typeString);
      } catch (e) {
        if (kDebugMode) {
          print('Invalid notification type: $typeString');
        }
        return false;
      }
    }
    
    // Validate priority if provided
    if (data.containsKey('priority')) {
      final priorityString = data['priority'] as String;
      try {
        NotificationPriority.values.firstWhere((priority) => priority.name == priorityString);
      } catch (e) {
        if (kDebugMode) {
          print('Invalid notification priority: $priorityString');
        }
        return false;
      }
    }
    
    return true;
  }
  
  /// Safe JSON decode with error handling
  static Map<String, dynamic>? _safeJsonDecode(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding JSON: $e');
      }
      return null;
    }
  }
  
  /// Create notification item from raw data (for testing)
  static NotificationItem createNotificationFromData(Map<String, dynamic> data) {
    return NotificationItem(
      id: data['id'] ?? _generateNotificationId(),
      title: data['title'] ?? 'Test Notification',
      message: data['body'] ?? 'Test message',
      type: _parseNotificationType(data['type'] ?? 'general'),
      priority: _parseNotificationPriority(data['priority'] ?? 'normal'),
      createdAt: DateTime.now(),
      actionUrl: data['action_url'],
      metadata: data['metadata'] != null 
          ? (data['metadata'] is String 
              ? _safeJsonDecode(data['metadata']) 
              : data['metadata'])
          : null,
      imageUrl: data['image_url'],
      senderId: data['sender_id'],
      senderName: data['sender_name'],
      isActionable: data['is_actionable'] == 'true' || data['is_actionable'] == true,
    );
  }
} 