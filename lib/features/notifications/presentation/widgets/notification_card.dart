import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/models/notification_item.dart';

/// Widget card hiển thị thông báo
class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;
  final VoidCallback? onAction;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
    this.onDelete,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = notification.status == NotificationStatus.unread;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Highlight unread notifications
            color: isUnread 
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                : null,
            border: isUnread 
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon, title and time
              Row(
                children: [
                  // Type icon
                  _buildTypeIcon(theme),
                  
                  const SizedBox(width: 12),
                  
                  // Title and metadata
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
                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (notification.isNew)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 2),
                        
                        // Time and sender
                        Row(
                          children: [
                            Text(
                              notification.timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (notification.senderName != null) ...[
                              Text(
                                ' • ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                notification.senderName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions menu
                  _buildActionsMenu(theme),
                ],
              ),

              const SizedBox(height: 12),

              // Message content
              Text(
                notification.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Priority indicator
              if (notification.priority != NotificationPriority.normal) ...[
                const SizedBox(height: 8),
                _buildPriorityChip(theme),
              ],

              // Action button
              if (notification.isActionable) ...[
                const SizedBox(height: 12),
                _buildActionButton(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ThemeData theme) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.attendance:
        icon = TablerIcons.clock;
        iconColor = Colors.blue;
        break;
      case NotificationType.training:
        icon = TablerIcons.school;
        iconColor = Colors.green;
        break;
      case NotificationType.leave:
        icon = TablerIcons.calendar_minus;
        iconColor = Colors.orange;
        break;
      case NotificationType.overtime:
        icon = TablerIcons.clock_plus;
        iconColor = Colors.purple;
        break;
      case NotificationType.general:
        icon = TablerIcons.info_circle;
        iconColor = Colors.blue;
        break;
      case NotificationType.system:
        icon = TablerIcons.settings;
        iconColor = Colors.grey;
        break;
      case NotificationType.urgent:
        icon = TablerIcons.alert_triangle;
        iconColor = Colors.red;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildActionsMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        TablerIcons.dots_vertical,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
      itemBuilder: (context) => [
        if (notification.status == NotificationStatus.unread)
          PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(TablerIcons.check, size: 18, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                const Text('Đánh dấu đã đọc'),
              ],
            ),
          ),
        if (notification.status == NotificationStatus.read)
          PopupMenuItem(
            value: 'mark_unread',
            child: Row(
              children: [
                Icon(TablerIcons.mail, size: 18, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                const Text('Đánh dấu chưa đọc'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(TablerIcons.trash, size: 18, color: Colors.red),
              const SizedBox(width: 12),
              Text('Xóa', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'mark_read':
          case 'mark_unread':
            onMarkRead?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
    );
  }

  Widget _buildPriorityChip(ThemeData theme) {
    Color chipColor;
    String priorityText;
    IconData priorityIcon;

    switch (notification.priority) {
      case NotificationPriority.high:
        chipColor = Colors.orange;
        priorityText = 'Ưu tiên cao';
        priorityIcon = TablerIcons.arrow_up;
        break;
      case NotificationPriority.urgent:
        chipColor = Colors.red;
        priorityText = 'Khẩn cấp';
        priorityIcon = TablerIcons.alert_triangle;
        break;
      case NotificationPriority.low:
        chipColor = Colors.grey;
        priorityText = 'Ưu tiên thấp';
        priorityIcon = TablerIcons.arrow_down;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityIcon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            priorityText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onAction,
        icon: Icon(
          TablerIcons.external_link,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        label: const Text('Xem chi tiết'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 