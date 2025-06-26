import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'shared/widgets/bottom_navigation.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/attendance/presentation/pages/attendance_page.dart';
import 'features/training/presentation/pages/training_page.dart';
import 'features/notifications/presentation/pages/notification_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'shared/services/firebase_service.dart';
import 'features/notifications/data/repositories/local_notification_repository.dart';
import 'features/notifications/data/models/notification_item.dart';

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
  late LocalNotificationRepository _notificationRepository;
  
  @override
  void initState() {
    super.initState();
    _notificationRepository = LocalNotificationRepository();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  /// Initialize notification system and callbacks
  Future<void> _initializeNotifications() async {
    try {
      // Setup Firebase service callbacks
      final firebaseService = FirebaseService();
      
      // Handle incoming notifications when app is running
      firebaseService.onNotificationReceived = _handleNotificationReceived;
      
      // Handle notification taps
      firebaseService.onNotificationTapped = _handleNotificationTapped;
      
      // Load initial unread count
      await _updateUnreadCount();
      
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
  
  /// Handle new notification received
  void _handleNotificationReceived(NotificationItem notification) {
    // Update unread count
    _updateUnreadCount();
    
    // Show snackbar for important notifications when app is active
    if (notification.priority == NotificationPriority.urgent || 
        notification.priority == NotificationPriority.high) {
      _showNotificationSnackBar(notification);
    }
  }
  
  /// Handle notification tap
  void _handleNotificationTapped(NotificationItem notification) {
    // Navigate to notifications page
    setState(() {
      _currentIndex = 3; // Notifications tab index
    });
    _pageController.jumpToPage(3);
    
    // Handle specific actions based on notification
    _handleNotificationAction(notification);
  }
  
  /// Show snackbar for incoming important notifications
  void _showNotificationSnackBar(NotificationItem notification) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification.message),
          ],
        ),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            _handleNotificationTapped(notification);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Handle notification-specific actions
  void _handleNotificationAction(NotificationItem notification) {
    final actionUrl = notification.actionUrl;
    if (actionUrl == null) return;
    
    // Parse action URL and navigate accordingly
    if (actionUrl.startsWith('/attendance')) {
      setState(() {
        _currentIndex = 1; // Attendance tab
      });
      _pageController.jumpToPage(1);
    } else if (actionUrl.startsWith('/training')) {
      setState(() {
        _currentIndex = 2; // Training tab  
      });
      _pageController.jumpToPage(2);
    } else if (actionUrl.startsWith('/profile')) {
      setState(() {
        _currentIndex = 4; // Profile tab
      });
      _pageController.jumpToPage(4);
    }
    // Add more navigation rules as needed
  }
  
  /// Update unread notification count
  Future<void> _updateUnreadCount() async {
    try {
      final count = await _notificationRepository.getUnreadCount();
      if (mounted) {
        setState(() {
          _notificationUnreadCount = count;
        });
      }
    } catch (e) {
      print('Error updating unread count: $e');
    }
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