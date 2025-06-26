/// Model cho tiến độ học tập
class TrainingProgress {
  final String id;
  final String courseId;
  final String userId;
  final int completedLessons;
  final int totalLessons;
  final double progressPercentage;
  final Duration totalStudyTime;
  final DateTime lastAccessedAt;
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final TrainingStatus status;
  final List<LessonProgress> lessonProgresses;

  const TrainingProgress({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercentage,
    required this.totalStudyTime,
    required this.lastAccessedAt,
    required this.enrolledAt,
    this.completedAt,
    required this.status,
    required this.lessonProgresses,
  });

  /// Tính toán phần trăm hoàn thành
  double get completionRate => 
      totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;

  /// Kiểm tra khóa học đã hoàn thành
  bool get isCompleted => status == TrainingStatus.completed;

  /// Kiểm tra khóa học đang học
  bool get isInProgress => status == TrainingStatus.inProgress;

  /// Thời gian học trung bình mỗi bài
  Duration get averageTimePerLesson {
    if (completedLessons == 0) return Duration.zero;
    return Duration(
      minutes: totalStudyTime.inMinutes ~/ completedLessons,
    );
  }

  factory TrainingProgress.fromJson(Map<String, dynamic> json) {
    return TrainingProgress(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      userId: json['userId'] as String,
      completedLessons: json['completedLessons'] as int,
      totalLessons: json['totalLessons'] as int,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      totalStudyTime: Duration(minutes: json['totalStudyTimeMinutes'] as int),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      enrolledAt: DateTime.parse(json['enrolledAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      status: TrainingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TrainingStatus.notStarted,
      ),
      lessonProgresses: (json['lessonProgresses'] as List)
          .map((e) => LessonProgress.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'userId': userId,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'progressPercentage': progressPercentage,
      'totalStudyTimeMinutes': totalStudyTime.inMinutes,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'enrolledAt': enrolledAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'lessonProgresses': lessonProgresses.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model cho tiến độ từng bài học
class LessonProgress {
  final String lessonId;
  final String title;
  final bool isCompleted;
  final Duration watchTime;
  final Duration totalDuration;
  final DateTime? completedAt;
  final double progressPercentage;

  const LessonProgress({
    required this.lessonId,
    required this.title,
    required this.isCompleted,
    required this.watchTime,
    required this.totalDuration,
    this.completedAt,
    required this.progressPercentage,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      watchTime: Duration(seconds: json['watchTimeSeconds'] as int),
      totalDuration: Duration(seconds: json['totalDurationSeconds'] as int),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'title': title,
      'isCompleted': isCompleted,
      'watchTimeSeconds': watchTime.inSeconds,
      'totalDurationSeconds': totalDuration.inSeconds,
      'completedAt': completedAt?.toIso8601String(),
      'progressPercentage': progressPercentage,
    };
  }
}

/// Enum cho trạng thái học tập
enum TrainingStatus {
  notStarted('Chưa bắt đầu'),
  inProgress('Đang học'),
  completed('Đã hoàn thành'),
  suspended('Tạm ngưng');

  const TrainingStatus(this.displayName);
  final String displayName;
} 