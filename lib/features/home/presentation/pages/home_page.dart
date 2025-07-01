import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Models
import '../../data/models/employee_info.dart';
import '../../data/models/attendance_info.dart';
import '../../data/models/monthly_stats.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/upcoming_event.dart';

// Location and Services
import '../../../../shared/shared_exports.dart';
import 'package:geolocator/geolocator.dart';

// Auth Integration - use AuthModule for cross-feature access
import '../../../auth/auth_module.dart';
import '../../../auth/auth_exports.dart';

// Widgets
import '../widgets/scrollable_header.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/dashboard_cards/attendance_card.dart';
import '../widgets/dashboard_cards/monthly_stats_card.dart';
import '../widgets/dashboard_cards/notifications_card.dart';
import '../widgets/upcoming_events_card.dart';

/// Trang chủ chính của ứng dụng với auth integration
class HomePage extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  
  const HomePage({
    super.key,
    this.onThemeToggle,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Position? _currentPosition;
  bool _isLocationLoading = false;

  // Get AuthProvider from AuthModule for cross-feature access
  late final authProvider = AuthModule.instance.provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationAndData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh location when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Icons màu trắng cho header sẫm
        statusBarBrightness: Brightness.dark,      // Cho iOS
      ),
      child: StreamBuilder(
        stream: authProvider.authStateStream,
        builder: (context, snapshot) {
          // Handle auth state changes via AuthProvider instead of BlocConsumer
          if (!authProvider.isAuthenticated) {
            // Navigate to login page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Get user info from auth provider
          final user = authProvider.currentUser;
          
          return Scaffold(
            // Sử dụng surfaceContainerLowest làm background chính để tạo contrast với cards (surface)
            // Light theme: surfaceContainerLowest (~#FAFAFA) vs surface (#FFFFFF)  
            // Dark theme: surfaceContainerLowest (~#0F0F0F) vs surface (#1E1E1E)
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            body: RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Scrollable Header with real user info
                  SliverToBoxAdapter(
                    child: ScrollableHeader(
                      employee: _getEmployeeInfoFromUser(user),
                      onThemeToggle: widget.onThemeToggle,
                    ),
                  ),

                  // Welcome Banner with Weather
                  SliverToBoxAdapter(
                    child: WelcomeBanner(
                      employeeName: user?.displayName ?? 'Người dùng',
                      currentPosition: _currentPosition,
                      isLocationLoading: _isLocationLoading,
                      onLocationRefresh: _refreshLocation,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Dashboard Cards Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Thông tin tổng quan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Attendance Card
                  SliverToBoxAdapter(
                    child: AttendanceCard(
                      attendanceInfo: _getMockAttendanceInfo(),
                      onTap: () => _handleAttendanceDetailTap(),
                    ),
                  ),

                  // Monthly Stats Card
                  SliverToBoxAdapter(
                    child: MonthlyStatsCard(
                      monthlyStats: _getMockMonthlyStats(),
                      onTap: () => _handleMonthlyStatsTap(),
                    ),
                  ),

                  // Notifications Card
                  SliverToBoxAdapter(
                    child: NotificationsCard(
                      notifications: _getMockNotifications(),
                      onSeeAllTap: () => _handleSeeAllNotificationsTap(),
                      onNotificationTap: (notification) => _handleNotificationItemTap(notification),
                    ),
                  ),

                  // Upcoming Events Card
                  SliverToBoxAdapter(
                    child: UpcomingEventsCard(
                      events: _getMockUpcomingEvents(),
                      onSeeAllTap: () => _handleSeeAllEventsTap(),
                      onEventTap: (event) => _handleEventTap(event),
                    ),
                  ),

                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =============== AUTH INTEGRATION METHODS ===============

  /// Convert UserSession to EmployeeInfo for backward compatibility
  EmployeeInfo _getEmployeeInfoFromUser(UserSession? user) {
    if (user == null) {
      return _getMockEmployeeInfo(); // Fallback to mock data
    }
    
    return EmployeeInfo(
      id: user.userId,
      fullName: user.displayName ?? 'Người dùng',
      position: 'Nhân viên', // Default position
      department: 'IT', // Default department
      avatarUrl: user.avatar ?? '',
    );
  }

  // =============== LOCATION METHODS ===============

  Future<void> _initializeLocationAndData() async {
    await _checkLocationPermissions();
  }

  Future<void> _checkLocationPermissions() async {
    setState(() => _isLocationLoading = true);

    try {
      final status = await LocationService.getLocationPermissionStatus();
      
      switch (status) {
        case LocationPermissionStatus.denied:
          if (mounted) {
            await LocationPermissionDialog.show(
              context,
              onPermissionGranted: () {
                _refreshLocation();
              },
              onPermissionDenied: () {
                setState(() => _isLocationLoading = false);
              },
            );
          }
          break;
          
        case LocationPermissionStatus.deniedForever:
          setState(() => _isLocationLoading = false);
          _showLocationPermissionDeniedSnackBar();
          break;
          
        case LocationPermissionStatus.serviceDisabled:
          setState(() => _isLocationLoading = false);
          if (mounted) {
            await LocationServiceDisabledDialog.show(context);
          }
          break;
          
        case LocationPermissionStatus.whileInUse:
        case LocationPermissionStatus.always:
          await _refreshLocation();
          break;
      }
    } catch (e) {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();
      
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      } else {
        setState(() => _isLocationLoading = false);
      }
    } catch (e) {
      setState(() => _isLocationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy vị trí: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkAndRefreshLocation() async {
    final status = await LocationService.getLocationPermissionStatus();
    
    if (status == LocationPermissionStatus.whileInUse || 
        status == LocationPermissionStatus.always) {
      await _refreshLocation();
    }
  }

  void _showLocationPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cần quyền truy cập vị trí để hiển thị thời tiết chính xác'),
        action: SnackBarAction(
          label: 'Cài đặt',
          onPressed: () async {
            await LocationService.openAppSettings();
          },
        ),
      ),
    );
  }

  // =============== EVENT HANDLERS ===============

  Future<void> _onRefresh(BuildContext context) async {
    await Future.wait([
      _refreshLocation(),
      Future.delayed(const Duration(seconds: 1)), // Simulate other data refresh
    ]);
  }

  void _handleAttendanceDetailTap() {
    // TODO: Navigate to attendance detail page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở chi tiết chấm công')),
    );
  }

  void _handleMonthlyStatsTap() {
    // TODO: Navigate to monthly stats page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở thống kê tháng')),
    );
  }

  void _handleSeeAllNotificationsTap() {
    // TODO: Navigate to all notifications page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở tất cả thông báo')),
    );
  }

  void _handleNotificationItemTap(NotificationItem notification) {
    // TODO: Handle notification item tap
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mở thông báo: ${notification.title}')),
    );
  }

  void _handleSeeAllEventsTap() {
    // TODO: Navigate to calendar page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở lịch đầy đủ')),
    );
  }

  void _handleEventTap(UpcomingEvent event) {
    // TODO: Handle event tap
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mở sự kiện: ${event.title}')),
    );
  }

  // =============== MOCK DATA ===============

  EmployeeInfo _getMockEmployeeInfo() {
    return const EmployeeInfo(
      id: 'EMP001',
      fullName: 'Nguyễn Văn An',
      position: 'Lập trình viên Senior',
      avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      department: 'IT Department',
      notificationCount: 5,
    );
  }

  AttendanceInfo _getMockAttendanceInfo() {
    final now = DateTime.now();
    return AttendanceInfo(
      checkInTime: DateTime(now.year, now.month, now.day, 8, 15),
      checkOutTime: null,
      totalWorkTime: const Duration(hours: 4, minutes: 30),
      status: AttendanceStatus.working,
      location: 'Văn phòng chính - Tầng 5',
      isLate: false,
      isEarlyLeave: false,
    );
  }

  MonthlyStats _getMockMonthlyStats() {
    final now = DateTime.now();
    return MonthlyStats(
      month: now.month,
      year: now.year,
      workDaysCompleted: 15,
      totalWorkDays: 22,
      remainingLeaveDays: 7,
      totalOvertimeHours: const Duration(hours: 12),
      performanceRating: 8.5,
      performanceLevel: 'Xuất sắc',
    );
  }

  List<NotificationItem> _getMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: '1',
        title: 'Tăng lương Q4 - Xem chi tiết',
        content: 'Thông báo về việc điều chỉnh mức lương quý 4/2024',
        type: NotificationType.payroll,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
        isImportant: true,
      ),
      NotificationItem(
        id: '2',
        title: 'Họp team vào 14:00 - Phòng 301',
        content: 'Cuộc họp weekly standup với team development',
        type: NotificationType.meeting,
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Deadline báo cáo: 25/12/2024',
        content: 'Nộp báo cáo tiến độ dự án cho quý 4',
        type: NotificationType.deadline,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  List<UpcomingEvent> _getMockUpcomingEvents() {
    final now = DateTime.now();
    return [
      UpcomingEvent(
        id: '1',
        title: 'Họp Ban Giám Đốc',
        date: now.add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 9, minute: 0),
        type: EventType.meeting,
        location: 'Phòng họp tầng 10',
      ),
      UpcomingEvent(
        id: '2',
        title: 'Sinh nhật Nguyễn Văn A',
        date: now.add(const Duration(days: 2)),
        type: EventType.birthday,
        isAllDay: true,
      ),
      UpcomingEvent(
        id: '3',
        title: 'Training Flutter nâng cao',
        date: now.add(const Duration(days: 4)),
        time: const TimeOfDay(hour: 14, minute: 0),
        type: EventType.training,
        location: 'Phòng đào tạo A',
        isOptional: true,
      ),
      UpcomingEvent(
        id: '4',
        title: 'Nghỉ lễ Giáng sinh',
        date: DateTime(now.year, 12, 25),
        type: EventType.holiday,
        isAllDay: true,
      ),
    ];
  }
} 