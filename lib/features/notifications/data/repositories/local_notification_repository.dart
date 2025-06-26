import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../shared/database/database_helper.dart';
import '../models/notification_item.dart';
import '../models/notification_extensions.dart';

/// Exception class cho notification repository errors
class NotificationRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const NotificationRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'NotificationRepositoryException: $message';
}

/// Repository cho local notification storage với SQLite
class LocalNotificationRepository {
  static const String _tableName = 'notifications';
  
  /// Get database instance
  Future<Database> get _database async {
    return await DatabaseHelper.instance.database;
  }
  
  // =============== CRUD OPERATIONS ===============
  
  /// Insert một notification vào database
  Future<void> insertNotification(NotificationItem notification) async {
    try {
      final db = await _database;
      final map = notification.toSQLiteMap();
      
      await db.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (kDebugMode) {
        print('Inserted notification: ${notification.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting notification: $e');
      }
      throw NotificationRepositoryException(
        'Failed to insert notification',
        originalError: e,
      );
    }
  }
  
  /// Insert multiple notifications (batch operation)
  Future<void> insertNotifications(
    List<NotificationItem> notifications, {
    String source = 'fcm',
  }) async {
    if (notifications.isEmpty) return;
    
    try {
      final db = await _database;
      final batch = db.batch();
      
      for (final notification in notifications) {
        final map = notification.toSQLiteMapWithSource(
          receivedAt: DateTime.now(),
          source: source,
        );
        
        batch.insert(
          _tableName,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      
      if (kDebugMode) {
        print('Inserted ${notifications.length} notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting notifications: $e');
      }
      throw NotificationRepositoryException(
        'Failed to insert notifications',
        originalError: e,
      );
    }
  }
  
  /// Get notification by ID
  Future<NotificationItem?> getNotification(String id) async {
    try {
      final db = await _database;
      final results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (results.isEmpty) return null;
      
      return NotificationItemSQLiteHelper.fromSQLiteMap(results.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification $id: $e');
      }
      throw NotificationRepositoryException(
        'Failed to get notification',
        originalError: e,
      );
    }
  }
  
  /// Get all notifications với pagination
  Future<List<NotificationItem>> getNotifications({
    int limit = 50,
    int offset = 0,
    String? orderBy,
  }) async {
    try {
      final db = await _database;
      final results = await db.query(
        _tableName,
        orderBy: orderBy ?? 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      return NotificationBatchHelper.fromSQLiteMaps(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notifications: $e');
      }
      throw NotificationRepositoryException(
        'Failed to get notifications',
        originalError: e,
      );
    }
  }
  
  /// Update notification status (mark as read/unread)
  Future<void> updateNotificationStatus(
    String notificationId,
    NotificationStatus status, {
    DateTime? readAt,
  }) async {
    try {
      final db = await _database;
      
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      
      if (status == NotificationStatus.read) {
        updateData['read_at'] = (readAt ?? DateTime.now()).millisecondsSinceEpoch;
      } else if (status == NotificationStatus.unread) {
        updateData['read_at'] = null;
      }
      
      final rowsAffected = await db.update(
        _tableName,
        updateData,
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      
      if (rowsAffected == 0) {
        throw NotificationRepositoryException(
          'Notification not found: $notificationId',
        );
      }
      
      if (kDebugMode) {
        print('Updated notification $notificationId status to ${status.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating notification status: $e');
      }
      
      if (e is NotificationRepositoryException) {
        rethrow;
      }
      
      throw NotificationRepositoryException(
        'Failed to update notification status',
        originalError: e,
      );
    }
  }
  
  /// Delete notification by ID
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final db = await _database;
      final rowsAffected = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      
      if (kDebugMode) {
        print('Deleted notification: $notificationId');
      }
      
      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      throw NotificationRepositoryException(
        'Failed to delete notification',
        originalError: e,
      );
    }
  }
  
  // =============== FILTERING METHODS ===============
  
  /// Get notifications với advanced filtering
  Future<List<NotificationItem>> getFilteredNotifications({
    Set<NotificationType>? types,
    Set<NotificationStatus>? statuses,
    NotificationPriority? priority,
    DateFilter? dateFilter,
    bool showOnlyUnread = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _database;
      
      // Build WHERE clause dynamically
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];
      
      // Type filter
      if (types != null && types.isNotEmpty) {
        final typePlaceholders = types.map((_) => '?').join(',');
        whereConditions.add('type IN ($typePlaceholders)');
        whereArgs.addAll(types.map((t) => t.name));
      }
      
      // Status filter
      if (statuses != null && statuses.isNotEmpty) {
        final statusPlaceholders = statuses.map((_) => '?').join(',');
        whereConditions.add('status IN ($statusPlaceholders)');
        whereArgs.addAll(statuses.map((s) => s.name));
      }
      
      // Priority filter
      if (priority != null) {
        whereConditions.add('priority = ?');
        whereArgs.add(priority.name);
      }
      
      // Unread filter
      if (showOnlyUnread) {
        whereConditions.add('status = ?');
        whereArgs.add(NotificationStatus.unread.name);
      }
      
      // Date filter
      if (dateFilter != null) {
        final dateRange = _getDateRange(dateFilter);
        if (dateRange != null) {
          whereConditions.add('created_at >= ? AND created_at <= ?');
          whereArgs.add(dateRange['start']);
          whereArgs.add(dateRange['end']);
        }
      }
      
      final whereClause = whereConditions.isEmpty 
          ? null 
          : whereConditions.join(' AND ');
      
      final results = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      return NotificationBatchHelper.fromSQLiteMaps(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting filtered notifications: $e');
      }
      throw NotificationRepositoryException(
        'Failed to get filtered notifications',
        originalError: e,
      );
    }
  }
  
  /// Get date range for filtering
  Map<String, int>? _getDateRange(DateFilter dateFilter) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    
    switch (dateFilter) {
      case DateFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case DateFilter.thisWeek:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    
    return {
      'start': startDate.millisecondsSinceEpoch,
      'end': endDate.millisecondsSinceEpoch,
    };
  }
  
  // =============== STATISTICS & COUNTS ===============
  
  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?',
        [NotificationStatus.unread.name],
      );
      
