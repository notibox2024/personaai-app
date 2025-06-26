import 'package:flutter/material.dart';

/// Enum cho trạng thái chấm công
enum AttendanceStatus {
  notStarted('Chưa bắt đầu', Colors.grey),
  working('Đang làm', Colors.green),
  break_('Nghỉ trưa', Colors.orange),
  finished('Đã kết thúc', Colors.blue),
  absent('Vắng mặt', Colors.red);

  const AttendanceStatus(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Model cho thông tin chấm công hôm nay
class AttendanceInfo {
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration totalWorkTime;
  final AttendanceStatus status;
  final String location;
  final bool isLate;
  final bool isEarlyLeave;

  const AttendanceInfo({
    this.checkInTime,
    this.checkOutTime,
    required this.totalWorkTime,
    required this.status,
    required this.location,
    this.isLate = false,
    this.isEarlyLeave = false,
  });

  /// Tính số giờ đã làm việc
  String get workedTimeString {
    final hours = totalWorkTime.inHours;
    final minutes = totalWorkTime.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Format thời gian check in/out
  String get checkInTimeString {
    if (checkInTime == null) return '--:--';
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  String get checkOutTimeString {
    if (checkOutTime == null) return '--:--';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  factory AttendanceInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceInfo(
      checkInTime: json['checkInTime'] != null 
          ? DateTime.parse(json['checkInTime']) 
          : null,
      checkOutTime: json['checkOutTime'] != null 
          ? DateTime.parse(json['checkOutTime']) 
          : null,
      totalWorkTime: Duration(minutes: json['totalWorkMinutes'] ?? 0),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.notStarted,
      ),
      location: json['location'] ?? '',
      isLate: json['isLate'] ?? false,
      isEarlyLeave: json['isEarlyLeave'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'totalWorkMinutes': totalWorkTime.inMinutes,
      'status': status.name,
      'location': location,
      'isLate': isLate,
      'isEarlyLeave': isEarlyLeave,
    };
  }
} 