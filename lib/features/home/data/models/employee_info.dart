/// Model cho thông tin nhân viên
class EmployeeInfo {
  final String id;
  final String fullName;
  final String position;
  final String avatarUrl;
  final String department;
  final int notificationCount;

  const EmployeeInfo({
    required this.id,
    required this.fullName,
    required this.position,
    required this.avatarUrl,
    required this.department,
    this.notificationCount = 0,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      position: json['position'] as String,
      avatarUrl: json['avatarUrl'] as String,
      department: json['department'] as String,
      notificationCount: json['notificationCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'position': position,
      'avatarUrl': avatarUrl,
      'department': department,
      'notificationCount': notificationCount,
    };
  }

  EmployeeInfo copyWith({
    String? id,
    String? fullName,
    String? position,
    String? avatarUrl,
    String? department,
    int? notificationCount,
  }) {
    return EmployeeInfo(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      department: department ?? this.department,
      notificationCount: notificationCount ?? this.notificationCount,
    );
  }
} 