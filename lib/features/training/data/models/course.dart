import 'package:flutter/material.dart';

/// Model cho khóa học
class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String thumbnailUrl;
  final Duration duration;
  final int totalLessons;
  final CourseLevel level;
  final CourseCategory category;
  final double rating;
  final int enrolledCount;
  final double price;
  final bool isFree;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.thumbnailUrl,
    required this.duration,
    required this.totalLessons,
    required this.level,
    required this.category,
    required this.rating,
    required this.enrolledCount,
    required this.price,
    required this.isFree,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      instructor: json['instructor'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      duration: Duration(minutes: json['durationMinutes'] as int),
      totalLessons: json['totalLessons'] as int,
      level: CourseLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => CourseLevel.beginner,
      ),
      category: CourseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => CourseCategory.technical,
      ),
      rating: (json['rating'] as num).toDouble(),
      enrolledCount: json['enrolledCount'] as int,
      price: (json['price'] as num).toDouble(),
      isFree: json['isFree'] as bool,
      tags: List<String>.from(json['tags']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'thumbnailUrl': thumbnailUrl,
      'durationMinutes': duration.inMinutes,
      'totalLessons': totalLessons,
      'level': level.name,
      'category': category.name,
      'rating': rating,
      'enrolledCount': enrolledCount,
      'price': price,
      'isFree': isFree,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Enum cho cấp độ khóa học
enum CourseLevel {
  beginner('Cơ bản', Colors.green),
  intermediate('Trung cấp', Colors.orange),
  advanced('Nâng cao', Colors.red),
  expert('Chuyên gia', Colors.purple);

  const CourseLevel(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Enum cho danh mục khóa học
enum CourseCategory {
  technical('Kỹ thuật', Icons.computer),
  softSkills('Kỹ năng mềm', Icons.psychology),
  leadership('Lãnh đạo', Icons.supervisor_account),
  compliance('Tuân thủ', Icons.gavel),
  safety('An toàn', Icons.security),
  finance('Tài chính', Icons.account_balance);

  const CourseCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
} 