import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../data/models/notification_item.dart';
import '../../../../../shared/widgets/custom_card.dart';

/// Widget card hiển thị thông báo quan trọng
class NotificationsCard extends StatelessWidget {
  final List<NotificationItem> notifications;
  final VoidCallback? onSeeAllTap;
  final Function(NotificationItem)? onNotificationTap;

  const NotificationsCard({
    super.key,
    required this.notifications,
    this.onSeeAllTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayNotifications = notifications.take(3).toList();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.bell,
                color: theme.colorScheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thông Báo Quan Trọng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (notifications.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${notifications.length - 3}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          if (displayNotifications.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    TablerIcons.bell_off,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không có thông báo mới',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 16),
            
            // Notification items
            ...displayNotifications.map((notification) => 
              _NotificationItem(
                notification: notification,
                onTap: () => onNotificationTap?.call(notification),
              ),
            ),
            
            if (onSeeAllTap != null) ...[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              InkWell(
                onTap: onSeeAllTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        TablerIcons.book_2,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Xem tất cả (${notifications.length})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Widget item thông báo
class _NotificationItem extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;

  const _NotificationItem({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? Colors.transparent 
                : theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: notification.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    notification.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead 
                                  ? FontWeight.w400 
                                  : FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.isImportant)
                          Icon(
                            TablerIcons.star_filled,
                            size: 14,
                            color: Colors.amber,
                          ),
                      ],
                    ),
                    if (notification.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.content,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          notification.type.icon,
                          size: 12,
                          color: notification.type.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.type.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: notification.type.color,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.timeAgoString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 