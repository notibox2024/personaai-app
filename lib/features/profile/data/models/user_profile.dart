/// Model thông tin cá nhân của người dùng
class UserProfile {
  final String employeeId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;
  final String department;
  final String position;
  final DateTime joinDate;
  final DateTime? birthDate;
  final String? address;
  final UserStatus status;
  final List<Achievement> achievements;
  final WorkInfo workInfo;

  const UserProfile({
    required this.employeeId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatar,
    required this.department,
    required this.position,
    required this.joinDate,
    this.birthDate,
    this.address,
    required this.status,
    this.achievements = const [],
    required this.workInfo,
  });

  /// Số năm làm việc tại công ty
  int get yearsOfService {
    final now = DateTime.now();
    return now.year - joinDate.year;
  }

  /// Tuổi của nhân viên
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.year - birthDate!.year;
  }

  UserProfile copyWith({
    String? employeeId,
    String? fullName,
    String? email,
    String? phone,
    String? avatar,
    String? department,
    String? position,
    DateTime? joinDate,
    DateTime? birthDate,
    String? address,
    UserStatus? status,
    List<Achievement>? achievements,
    WorkInfo? workInfo,
  }) {
    return UserProfile(
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      department: department ?? this.department,
      position: position ?? this.position,
      joinDate: joinDate ?? this.joinDate,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      status: status ?? this.status,
      achievements: achievements ?? this.achievements,
      workInfo: workInfo ?? this.workInfo,
    );
  }
}

/// Enum trạng thái nhân viên
enum UserStatus {
  active('Đang làm việc'),
  onLeave('Đang nghỉ phép'),
  probation('Thử việc'),
  inactive('Tạm nghỉ');

  const UserStatus(this.displayName);
  final String displayName;
}

/// Model thành tựu của nhân viên
class Achievement {
  final String id;
  final String title;
  final String description;
  final DateTime dateEarned;
  final AchievementType type;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.dateEarned,
    required this.type,
  });
}

/// Enum loại thành tựu
enum AchievementType {
  performance('Hiệu suất'),
  attendance('Chấm công'),
  training('Đào tạo'),
  special('Đặc biệt');

  const AchievementType(this.displayName);
  final String displayName;
}

/// Model thông tin công việc
class WorkInfo {
  final String contractType;
  final double salary;
  final String workSchedule;
  final String? managerId;
  final String? managerName;
  final List<String> responsibilities;

  const WorkInfo({
    required this.contractType,
    required this.salary,
    required this.workSchedule,
    this.managerId,
    this.managerName,
    this.responsibilities = const [],
  });

  WorkInfo copyWith({
    String? contractType,
    double? salary,
    String? workSchedule,
    String? managerId,
    String? managerName,
    List<String>? responsibilities,
  }) {
    return WorkInfo(
      contractType: contractType ?? this.contractType,
      salary: salary ?? this.salary,
      workSchedule: workSchedule ?? this.workSchedule,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      responsibilities: responsibilities ?? this.responsibilities,
    );
  }
} 