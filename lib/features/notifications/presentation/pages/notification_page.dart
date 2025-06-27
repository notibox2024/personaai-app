import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/notification_header.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_bottom_sheet.dart';
import '../widgets/quick_filter_bar.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_filter.dart';
import '../../data/repositories/local_notification_repository.dart';
import '../bloc/notification_bloc.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/shared_exports.dart';

/// Enhanced notification page với BLoC state management
class NotificationPage extends StatelessWidget {
  final Function(int)? onUnreadCountChanged;
  
  const NotificationPage({
    super.key,
    this.onUnreadCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc(
        repository: LocalNotificationRepository(),
        firebaseService: FirebaseService(),
      )..add(const NotificationLoadRequested()),
      child: NotificationView(
        onUnreadCountChanged: onUnreadCountChanged,
      ),
    );
  }
}

class NotificationView extends StatefulWidget {
  final Function(int)? onUnreadCountChanged;
  
  const NotificationView({
    super.key,
    this.onUnreadCountChanged,
  });

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  bool _isSearchMode = false;
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _handleSearchChanged(String query) {
    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();
    
    // Update UI immediately for responsive feel
    setState(() {
      _searchQuery = query;
      _isSearchMode = query.isNotEmpty;
    });
    
    // Debounce the actual search operation
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<NotificationBloc>().add(
        NotificationSearchChanged(query),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set status bar styling
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          // Handle unread count changes and success messages
          if (state is NotificationLoaded) {
            widget.onUnreadCountChanged?.call(state.unreadCount);
            
            // Show success message if available
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          
          // Handle action success messages (legacy - can be removed later)
          if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          
          // Handle errors
          if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Thử lại',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      const NotificationRefreshRequested(),
                    );
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(
                const NotificationRefreshRequested(),
              );
            },
            child: CustomScrollView(
              slivers: [
                _buildHeader(context, state),
                _buildContent(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NotificationState state) {
    return SliverToBoxAdapter(
      child: NotificationHeader(
        onFilterTap: () => _showFilterBottomSheet(context, state),
        onMarkAllReadTap: () {
          context.read<NotificationBloc>().add(
            const NotificationMarkAllAsRead(),
          );
        },
        onSearchChanged: _handleSearchChanged,
        unreadCount: state is NotificationLoaded ? state.unreadCount : 0,
        totalCount: state is NotificationLoaded ? state.filteredNotifications.length : 0,
        isSearchMode: _isSearchMode,
        searchQuery: _searchQuery,
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationState state) {
    if (state is NotificationLoading) {
      return _buildLoadingState();
    }
    
    if (state is NotificationLoaded) {
      return _buildLoadedState(context, state);
    }
    
    if (state is NotificationError) {
      return _buildErrorState(context, state);
    }
    
    return _buildLoadingState();
  }

  Widget _buildLoadedState(BuildContext context, NotificationLoaded state) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Top spacing
        SafeArea(
          top: false,
          child: const SizedBox(height: 16),
        ),

        // Quick filter bar
        QuickFilterBar(
          currentFilter: state.currentFilter,
          onFilterChanged: (filter) {
            context.read<NotificationBloc>().add(
              NotificationFilterChanged(filter),
            );
          },
          totalCount: state.notifications.length,
          filteredCount: state.filteredNotifications.length,
        ),

        // Filter info if active
        if (state.currentFilter.hasActiveFilters)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.filter,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang hiển thị ${state.filteredNotifications.length} thông báo đã lọc',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<NotificationBloc>().add(
                      const NotificationFilterChanged(NotificationFilter()),
                    );
                  },
                  child: Icon(
                    TablerIcons.x,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

        // Notifications list or empty state
        if (state.filteredNotifications.isEmpty)
          _buildEmptyStateContent(context, state)
        else
          ...state.filteredNotifications.map((notification) {
            return Container(
              margin: const EdgeInsets.only(
                left: 4,
                right: 4,
                bottom: 8,
              ),
              child: NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
                onMarkRead: () => _toggleReadStatus(context, notification),
                onDelete: () => _deleteNotification(context, notification),
                onAction: () => _handleNotificationAction(context, notification),
                enableSwipeActions: true,
              ),
            );
          }).toList(),

        // Bottom spacing
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ]),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải thông báo...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, NotificationError state) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              TablerIcons.alert_circle,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationBloc>().add(
                  const NotificationLoadRequested(),
                );
              },
              icon: const Icon(TablerIcons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateContent(BuildContext context, NotificationLoaded state) {
    final theme = Theme.of(context);
    final hasActiveFilters = state.currentFilter.hasActiveFilters || _searchQuery.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            hasActiveFilters ? TablerIcons.filter_off : TablerIcons.bell_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters 
                ? 'Không có thông báo nào phù hợp'
                : 'Chưa có thông báo nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters 
                ? 'Thử thay đổi bộ lọc để xem thêm thông báo'
                : 'Thông báo mới sẽ hiển thị tại đây',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _isSearchMode = false;
                });
                context.read<NotificationBloc>().add(
                  const NotificationFilterChanged(NotificationFilter()),
                );
                context.read<NotificationBloc>().add(
                  const NotificationSearchChanged(''),
                );
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  // =============== EVENT HANDLERS ===============

  void _showFilterBottomSheet(BuildContext context, NotificationState state) {
    if (state is NotificationLoaded) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => NotificationFilterBottomSheet(
          initialFilter: state.currentFilter,
          onApply: (filter) {
            context.read<NotificationBloc>().add(
              NotificationFilterChanged(filter),
            );
          },
        ),
      );
    }
  }

  void _handleNotificationTap(BuildContext context, NotificationItem notification) {
    // If notification is actionable and has action URL, trigger the action
    if (notification.isActionable && notification.actionUrl != null) {
      _handleNotificationAction(context, notification);
    } else {
      // Mark as read if unread
      if (notification.status == NotificationStatus.unread) {
        context.read<NotificationBloc>().add(
          NotificationMarkAsRead(notification.id),
        );
      }

      // Show notification detail or simple message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã mở thông báo: ${notification.title}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleReadStatus(BuildContext context, NotificationItem notification) {
    if (notification.status == NotificationStatus.unread) {
      context.read<NotificationBloc>().add(
        NotificationMarkAsRead(notification.id),
      );
    } else {
      context.read<NotificationBloc>().add(
        NotificationMarkAsUnread(notification.id),
      );
    }
  }

  void _deleteNotification(BuildContext context, NotificationItem notification) {
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
              context.read<NotificationBloc>().add(
                NotificationDelete(notification.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(BuildContext context, NotificationItem notification) {
    // Mark as read if unread
    if (notification.status == NotificationStatus.unread) {
      context.read<NotificationBloc>().add(
        NotificationMarkAsRead(notification.id),
      );
    }

    // Handle action based on action URL
    if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      final actionUrl = notification.actionUrl!;
      
      // Check if it's a web URL using WebViewHelper
      if (WebViewHelper.isValidUrl(actionUrl)) {
        // Open in webview
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InAppWebViewPage(
              url: actionUrl,
              title: notification.title,
            ),
          ),
        );
      } else if (WebViewHelper.isInternalNavigation(actionUrl)) {
        // Handle internal app navigation
        _handleInternalNavigation(context, actionUrl, notification);
      } else {
        // Try to normalize URL and open in webview
        final normalizedUrl = WebViewHelper.normalizeUrl(actionUrl);
        if (WebViewHelper.isValidUrl(normalizedUrl)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InAppWebViewPage(
                url: normalizedUrl,
                title: notification.title,
              ),
            ),
          );
        } else {
          _showActionNotImplemented(context, actionUrl);
        }
      }
    } else {
      // No action URL, just show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã mở thông báo: ${notification.title}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleInternalNavigation(BuildContext context, String actionUrl, NotificationItem notification) {
    // Parse internal action URL and navigate accordingly
    try {
      final uri = Uri.parse(actionUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2) {
        final module = pathSegments[0];
        final action = pathSegments[1];
        
        switch (module) {
          case 'attendance':
            _navigateToAttendance(context, action);
            break;
          case 'training':
            _navigateToTraining(context, action);
            break;
          case 'leave':
            _navigateToLeave(context, action);
            break;
          case 'overtime':
            _navigateToOvertime(context, action);
            break;
          default:
            _showActionNotImplemented(context, actionUrl);
        }
      } else {
        _showActionNotImplemented(context, actionUrl);
      }
    } catch (e) {
      _showActionNotImplemented(context, actionUrl);
    }
  }

  void _navigateToAttendance(BuildContext context, String action) {
    // TODO: Navigate to attendance pages based on action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chuyển đến chấm công: $action'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToTraining(BuildContext context, String action) {
    // TODO: Navigate to training pages based on action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chuyển đến đào tạo: $action'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToLeave(BuildContext context, String action) {
    // TODO: Navigate to leave pages based on action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chuyển đến nghỉ phép: $action'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToOvertime(BuildContext context, String action) {
    // TODO: Navigate to overtime pages based on action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chuyển đến tăng ca: $action'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActionNotImplemented(BuildContext context, String actionUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chức năng chưa được triển khai: $actionUrl'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }
} 