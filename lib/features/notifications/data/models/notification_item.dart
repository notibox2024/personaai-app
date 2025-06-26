import 'package:flutter/foundation.dart';

/// Enum cho loại thông báo
enum NotificationType {
  attendance,   // Chấm công
  training,     // Đào tạo
  leave,        // Nghỉ phép
  overtime,     // Tăng ca
  general,      // Thông báo chung
  system,       // Hệ thống
  urgent,       // Khẩn cấp
}

/// Enum cho trạng thái thông báo
enum NotificationStatus {
  unread,       // Chưa đọc
  read,         // Đã đọc
  archived,     // Đã lưu trữ
}

/// Enum cho độ ưu tiên thông báo
enum NotificationPriority {
  low,          // Thấp
  normal,       // Bình thường
  high,         // Cao
  urgent,       // Khẩn cấp
}

/// Model cho thông báo
@immutable
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledAt;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final String? imageUrl;
  final String? senderId;
  final String? senderName;
  final bool isActionable;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.status = NotificationStatus.unread,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.readAt,
    this.scheduledAt,
    this.actionUrl,
    this.metadata,
    this.imageUrl,
    this.senderId,
    this.senderName,
    this.isActionable = false,
  });

  /// Copy with method
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? scheduledAt,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? senderId,
    String? senderName,
    bool? isActionable,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      isActionable: isActionable ?? this.isActionable,
    );
  }

  /// Đánh dấu đã đọc
  NotificationItem markAsRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }

  /// Đánh dấu chưa đọc
  NotificationItem markAsUnread() {
    return copyWith(
      status: NotificationStatus.unread,
      readAt: null,
    );
  }

  /// Lưu trữ thông báo
  NotificationItem archive() {
    return copyWith(status: NotificationStatus.archived);
  }

  /// Kiểm tra thông báo có mới không (trong 24h)
  bool get isNew {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    return diff.inHours < 24 && status == NotificationStatus.unread;
  }

  /// Kiểm tra thông báo có quá hạn không
  bool get isOverdue {
    if (scheduledAt == null) return false;
    return DateTime.now().isAfter(scheduledAt!);
  }

  /// Format thời gian tương đối
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${(diff.inDays / 7).floor()} tuần trước';
    }
  }

  /// Get dynamic action button text dựa trên action_url và type
  String get actionButtonText {
    if (!isActionable || actionUrl == null) return '';
    
    // Parse action URL để get appropriate button text
    try {
      final uri = Uri.parse(actionUrl!);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2) {
        final module = pathSegments[0];
        final action = pathSegments[1];
        
        // URL structure mapping
        switch ('/$module/$action') {
          // Attendance actions
          case '/attendance/check-in':
            return 'Chấm công vào';
          case '/attendance/check-out':
            return 'Chấm công ra';
          case '/attendance/supplement':
            return 'Bổ sung chấm công';
          case '/attendance/details':
            return 'Xem chấm công';
            
          // Training actions
          case '/training/register':
            return 'Đăng ký khóa học';
          case '/training/continue':
            return 'Tiếp tục học';
          case '/training/certificate':
            return 'Xem chứng chỉ';
          case '/training/details':
            return 'Chi tiết khóa học';
            
          // Leave actions
          case '/leave/apply':
            return 'Nộp đơn nghỉ';
          case '/leave/details':
            return 'Xem chi tiết';
          case '/leave/respond':
            return 'Phản hồi';
            
          // Overtime actions
          case '/overtime/request':
            return 'Gửi yêu cầu';
          case '/overtime/respond':
            return 'Phản hồi';
          case '/overtime/details':
            return 'Chi tiết tăng ca';
            
          // System actions
          case '/system/update':
            return 'Cập nhật ngay';
          case '/system/details':
            return 'Xem chi tiết';
            
          // General actions
          case '/general/read':
            return 'Đọc thông báo';
          case '/general/download':
            return 'Tải xuống';
        }
      }
    } catch (e) {
      // Invalid URL, fallback to type-based text
    }
    
    // Fallback dựa trên notification type
    return _getTypeBasedActionText();
  }
  
  /// Get action button text dựa trên notification type (fallback)
  String _getTypeBasedActionText() {
    switch (type) {
      case NotificationType.attendance:
        return 'Xem chấm công';
      case NotificationType.training:
        return 'Xem khóa học';
      case NotificationType.leave:
        return 'Xem đơn nghỉ';
      case NotificationType.overtime:
        return 'Xem tăng ca';
      case NotificationType.system:
        return 'Xem chi tiết';
      case NotificationType.urgent:
        return 'Xem ngay';
      case NotificationType.general:
      default:
        return 'Xem chi tiết';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationItem(id: $id, title: $title, type: $type, status: $status)';
  }
} 