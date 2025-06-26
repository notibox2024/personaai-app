import 'package:flutter/material.dart';

/// Enum cho loại thông báo
enum NotificationType {
  general('Chung', Icons.notifications, Colors.blue),
  payroll('Lương', Icons.attach_money, Colors.green),
  meeting('Họp', Icons.meeting_room, Colors.orange),
  deadline('Deadline', Icons.schedule, Colors.red),
  birthday('Sinh nhật', Icons.cake, Colors.purple),
  holiday('Nghỉ lễ', Icons.beach_access, Colors.teal);

  const NotificationType(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

/// Model cho thông báo
class NotificationItem {
  final String id;
  final String title;
  final String content;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final bool isImportant;
  final String? actionUrl;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.isImportant = false,
    this.actionUrl,
  });

  /// Format thời gian tương đối
  String get timeAgoString {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Emoji cho loại thông báo
  String get emoji {
    switch (type) {
      case NotificationType.payroll:
        return '🎉';
      case NotificationType.meeting:
        return '📅';
      case NotificationType.deadline:
        return '⚠️';
      case NotificationType.birthday:
        return '🎂';
      case NotificationType.holiday:
        return '🏖️';
      default:
        return '📢';
    }
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      isImportant: json['isImportant'] ?? false,
      actionUrl: json['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isImportant': isImportant,
      'actionUrl': actionUrl,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? content,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isImportant,
    String? actionUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
} 