      return result.first['count'] as int;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      throw NotificationRepositoryException(
        'Failed to get unread count',
        originalError: e,
      );
    }
  }
  
  /// Get total notification count
  Future<int> getTotalCount() async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting total count: $e');
      }
      throw NotificationRepositoryException(
        'Failed to get total count',
        originalError: e,
      );
    }
  }
  
  /// Get notification counts by type
  Future<Map<NotificationType, int>> getCountsByType() async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        'SELECT type, COUNT(*) as count FROM $_tableName GROUP BY type',
      );
      
      final counts = <NotificationType, int>{};
      
      for (final row in result) {
        final typeString = row['type'] as String;
        final count = row['count'] as int;
        
        try {
          final type = NotificationType.values.firstWhere(
            (t) => t.name == typeString,
          );
          counts[type] = count;
        } catch (e) {
          // Skip unknown types
          if (kDebugMode) {
            print('Unknown notification type: $typeString');
          }
        }
      }
      
      return counts;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting counts by type: $e');
      }
      throw NotificationRepositoryException(
        'Failed to get counts by type',
        originalError: e,
      );
    }
  }
  
  // =============== MAINTENANCE OPERATIONS ===============
  
  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final db = await _database;
      final rowsAffected = await db.update(
        _tableName,
        {
          'status': NotificationStatus.read.name,
          'read_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'status = ?',
        whereArgs: [NotificationStatus.unread.name],
      );
      
      if (kDebugMode) {
        print('Marked $rowsAffected notifications as read');
      }
      
      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
      throw NotificationRepositoryException(
        'Failed to mark all as read',
        originalError: e,
      );
    }
  }
  
  /// Clean up old notifications (older than specified days)
  Future<int> cleanupOldNotifications({int retentionDays = 30}) async {
    try {
      final db = await _database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: retentionDays))
          .millisecondsSinceEpoch;
      
      final rowsAffected = await db.delete(
        _tableName,
        where: 'created_at < ? AND status = ?',
        whereArgs: [cutoffTime, NotificationStatus.archived.name],
      );
      
      if (kDebugMode) {
        print('Cleaned up $rowsAffected old notifications');
      }
      
      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old notifications: $e');
      }
      throw NotificationRepositoryException(
        'Failed to cleanup old notifications',
        originalError: e,
      );
    }
  }
  
  /// Delete all notifications (for testing/reset)
  Future<void> deleteAllNotifications() async {
    try {
      final db = await _database;
      await db.delete(_tableName);
      
      if (kDebugMode) {
        print('Deleted all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all notifications: $e');
      }
      throw NotificationRepositoryException(
        'Failed to delete all notifications',
        originalError: e,
      );
    }
  }
  

} 