/// Model cho thống kê tháng
class MonthlyStats {
  final int month;
  final int year;
  final int workDaysCompleted;
  final int totalWorkDays;
  final int remainingLeaveDays;
  final Duration totalOvertimeHours;
  final double performanceRating;
  final String performanceLevel;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.workDaysCompleted,
    required this.totalWorkDays,
    required this.remainingLeaveDays,
    required this.totalOvertimeHours,
    required this.performanceRating,
    required this.performanceLevel,
  });

  /// Format tháng năm hiển thị
  String get monthYearString {
    return '${month.toString().padLeft(2, '0')}/$year';
  }

  /// Tính phần trăm hoàn thành công việc
  double get completionPercentage {
    if (totalWorkDays == 0) return 0.0;
    return (workDaysCompleted / totalWorkDays) * 100;
  }

  /// Format giờ overtime
  String get overtimeString {
    return '${totalOvertimeHours.inHours}h';
  }

  /// Format rating
  String get ratingString {
    return '${performanceRating.toStringAsFixed(1)}/10';
  }

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month: json['month'] as int,
      year: json['year'] as int,
      workDaysCompleted: json['workDaysCompleted'] as int,
      totalWorkDays: json['totalWorkDays'] as int,
      remainingLeaveDays: json['remainingLeaveDays'] as int,
      totalOvertimeHours: Duration(hours: json['totalOvertimeHours'] as int),
      performanceRating: (json['performanceRating'] as num).toDouble(),
      performanceLevel: json['performanceLevel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'workDaysCompleted': workDaysCompleted,
      'totalWorkDays': totalWorkDays,
      'remainingLeaveDays': remainingLeaveDays,
      'totalOvertimeHours': totalOvertimeHours.inHours,
      'performanceRating': performanceRating,
      'performanceLevel': performanceLevel,
    };
  }
} 