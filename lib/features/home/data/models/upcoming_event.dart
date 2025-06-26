import 'package:flutter/material.dart';

/// Enum cho loại sự kiện
enum EventType {
  meeting('Họp', Icons.meeting_room, Colors.blue),
  birthday('Sinh nhật', Icons.cake, Colors.pink),
  training('Đào tạo', Icons.school, Colors.purple),
  holiday('Nghỉ lễ', Icons.beach_access, Colors.green),
  deadline('Deadline', Icons.schedule, Colors.red),
  company('Sự kiện công ty', Icons.business, Colors.orange);

  const EventType(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

/// Model cho sự kiện sắp tới
class UpcomingEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;
  final EventType type;
  final String? location;
  final bool isAllDay;
  final bool isOptional;

  const UpcomingEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.type,
    this.location,
    this.isAllDay = false,
    this.isOptional = false,
  });

  /// Format ngày hiển thị
  String get dateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Hôm nay';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Ngày mai';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  /// Format thời gian hiển thị
  String get timeString {
    if (isAllDay) return 'Cả ngày';
    if (time == null) return '';
    return '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
  }

  /// Emoji cho loại sự kiện
  String get emoji {
    switch (type) {
      case EventType.meeting:
        return '🗓️';
      case EventType.birthday:
        return '🎂';
      case EventType.training:
        return '🎓';
      case EventType.holiday:
        return '🏖️';
      case EventType.deadline:
        return '⏰';
      case EventType.company:
        return '🏢';
    }
  }

  /// Kiểm tra có phải sự kiện hôm nay không
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Số ngày còn lại
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return eventDate.difference(today).inDays;
  }

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    return UpcomingEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'] != null 
          ? TimeOfDay(
              hour: json['time']['hour'], 
              minute: json['time']['minute']
            )
          : null,
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.company,
      ),
      location: json['location'],
      isAllDay: json['isAllDay'] ?? false,
      isOptional: json['isOptional'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time != null 
          ? {'hour': time!.hour, 'minute': time!.minute}
          : null,
      'type': type.name,
      'location': location,
      'isAllDay': isAllDay,
      'isOptional': isOptional,
    };
  }
} 