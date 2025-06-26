import 'dart:convert';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'notification_item.dart';

/// Extensions cho NotificationItem để support SQLite operations
extension NotificationItemSQLite on NotificationItem {
  /// Convert NotificationItem thành Map để lưu vào SQLite
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'read_at': readAt?.millisecondsSinceEpoch,
      'scheduled_at': scheduledAt?.millisecondsSinceEpoch,
      'action_url': actionUrl,
      'metadata': metadata != null ? jsonEncode(metadata!) : null,
      'image_url': imageUrl,
      'sender_id': senderId,
      'sender_name': senderName,
      'is_actionable': isActionable ? 1 : 0,
      'received_at': DateTime.now().millisecondsSinceEpoch,
      'source': 'fcm', // Default source when creating from app
    };
  }
  
  /// Convert NotificationItem thành Map với custom received_at và source
  Map<String, dynamic> toSQLiteMapWithSource({
    required DateTime receivedAt,
    required String source,
  }) {
    final map = toSQLiteMap();
    map['received_at'] = receivedAt.millisecondsSinceEpoch;
    map['source'] = source;
    return map;
  }
}

/// Helper class để create NotificationItem từ SQLite data
class NotificationItemSQLiteHelper {
  /// Create NotificationItem từ SQLite Map
  static NotificationItem fromSQLiteMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: _parseNotificationType(map['type'] as String),
      status: _parseNotificationStatus(map['status'] as String),
      priority: _parseNotificationPriority(map['priority'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      readAt: map['read_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['read_at'] as int)
          : null,
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'] as int)
          : null,
      actionUrl: map['action_url'] as String?,
      metadata: map['metadata'] != null 
          ? _parseMetadata(map['metadata'] as String)
          : null,
      imageUrl: map['image_url'] as String?,
      senderId: map['sender_id'] as String?,
      senderName: map['sender_name'] as String?,
      isActionable: (map['is_actionable'] as int) == 1,
    );
  }
  
  /// Parse NotificationType từ string
  static NotificationType _parseNotificationType(String typeString) {
    try {
      return NotificationType.values.firstWhere(
        (type) => type.name == typeString,
      );
    } catch (e) {
      return NotificationType.general; // Fallback
    }
  }
  
  /// Parse NotificationStatus từ string
  static NotificationStatus _parseNotificationStatus(String statusString) {
    try {
      return NotificationStatus.values.firstWhere(
        (status) => status.name == statusString,
      );
    } catch (e) {
      return NotificationStatus.unread; // Fallback
    }
  }
  
  /// Parse NotificationPriority từ string
  static NotificationPriority _parseNotificationPriority(String priorityString) {
    try {
      return NotificationPriority.values.firstWhere(
        (priority) => priority.name == priorityString,
      );
    } catch (e) {
      return NotificationPriority.normal; // Fallback
    }
  }
  
  /// Parse metadata JSON string
  static Map<String, dynamic>? _parseMetadata(String metadataString) {
    try {
      return jsonDecode(metadataString) as Map<String, dynamic>;
    } catch (e) {
      return null; // Invalid JSON, return null
    }
  }
  
  /// Validate SQLite map có đủ required fields không
  static bool isValidSQLiteMap(Map<String, dynamic> map) {
    final requiredFields = ['id', 'title', 'message', 'type', 'created_at'];
    
    for (final field in requiredFields) {
      if (!map.containsKey(field) || map[field] == null) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Get default values cho các optional fields
  static Map<String, dynamic> getDefaultSQLiteValues() {
    return {
      'status': NotificationStatus.unread.name,
      'priority': NotificationPriority.normal.name,
      'read_at': null,
      'scheduled_at': null,
      'action_url': null,
      'metadata': null,
      'image_url': null,
      'sender_id': null,
      'sender_name': null,
      'is_actionable': 0,
      'received_at': DateTime.now().millisecondsSinceEpoch,
      'source': 'fcm',
    };
  }
}

/// Extensions cho filtering support
extension NotificationItemFiltering on NotificationItem {
  /// Check if notification matches date filter
  bool matchesDateFilter(DateFilter? dateFilter) {
    if (dateFilter == null) return true;
    
    final now = DateTime.now();
    final notificationDate = createdAt;
    
    switch (dateFilter) {
      case DateFilter.today:
        return _isSameDay(notificationDate, now);
      case DateFilter.yesterday:
        return _isSameDay(notificationDate, now.subtract(const Duration(days: 1)));
      case DateFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return notificationDate.isAfter(weekStart) || _isSameDay(notificationDate, weekStart);
    }
  }
  
  /// Check if notification matches type filter
  bool matchesTypeFilter(Set<NotificationType> types) {
    return types.isEmpty || types.contains(type);
  }
  
  /// Check if notification matches status filter
  bool matchesStatusFilter(Set<NotificationStatus> statuses) {
    return statuses.isEmpty || statuses.contains(status);
  }
  
  /// Check if notification matches priority filter
  bool matchesPriorityFilter(NotificationPriority? priorityFilter) {
    return priorityFilter == null || priority == priorityFilter;
  }
  
  /// Check if notification matches unread filter
  bool matchesUnreadFilter(bool showOnlyUnread) {
    return !showOnlyUnread || status == NotificationStatus.unread;
  }
  
  /// Helper method để check same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}

/// Enum cho date filtering
enum DateFilter {
  today,        // Hôm nay
  yesterday,    // Hôm qua
  thisWeek,     // Tuần này
}

/// Helper class cho batch operations
class NotificationBatchHelper {
  /// Convert list of NotificationItem thành list of SQLite maps
  static List<Map<String, dynamic>> toSQLiteMaps(
    List<NotificationItem> notifications, {
    String source = 'fcm',
  }) {
    final receivedAt = DateTime.now();
    
    return notifications.map((notification) {
      return notification.toSQLiteMapWithSource(
        receivedAt: receivedAt,
        source: source,
      );
    }).toList();
  }
  
  /// Convert list of SQLite maps thành list of NotificationItem
  static List<NotificationItem> fromSQLiteMaps(List<Map<String, dynamic>> maps) {
    return maps
        .where((map) => NotificationItemSQLiteHelper.isValidSQLiteMap(map))
        .map((map) => NotificationItemSQLiteHelper.fromSQLiteMap(map))
        .toList();
  }
  
  /// Filter notifications by multiple criteria
  static List<NotificationItem> filterNotifications(
    List<NotificationItem> notifications, {
    Set<NotificationType>? types,
    Set<NotificationStatus>? statuses,
    NotificationPriority? priority,
    DateFilter? dateFilter,
    bool showOnlyUnread = false,
  }) {
    return notifications.where((notification) {
      return notification.matchesTypeFilter(types ?? {}) &&
             notification.matchesStatusFilter(statuses ?? {}) &&
             notification.matchesPriorityFilter(priority) &&
             notification.matchesDateFilter(dateFilter) &&
             notification.matchesUnreadFilter(showOnlyUnread);
    }).toList();
  }
  
  /// Sort notifications by created_at (newest first)
  static List<NotificationItem> sortByNewest(List<NotificationItem> notifications) {
    final sorted = List<NotificationItem>.from(notifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
  
  /// Get unread count from list
  static int getUnreadCount(List<NotificationItem> notifications) {
    return notifications
        .where((n) => n.status == NotificationStatus.unread)
        .length;
  }
} 