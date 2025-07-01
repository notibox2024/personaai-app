import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/models/notification_item.dart';

/// Enhanced notification card với swipe actions và dynamic buttons
class NotificationCard extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;
  final VoidCallback? onAction;
  final bool enableSwipeActions;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
    this.onDelete,
    this.onAction,
    this.enableSwipeActions = true,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // Stop and dispose animation safely
    try {
      _animationController.stop();
      _animationController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
    
    super.dispose();
  }

  NotificationItem get notification => widget.notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = notification.status == NotificationStatus.unread;

    if (widget.enableSwipeActions) {
      return _buildSwipeableCard(theme, isUnread);
    }
    
    return _buildRegularCard(theme, isUnread);
  }

  Widget _buildSwipeableCard(ThemeData theme, bool isUnread) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(theme, true),
      secondaryBackground: _buildSwipeBackground(theme, false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as read/unread
          widget.onMarkRead?.call();
          return false; // Don't actually dismiss
        } else {
          // Delete
          return await _showDeleteConfirmation();
        }
      },
      child: _buildCardContent(theme, isUnread),
    );
  }

  Widget _buildRegularCard(ThemeData theme, bool isUnread) {
    return _buildCardContent(theme, isUnread);
  }

  Widget _buildCardContent(ThemeData theme, bool isUnread) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  _animationController.forward();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    // Enhanced unread notification styling
                    color: isUnread 
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                        : null,
                    border: _getBorderForPriority(theme, isUnread),
                    // Subtle shadow for better depth
                    boxShadow: _isPressed ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced header with priority indicators
                      Row(
                        children: [
                          _buildEnhancedTypeIcon(theme),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                          color: _getTitleColor(theme, isUnread),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Enhanced status indicators
                                    _buildStatusIndicators(theme),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _buildMetadataRow(theme),
                              ],
                            ),
                          ),
                          _buildActionsMenu(theme),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Enhanced message content
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Enhanced priority indicator
                      if (notification.priority != NotificationPriority.normal) ...[
                        const SizedBox(height: 10),
                        _buildEnhancedPriorityChip(theme),
                      ],

                      // Dynamic action button
                      if (notification.isActionable) ...[
                        const SizedBox(height: 14),
                        _buildDynamicActionButton(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =============== SWIPE ACTIONS ===============

  Widget _buildSwipeBackground(ThemeData theme, bool isLeftSwipe) {
    final isMarkRead = isLeftSwipe;
    final color = isMarkRead ? Colors.green : Colors.red;
    final icon = isMarkRead 
        ? (notification.status == NotificationStatus.unread ? TablerIcons.check : TablerIcons.mail)
        : TablerIcons.trash;
    final text = isMarkRead 
        ? (notification.status == NotificationStatus.unread ? 'Đánh dấu đã đọc' : 'Đánh dấu chưa đọc')
        : 'Xóa';

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isLeftSwipe ? 20 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    ) ?? false;
  }

  // =============== ENHANCED UI COMPONENTS ===============

  Widget _buildEnhancedTypeIcon(ThemeData theme) {
    final iconData = _getTypeIconData();
    final iconColor = _getTypeIconColor();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildStatusIndicators(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Priority badge
        if (notification.priority == NotificationPriority.urgent)
          Container(
            margin: const EdgeInsets.only(left: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        
        // Unread indicator
        if (notification.status == NotificationStatus.unread)
          Container(
            margin: const EdgeInsets.only(left: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        
        // Actionable indicator
        if (notification.isActionable)
          Container(
            margin: const EdgeInsets.only(left: 6),
            child: Icon(
              TablerIcons.arrow_right,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildMetadataRow(ThemeData theme) {
    return Row(
      children: [
        Icon(
          TablerIcons.clock,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          notification.timeAgo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        if (notification.senderName != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            TablerIcons.user,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              notification.senderName!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedPriorityChip(ThemeData theme) {
    final priorityData = _getPriorityData();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: priorityData['color'].withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priorityData['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityData['icon'],
            size: 14,
            color: priorityData['color'],
          ),
          const SizedBox(width: 6),
          Text(
            priorityData['text'],
            style: theme.textTheme.labelSmall?.copyWith(
              color: priorityData['color'],
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicActionButton(ThemeData theme) {
    final actionData = _getActionButtonData();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onAction,
        icon: Icon(
          actionData['icon'],
          size: 18,
        ),
        label: Text(
          actionData['text'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: actionData['color'].withValues(alpha: 0.1),
          foregroundColor: actionData['color'],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: actionData['color'].withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        TablerIcons.dots_vertical,
        color: theme.colorScheme.onSurfaceVariant,
        size: 18,
      ),
      iconSize: 18,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        if (notification.status == NotificationStatus.unread)
          PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(TablerIcons.check, size: 16, color: Colors.green),
                const SizedBox(width: 10),
                const Text('Đánh dấu đã đọc'),
              ],
            ),
          ),
        if (notification.status == NotificationStatus.read)
          PopupMenuItem(
            value: 'mark_unread',
            child: Row(
              children: [
                Icon(TablerIcons.mail, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Text('Đánh dấu chưa đọc'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(TablerIcons.trash, size: 16, color: Colors.red),
              const SizedBox(width: 10),
              Text('Xóa', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'mark_read':
          case 'mark_unread':
            widget.onMarkRead?.call();
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
        }
      },
    );
  }

  // =============== HELPER METHODS ===============

  IconData _getTypeIconData() {
    switch (notification.type) {
      case NotificationType.attendance:
        return TablerIcons.clock;
      case NotificationType.training:
        return TablerIcons.school;
      case NotificationType.leave:
        return TablerIcons.calendar_x;
      case NotificationType.overtime:
        return TablerIcons.clock_plus;
      case NotificationType.general:
        return TablerIcons.info_circle;
      case NotificationType.system:
        return TablerIcons.settings;
      case NotificationType.urgent:
        return TablerIcons.alert_triangle;
    }
  }

  Color _getTypeIconColor() {
    switch (notification.type) {
      case NotificationType.attendance:
        return Colors.blue;
      case NotificationType.training:
        return Colors.green;
      case NotificationType.leave:
        return Colors.orange;
      case NotificationType.overtime:
        return Colors.purple;
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.urgent:
        return Colors.red;
    }
  }

  Border? _getBorderForPriority(ThemeData theme, bool isUnread) {
    if (notification.priority == NotificationPriority.urgent) {
      return Border.all(
        color: Colors.red.withValues(alpha: 0.4),
        width: 1.5,
      );
    } else if (notification.priority == NotificationPriority.high) {
      return Border.all(
        color: Colors.orange.withValues(alpha: 0.3),
        width: 1,
      );
    } else if (isUnread) {
      return Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
        width: 1,
      );
    }
    return null;
  }

  Color _getTitleColor(ThemeData theme, bool isUnread) {
    if (notification.priority == NotificationPriority.urgent) {
      return Colors.red.shade700;
    }
    return theme.colorScheme.onSurface;
  }

  Map<String, dynamic> _getPriorityData() {
    switch (notification.priority) {
      case NotificationPriority.high:
        return {
          'color': Colors.orange,
          'text': 'Ưu tiên cao',
          'icon': TablerIcons.arrow_up,
        };
      case NotificationPriority.urgent:
        return {
          'color': Colors.red,
          'text': 'Khẩn cấp',
          'icon': TablerIcons.alert_triangle,
        };
      case NotificationPriority.low:
        return {
          'color': Colors.grey,
          'text': 'Ưu tiên thấp',
          'icon': TablerIcons.arrow_down,
        };
      default:
        return {
          'color': Colors.blue,
          'text': 'Bình thường',
          'icon': TablerIcons.minus,
        };
    }
  }

  /// Dynamic action button data based on action URL structure
  Map<String, dynamic> _getActionButtonData() {
    final actionUrl = notification.actionUrl;
    
    if (actionUrl != null && actionUrl.isNotEmpty) {
      // Parse action URL structure: /[module]/[action]/[optional_id]
      final parts = actionUrl.split('/').where((p) => p.isNotEmpty).toList();
      
      if (parts.length >= 2) {
        final module = parts[0];
        final action = parts[1];
        
        // Attendance actions
        if (module == 'attendance') {
          switch (action) {
            case 'check-in':
              return {
                'text': 'Chấm công vào',
                'icon': TablerIcons.login,
                'color': Colors.green,
              };
            case 'check-out':
              return {
                'text': 'Chấm công ra',
                'icon': TablerIcons.logout,
                'color': Colors.orange,
              };
            case 'supplement':
              return {
                'text': 'Bổ sung chấm công',
                'icon': TablerIcons.clock_plus,
                'color': Colors.blue,
              };
            default:
              return {
                'text': 'Xem chấm công',
                'icon': TablerIcons.clock,
                'color': Colors.blue,
              };
          }
        }
        
        // Training actions
        else if (module == 'training') {
          switch (action) {
            case 'register':
              return {
                'text': 'Đăng ký khóa học',
                'icon': TablerIcons.plus,
                'color': Colors.green,
              };
                         case 'continue':
               return {
                 'text': 'Tiếp tục học',
                 'icon': TablerIcons.player_play,
                 'color': Colors.blue,
               };
            case 'certificate':
              return {
                'text': 'Xem chứng chỉ',
                'icon': TablerIcons.certificate,
                'color': Colors.purple,
              };
            default:
              return {
                'text': 'Xem khóa học',
                'icon': TablerIcons.school,
                'color': Colors.green,
              };
          }
        }
        
        // Leave actions
        else if (module == 'leave') {
          switch (action) {
            case 'apply':
              return {
                'text': 'Nộp đơn nghỉ',
                'icon': TablerIcons.plus,
                'color': Colors.orange,
              };
            case 'details':
              return {
                'text': 'Xem chi tiết',
                'icon': TablerIcons.eye,
                'color': Colors.blue,
              };
            default:
              return {
                'text': 'Xem nghỉ phép',
                'icon': TablerIcons.calendar_x,
                'color': Colors.orange,
              };
          }
        }
        
        // Overtime actions
        else if (module == 'overtime') {
          switch (action) {
            case 'request':
              return {
                'text': 'Gửi yêu cầu',
                'icon': TablerIcons.send,
                'color': Colors.purple,
              };
            case 'respond':
              return {
                'text': 'Phản hồi',
                'icon': TablerIcons.message,
                'color': Colors.blue,
              };
            default:
              return {
                'text': 'Xem tăng ca',
                'icon': TablerIcons.clock_plus,
                'color': Colors.purple,
              };
          }
        }
      }
    }
    
    // Fallback based on notification type
    switch (notification.type) {
      case NotificationType.attendance:
        return {
          'text': 'Xem chấm công',
          'icon': TablerIcons.clock,
          'color': Colors.blue,
        };
      case NotificationType.training:
        return {
          'text': 'Xem khóa học',
          'icon': TablerIcons.school,
          'color': Colors.green,
        };
      case NotificationType.leave:
        return {
          'text': 'Xem nghỉ phép',
          'icon': TablerIcons.calendar_x,
          'color': Colors.orange,
        };
      case NotificationType.overtime:
        return {
          'text': 'Xem tăng ca',
          'icon': TablerIcons.clock_plus,
          'color': Colors.purple,
        };
      default:
        return {
          'text': 'Xem chi tiết',
          'icon': TablerIcons.eye,
          'color': Colors.blue,
        };
    }
  }
} 