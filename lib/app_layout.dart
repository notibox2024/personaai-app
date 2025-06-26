import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'shared/widgets/bottom_navigation.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/attendance/presentation/pages/attendance_page.dart';
import 'features/training/presentation/pages/training_page.dart';
import 'features/notifications/presentation/pages/notification_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

/// Layout chính của ứng dụng với bottom navigation
class AppLayout extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  
  const AppLayout({
    super.key,
    this.onThemeToggle,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  int _notificationUnreadCount = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _updateNotificationUnreadCount(int count) {
    setState(() {
      _notificationUnreadCount = count;
    });
  }

  List<BottomNavItem> _getNavigationItems() {
    return [
      const BottomNavItem(
        id: 'home',
        label: 'Trang chủ',
        icon: TablerIcons.home,
        activeIcon: TablerIcons.home,
      ),
      const BottomNavItem(
        id: 'attendance',
        label: 'Chấm công',
        icon: TablerIcons.clock,
        activeIcon: TablerIcons.clock,
      ),
      const BottomNavItem(
        id: 'training',
        label: 'Đào tạo',
        icon: TablerIcons.school,
        activeIcon: TablerIcons.school,
      ),
      BottomNavItem(
        id: 'notifications',
        label: 'Thông báo',
        icon: TablerIcons.bell,
        activeIcon: TablerIcons.bell,
        badgeCount: _notificationUnreadCount,
      ),
      const BottomNavItem(
        id: 'profile',
        label: 'Cá nhân',
        icon: TablerIcons.user,
        activeIcon: TablerIcons.user,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Trang chủ
          HomePage(onThemeToggle: widget.onThemeToggle),
          
          // Chấm công
          const AttendancePage(),
          
          // Đào tạo
          const TrainingPage(),
          
          // Thông báo
          NotificationPage(
            onUnreadCountChanged: _updateNotificationUnreadCount,
          ),
          
          // Cá nhân
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        items: _getNavigationItems(),
      ),
    );
  }


} 