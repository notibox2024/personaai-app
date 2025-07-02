/// Model chứa thông tin chi tiết về user profile từ API
class UserProfile {
  final int empId;
  final String empCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String emailInternal;
  final String phone;
  final String? avatar;
  final String employeeType;
  final DateTime dateJoin;
  final DateTime dob;
  final String gender;
  final String maritalStatus;
  final String educationLevel;
  final int jobTitleId;
  final String jobTitleCode;
  final String jobTitleName;
  final String jobTitleEnName;
  final bool isManagement;
  final int organizationId;
  final String orgCode;
  final String orgName;
  final String orgEnName;
  final int? parentOrgId;
  final int? managerId;
  final String? managerName;
  final int workLocationId;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const UserProfile({
    required this.empId,
    required this.empCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.emailInternal,
    required this.phone,
    this.avatar,
    required this.employeeType,
    required this.dateJoin,
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.educationLevel,
    required this.jobTitleId,
    required this.jobTitleCode,
    required this.jobTitleName,
    required this.jobTitleEnName,
    required this.isManagement,
    required this.organizationId,
    required this.orgCode,
    required this.orgName,
    required this.orgEnName,
    this.parentOrgId,
    this.managerId,
    this.managerName,
    required this.workLocationId,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// Tạo instance từ JSON response của API
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      empId: json['emp_id'] ?? 0,
      empCode: json['emp_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      emailInternal: json['email_internal'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      employeeType: json['employee_type'] ?? '',
      dateJoin: DateTime.parse(json['date_join']),
      dob: DateTime.parse(json['dob']),
      gender: json['gender'] ?? '',
      maritalStatus: json['marital_status'] ?? '',
      educationLevel: json['education_level'] ?? '',
      jobTitleId: json['job_title_id'] ?? 0,
      jobTitleCode: json['job_title_code'] ?? '',
      jobTitleName: json['job_title_name'] ?? '',
      jobTitleEnName: json['job_title_en_name'] ?? '',
      isManagement: json['is_management'] ?? false,
      organizationId: json['organization_id'] ?? 0,
      orgCode: json['org_code'] ?? '',
      orgName: json['org_name'] ?? '',
      orgEnName: json['org_en_name'] ?? '',
      parentOrgId: json['parent_org_id'],
      managerId: json['manager_id'],
      managerName: json['manager_name'],
      workLocationId: json['work_location_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      modifiedAt: DateTime.parse(json['modified_at']),
    );
  }

  /// Convert thành Map để lưu trữ
  Map<String, dynamic> toJson() {
    return {
      'emp_id': empId,
      'emp_code': empCode,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email_internal': emailInternal,
      'phone': phone,
      'avatar': avatar,
      'employee_type': employeeType,
      'date_join': dateJoin.toIso8601String(),
      'dob': dob.toIso8601String(),
      'gender': gender,
      'marital_status': maritalStatus,
      'education_level': educationLevel,
      'job_title_id': jobTitleId,
      'job_title_code': jobTitleCode,
      'job_title_name': jobTitleName,
      'job_title_en_name': jobTitleEnName,
      'is_management': isManagement,
      'organization_id': organizationId,
      'org_code': orgCode,
      'org_name': orgName,
      'org_en_name': orgEnName,
      'parent_org_id': parentOrgId,
      'manager_id': managerId,
      'manager_name': managerName,
      'work_location_id': workLocationId,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  /// Copy with new values
  UserProfile copyWith({
    int? empId,
    String? empCode,
    String? firstName,
    String? lastName,
    String? fullName,
    String? emailInternal,
    String? phone,
    String? avatar,
    String? employeeType,
    DateTime? dateJoin,
    DateTime? dob,
    String? gender,
    String? maritalStatus,
    String? educationLevel,
    int? jobTitleId,
    String? jobTitleCode,
    String? jobTitleName,
    String? jobTitleEnName,
    bool? isManagement,
    int? organizationId,
    String? orgCode,
    String? orgName,
    String? orgEnName,
    int? parentOrgId,
    int? managerId,
    String? managerName,
    int? workLocationId,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return UserProfile(
      empId: empId ?? this.empId,
      empCode: empCode ?? this.empCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      emailInternal: emailInternal ?? this.emailInternal,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      employeeType: employeeType ?? this.employeeType,
      dateJoin: dateJoin ?? this.dateJoin,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      educationLevel: educationLevel ?? this.educationLevel,
      jobTitleId: jobTitleId ?? this.jobTitleId,
      jobTitleCode: jobTitleCode ?? this.jobTitleCode,
      jobTitleName: jobTitleName ?? this.jobTitleName,
      jobTitleEnName: jobTitleEnName ?? this.jobTitleEnName,
      isManagement: isManagement ?? this.isManagement,
      organizationId: organizationId ?? this.organizationId,
      orgCode: orgCode ?? this.orgCode,
      orgName: orgName ?? this.orgName,
      orgEnName: orgEnName ?? this.orgEnName,
      parentOrgId: parentOrgId ?? this.parentOrgId,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      workLocationId: workLocationId ?? this.workLocationId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(empId: $empId, empCode: $empCode, fullName: $fullName, email: $emailInternal, jobTitle: $jobTitleName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.empId == empId &&
        other.empCode == empCode &&
        other.emailInternal == emailInternal;
  }

  @override
  int get hashCode {
    return Object.hash(empId, empCode, emailInternal);
  }
} 