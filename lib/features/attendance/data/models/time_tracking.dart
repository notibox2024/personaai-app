/// Model cho theo dõi thời gian làm việc
class TimeTracking {
  final Duration currentWorkTime;
  final DateTime? breakStartTime;
  final Duration totalBreakTime;
  final DateTime? expectedEndTime;
  final Duration overtimeHours;
  final double efficiencyScore;
  final List<BreakSession> breakSessions;

  const TimeTracking({
    required this.currentWorkTime,
    this.breakStartTime,
    required this.totalBreakTime,
    this.expectedEndTime,
    required this.overtimeHours,
    required this.efficiencyScore,
    required this.breakSessions,
  });

  /// Format thời gian làm việc hiện tại
  String get currentWorkTimeString {
    final hours = currentWorkTime.inHours;
    final minutes = currentWorkTime.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Format tổng thời gian nghỉ
  String get totalBreakTimeString {
    final minutes = totalBreakTime.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  /// Format giờ overtime
  String get overtimeString {
    if (overtimeHours.inMinutes == 0) return '0h';
    final hours = overtimeHours.inHours;
    final minutes = overtimeHours.inMinutes % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  /// Format điểm hiệu suất
  String get efficiencyString {
    return '${(efficiencyScore * 100).toStringAsFixed(0)}%';
  }

  /// Kiểm tra có đang nghỉ giải lao không
  bool get isOnBreak => breakStartTime != null;

  /// Thời gian nghỉ hiện tại (nếu đang nghỉ)
  Duration? get currentBreakDuration {
    if (breakStartTime == null) return null;
    return DateTime.now().difference(breakStartTime!);
  }

  /// Format thời gian nghỉ hiện tại
  String get currentBreakString {
    final duration = currentBreakDuration;
    if (duration == null) return '0m';
    final minutes = duration.inMinutes;
    return '${minutes}m';
  }

  /// Tính progress ca làm việc (0.0 - 1.0)
  double get workProgress {
    const standardWorkHours = 8;
    final hoursWorked = currentWorkTime.inMinutes / 60;
    return (hoursWorked / standardWorkHours).clamp(0.0, 1.0);
  }

  /// Còn lại bao nhiêu thời gian đến giờ tan ca
  Duration? get timeUntilEndWork {
    if (expectedEndTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expectedEndTime!)) return Duration.zero;
    return expectedEndTime!.difference(now);
  }

  /// Format thời gian còn lại
  String get timeUntilEndWorkString {
    final duration = timeUntilEndWork;
    if (duration == null) return '--:--';
    if (duration.inMinutes <= 0) return 'Đã hết giờ';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  factory TimeTracking.fromJson(Map<String, dynamic> json) {
    return TimeTracking(
      currentWorkTime: Duration(minutes: json['currentWorkMinutes'] ?? 0),
      breakStartTime: json['breakStartTime'] != null 
          ? DateTime.parse(json['breakStartTime']) 
          : null,
      totalBreakTime: Duration(minutes: json['totalBreakMinutes'] ?? 0),
      expectedEndTime: json['expectedEndTime'] != null 
          ? DateTime.parse(json['expectedEndTime']) 
          : null,
      overtimeHours: Duration(minutes: json['overtimeMinutes'] ?? 0),
      efficiencyScore: (json['efficiencyScore'] ?? 0.0).toDouble(),
      breakSessions: (json['breakSessions'] as List<dynamic>?)
          ?.map((item) => BreakSession.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWorkMinutes': currentWorkTime.inMinutes,
      'breakStartTime': breakStartTime?.toIso8601String(),
      'totalBreakMinutes': totalBreakTime.inMinutes,
      'expectedEndTime': expectedEndTime?.toIso8601String(),
      'overtimeMinutes': overtimeHours.inMinutes,
      'efficiencyScore': efficiencyScore,
      'breakSessions': breakSessions.map((session) => session.toJson()).toList(),
    };
  }

  TimeTracking copyWith({
    Duration? currentWorkTime,
    DateTime? breakStartTime,
    Duration? totalBreakTime,
    DateTime? expectedEndTime,
    Duration? overtimeHours,
    double? efficiencyScore,
    List<BreakSession>? breakSessions,
  }) {
    return TimeTracking(
      currentWorkTime: currentWorkTime ?? this.currentWorkTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      totalBreakTime: totalBreakTime ?? this.totalBreakTime,
      expectedEndTime: expectedEndTime ?? this.expectedEndTime,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      breakSessions: breakSessions ?? this.breakSessions,
    );
  }
}

/// Model cho phiên nghỉ giải lao
class BreakSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String type; // 'lunch', 'coffee', 'rest'
  final String? notes;

  const BreakSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.type,
    this.notes,
  });

  /// Tính thời gian nghỉ
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Format thời gian nghỉ
  String get durationString {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    }
  }

  /// Kiểm tra có đang nghỉ không
  bool get isActive => endTime == null;

  /// Display name cho type nghỉ
  String get typeDisplayName {
    switch (type) {
      case 'lunch':
        return 'Nghỉ trưa';
      case 'coffee':
        return 'Nghỉ coffee';
      case 'rest':
        return 'Nghỉ ngơi';
      default:
        return 'Nghỉ giải lao';
    }
  }

  factory BreakSession.fromJson(Map<String, dynamic> json) {
    return BreakSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      type: json['type'] as String,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type,
      'notes': notes,
    };
  }

  BreakSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    String? notes,
  }) {
    return BreakSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }
} 