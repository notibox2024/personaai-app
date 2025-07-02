import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../widgets/profile_header.dart';
import '../widgets/personal_info_card.dart';
import '../widgets/work_info_card.dart';
import '../widgets/achievements_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../../data/models/user_profile.dart';
import '../../../auth/presentation/widgets/logout_button.dart';
import '../../../auth/presentation/widgets/fcm_token_debug_widget.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Trang cá nhân chính
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _userProfile = _getMockUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set status bar color to match header gradient
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons on orange background
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surfaceContainerLowest,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarDividerColor: theme.colorScheme.outline,
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Scrollable Header (extends to status bar)
            SliverToBoxAdapter(
              child: ProfileHeader(
                profile: _userProfile,
                onEditTap: _handleEditProfile,
                onSettingsTap: _handleSettings,
              ),
            ),

            // Top spacing for content
            SliverToBoxAdapter(
              child: SafeArea(
                top: false, // Header already handles top safe area
                child: const SizedBox(height: 16),
              ),
            ),

            // Personal Info Card
            SliverToBoxAdapter(
              child: PersonalInfoCard(
                profile: _userProfile,
                onEditTap: _handleEditPersonalInfo,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Work Info Card
            SliverToBoxAdapter(
              child: WorkInfoCard(
                profile: _userProfile,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Achievements Card
            SliverToBoxAdapter(
              child: AchievementsCard(
                achievements: _userProfile.achievements,
                onViewAllTap: _handleViewAllAchievements,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: QuickActionsGrid(
                onEditProfileTap: _handleEditProfile,
                onChangePasswordTap: _handleChangePassword,
                onPayrollTap: _handlePayroll,
                onLeaveRequestTap: _handleLeaveRequest,
                onDocumentsTap: _handleDocuments,
                onEmergencyContactTap: _handleEmergencyContact,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // FCM Token Debug Widget (Development only)
            if (kDebugMode)
              const SliverToBoxAdapter(
                child: FcmTokenDebugWidget(),
              ),

            if (kDebugMode)
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Logout Section
            SliverToBoxAdapter(
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TablerIcons.shield_lock,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bảo mật',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: LogoutButton(
                        onLogoutSuccess: _handleLogoutSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom spacing with safe area
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ),
          ],
        ),
      ),
    );
  }

  // =============== EVENT HANDLERS ===============

  Future<void> _onRefresh() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    _initializeData();
  }

  void _handleEditProfile() {
    // TODO: Implement edit profile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện chỉnh sửa hồ sơ')),
    );
  }

  void _handleSettings() {
    // TODO: Implement settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện cài đặt')),
    );
  }

  void _handleEditPersonalInfo() {
    // TODO: Implement edit personal info
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện chỉnh sửa thông tin cá nhân')),
    );
  }

  void _handleViewAllAchievements() {
    // TODO: Implement view all achievements
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở danh sách tất cả thành tựu')),
    );
  }

  void _handleChangePassword() {
    // TODO: Implement change password
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện đổi mật khẩu')),
    );
  }

  void _handlePayroll() {
    // TODO: Implement payroll
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở bảng lương')),
    );
  }

  void _handleLeaveRequest() {
    // TODO: Implement leave request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở giao diện xin nghỉ phép')),
    );
  }

  void _handleDocuments() {
    // TODO: Implement documents
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở tài liệu cá nhân')),
    );
  }

  void _handleEmergencyContact() {
    // TODO: Implement emergency contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở danh bạ khẩn cấp')),
    );
  }

  void _handleLogoutSuccess() {
    // Navigate to login page or main navigation
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // =============== MOCK DATA ===============

  UserProfile _getMockUserProfile() {
    return UserProfile(
      employeeId: 'EMP001',
      fullName: 'Nguyễn Văn An',
      email: 'nguyen.van.an@kienlongbank.com',
      phone: '0901234567',
      avatar: 'https://randomuser.me/api/portraits/men/1.jpg', // No avatar for demo
      department: 'Phòng Công nghệ thông tin',
      position: 'Senior Developer',
      joinDate: DateTime(2020, 3, 15),
      birthDate: DateTime(1990, 8, 20),
      address: '123 Nguyễn Huệ, Quận 1, TP.HCM',
      status: UserStatus.active,
      achievements: [
        Achievement(
          id: 'ach1',
          title: 'Nhân viên xuất sắc Q3/2024',
          description: 'Hoàn thành xuất sắc các dự án được giao trong quý 3',
          dateEarned: DateTime(2024, 9, 30),
          type: AchievementType.performance,
        ),
        Achievement(
          id: 'ach2',
          title: 'Chấm công đầy đủ 6 tháng',
          description: 'Không vắng mặt không phép trong 6 tháng liên tiếp',
          dateEarned: DateTime(2024, 8, 15),
          type: AchievementType.attendance,
        ),
        Achievement(
          id: 'ach3',
          title: 'Hoàn thành khóa đào tạo Flutter',
          description: 'Đạt điểm A trong khóa đào tạo Flutter Advanced',
          dateEarned: DateTime(2024, 7, 10),
          type: AchievementType.training,
        ),
      ],
      workInfo: WorkInfo(
        contractType: 'Hợp đồng không xác định thời hạn',
        salary: 25000000,
        workSchedule: 'Thứ 2 - Thứ 6 (8:00 - 17:00)',
        managerId: 'MGR001',
        managerName: 'Trần Thị Bình',
        responsibilities: [
          'Phát triển ứng dụng mobile Flutter',
          'Tham gia thiết kế hệ thống',
          'Hướng dẫn junior developer',
        ],
      ),
    );
  }
} 