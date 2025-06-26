import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../widgets/notification_header.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_bottom_sheet.dart';
import '../../data/models/notification_item.dart';

/// Trang thông báo chính
class NotificationPage extends StatefulWidget {
  final Function(int)? onUnreadCountChanged;
  
  const NotificationPage({
    super.key,
    this.onUnreadCountChanged,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];
  NotificationFilter _currentFilter = const NotificationFilter();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _notifications = _getMockNotifications();
    _applyFilters();
  }

  void _applyFilters() {
    _filteredNotifications = _notifications.where((notification) {
      // Filter by type
      if (_currentFilter.types.isNotEmpty && 
          !_currentFilter.types.contains(notification.type)) {
        return false;
      }

      // Filter by status
      if (_currentFilter.statuses.isNotEmpty && 
          !_currentFilter.statuses.contains(notification.status)) {
        return false;
      }

      // Filter by priority
      if (_currentFilter.priority != null && 
          notification.priority != _currentFilter.priority) {
        return false;
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    _filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Notify parent about unread count change after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnreadCountChanged?.call(_unreadCount);
    });
  }

  int get _unreadCount {
    return _notifications
        .where((n) => n.status == NotificationStatus.unread)
        .length;
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
              child: NotificationHeader(
                onFilterTap: _showFilterBottomSheet,
                onMarkAllReadTap: _markAllAsRead,
                unreadCount: _unreadCount,
              ),
            ),

            // Top spacing for content
            SliverToBoxAdapter(
              child: SafeArea(
                top: false, // Header already handles top safe area
                child: const SizedBox(height: 16),
              ),
            ),

            // Filter info if active
            if (_currentFilter.hasActiveFilters)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        TablerIcons.filter,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang hiển thị ${_filteredNotifications.length} thông báo đã lọc',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Icon(
                          TablerIcons.x,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Spacing after filter info
            if (_currentFilter.hasActiveFilters)
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Notifications list
            _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notification = _filteredNotifications[index];
                        return Container(
                          margin: const EdgeInsets.only(
                            left: 4,
                            right: 4,
                            bottom: 8,
                          ),
                          child: NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onMarkRead: () => _toggleReadStatus(notification),
                            onDelete: () => _deleteNotification(notification),
                            onAction: () => _handleNotificationAction(notification),
                          ),
                        );
                      },
                      childCount: _filteredNotifications.length,
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              _currentFilter.hasActiveFilters 
                  ? TablerIcons.filter_off 
                  : TablerIcons.bell_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _currentFilter.hasActiveFilters 
                  ? 'Không có thông báo nào phù hợp với bộ lọc'
                  : 'Chưa có thông báo nào',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _currentFilter.hasActiveFilters 
                  ? 'Thử thay đổi bộ lọc để xem thêm thông báo'
                  : 'Thông báo mới sẽ hiển thị tại đây',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentFilter.hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Xóa bộ lọc'),
              ),
            ],
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationFilterBottomSheet(
        initialFilter: _currentFilter,
        onApply: (filter) {
          setState(() {
            _currentFilter = filter;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = const NotificationFilter();
      _applyFilters();
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.markAsRead()).toList();
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read if unread
    if (notification.status == NotificationStatus.unread) {
      _toggleReadStatus(notification);
    }

    // TODO: Navigate to detail page or perform action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã mở thông báo: ${notification.title}')),
    );
  }

  void _toggleReadStatus(NotificationItem notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        if (notification.status == NotificationStatus.unread) {
          _notifications[index] = notification.markAsRead();
        } else {
          _notifications[index] = notification.markAsUnread();
        }
        _applyFilters();
      }
    });
  }

  void _deleteNotification(NotificationItem notification) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(notification);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _performDelete(NotificationItem notification) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa thông báo'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            setState(() {
              _notifications.add(notification);
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  void _handleNotificationAction(NotificationItem notification) {
    // TODO: Handle specific notification actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xử lý hành động cho: ${notification.title}')),
    );
  }

  // =============== MOCK DATA ===============

  List<NotificationItem> _getMockNotifications() {
    final now = DateTime.now();
    
    return [
      NotificationItem(
        id: 'notif_001',
        title: 'Nhắc nhở chấm công',
        message: 'Bạn chưa chấm công vào hôm nay. Vui lòng chấm công trước 9:00 AM.',
        type: NotificationType.attendance,
        status: NotificationStatus.unread,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(minutes: 30)),
        senderName: 'Hệ thống HR',
        isActionable: true,
      ),
      
      NotificationItem(
        id: 'notif_002',
        title: 'Khóa học mới đã được thêm',
        message: 'Khóa học "Kỹ năng giao tiếp hiệu quả" đã được thêm vào chương trình đào tạo. Hạn đăng ký: 15/12/2024.',
        type: NotificationType.training,
        status: NotificationStatus.unread,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 2)),
        senderName: 'Phòng Đào tạo',
        isActionable: true,
      ),
      
      NotificationItem(
        id: 'notif_003',
        title: 'Đơn nghỉ phép đã được duyệt',
        message: 'Đơn nghỉ phép từ ngày 20/12/2024 đến 22/12/2024 của bạn đã được phê duyệt.',
        type: NotificationType.leave,
        status: NotificationStatus.read,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 4)),
        senderName: 'Nguyễn Thị Manager',
      ),
      
      NotificationItem(
        id: 'notif_004',
        title: 'Cập nhật chính sách công ty',
        message: 'Chính sách làm việc từ xa đã được cập nhật. Vui lòng xem chi tiết trong tài liệu đính kèm.',
        type: NotificationType.general,
        status: NotificationStatus.unread,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 6)),
        senderName: 'Ban Giám đốc',
        isActionable: true,
      ),
      
      NotificationItem(
        id: 'notif_005',
        title: 'Yêu cầu tăng ca được chấp nhận',
        message: 'Yêu cầu tăng ca ngày 18/12/2024 từ 18:00-20:00 đã được chấp nhận.',
        type: NotificationType.overtime,
        status: NotificationStatus.read,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
        senderName: 'Phòng Nhân sự',
      ),
      
      NotificationItem(
        id: 'notif_006',
        title: 'KHẨN CẤP: Sự cố hệ thống',
        message: 'Hệ thống đang gặp sự cố, một số tính năng có thể không hoạt động bình thường. Chúng tôi đang khắc phục.',
        type: NotificationType.urgent,
        status: NotificationStatus.unread,
        priority: NotificationPriority.urgent,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        senderName: 'IT Support',
        isActionable: true,
      ),
      
      NotificationItem(
        id: 'notif_007',
        title: 'Hoàn thành khóa đào tạo',
        message: 'Chúc mừng! Bạn đã hoàn thành khóa đào tạo "An toàn lao động". Chứng chỉ đã được cấp.',
        type: NotificationType.training,
        status: NotificationStatus.read,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 2)),
        senderName: 'Phòng Đào tạo',
      ),
      
      NotificationItem(
        id: 'notif_008',
        title: 'Cập nhật hệ thống thành công',
        message: 'Hệ thống đã được cập nhật lên phiên bản mới với nhiều tính năng cải tiến.',
        type: NotificationType.system,
        status: NotificationStatus.read,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 3)),
        senderName: 'IT Department',
      ),
    ];
  }
} 