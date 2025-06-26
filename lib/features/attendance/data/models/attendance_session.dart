/// Enum cho loại phiên chấm công
enum SessionType {
  normal('Ca bình thường'),
  overtime('Tăng ca'),
  shift('Ca đêm'),
  weekend('Cuối tuần');

  const SessionType(this.displayName);
  final String displayName;
}

/// Enum cho trạng thái phiên chấm công
enum SessionStatus {
  active('Đang làm việc'),
  completed('Hoàn thành'),
  invalid('Không hợp lệ'),
  pending('Chờ xử lý');

  const SessionStatus(this.displayName);
  final String displayName;
}

/// Model cho phiên chấm công
class AttendanceSession {
  final String sessionId;
  final String employeeId;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final SessionType sessionType;
  final SessionStatus status;
  final String? checkInLocation;
  final String? checkOutLocation;
  final Map<String, dynamic>? deviceInfo;
  final String? notes;
  final bool isValidated;

  const AttendanceSession({
    required this.sessionId,
    required this.employeeId,
    this.checkInTime,
    this.checkOutTime,
    required this.sessionType,
    required this.status,
    this.checkInLocation,
    this.checkOutLocation,
    this.deviceInfo,
    this.notes,
    this.isValidated = false,
  });

  /// Tính tổng thời gian làm việc
  Duration get totalWorkTime {
    if (checkInTime == null) return Duration.zero;
    final endTime = checkOutTime ?? DateTime.now();
    return endTime.difference(checkInTime!);
  }

  /// Format thời gian làm việc
  String get workTimeString {
    final duration = totalWorkTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Format thời gian check in
  String get checkInTimeString {
    if (checkInTime == null) return '--:--';
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Format thời gian check out
  String get checkOutTimeString {
    if (checkOutTime == null) return '--:--';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Kiểm tra có đang làm việc không
  bool get isActive => status == SessionStatus.active && checkInTime != null && checkOutTime == null;

  /// Tính giờ dự kiến kết thúc (8 tiếng làm việc)
  DateTime? get expectedEndTime {
    if (checkInTime == null) return null;
    return checkInTime!.add(const Duration(hours: 8));
  }

  /// Format giờ dự kiến kết thúc
  String get expectedEndTimeString {
    final endTime = expectedEndTime;
    if (endTime == null) return '--:--';
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      sessionId: json['sessionId'] as String,
      employeeId: json['employeeId'] as String,
      checkInTime: json['checkInTime'] != null 
          ? DateTime.parse(json['checkInTime']) 
          : null,
      checkOutTime: json['checkOutTime'] != null 
          ? DateTime.parse(json['checkOutTime']) 
          : null,
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == json['sessionType'],
        orElse: () => SessionType.normal,
      ),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.pending,
      ),
      checkInLocation: json['checkInLocation'],
      checkOutLocation: json['checkOutLocation'],
      deviceInfo: json['deviceInfo'],
      notes: json['notes'],
      isValidated: json['isValidated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'employeeId': employeeId,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'sessionType': sessionType.name,
      'status': status.name,
      'checkInLocation': checkInLocation,
      'checkOutLocation': checkOutLocation,
      'deviceInfo': deviceInfo,
      'notes': notes,
      'isValidated': isValidated,
    };
  }

  AttendanceSession copyWith({
    String? sessionId,
    String? employeeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    SessionType? sessionType,
    SessionStatus? status,
    String? checkInLocation,
    String? checkOutLocation,
    Map<String, dynamic>? deviceInfo,
    String? notes,
    bool? isValidated,
  }) {
    return AttendanceSession(
      sessionId: sessionId ?? this.sessionId,
      employeeId: employeeId ?? this.employeeId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      notes: notes ?? this.notes,
      isValidated: isValidated ?? this.isValidated,
    );
  }
} 