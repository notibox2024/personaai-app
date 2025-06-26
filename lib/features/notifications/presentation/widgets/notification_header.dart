import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../themes/colors.dart';
import '../../../../shared/shared_exports.dart';

/// Widget header section cho trang thông báo
class NotificationHeader extends StatelessWidget {
  final VoidCallback? onFilterTap;
  final VoidCallback? onMarkAllReadTap;
  final int unreadCount;

  const NotificationHeader({
    super.key,
    this.onFilterTap,
    this.onMarkAllReadTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Container(
       decoration: BoxDecoration(
        color: theme.colorScheme.headerColor,
      ),
      child: Stack(
        children: [
          // Background icon chìm mờ ở góc dưới bên phải
          Positioned(
            bottom: -40,
            right: -30,
            child: Opacity(
              opacity: 0.1,
              child: SvgAsset.kienlongbankIcon(
                width: 160,
                height: 160,
                color: Colors.white,
              ),
            ),
          ),
          
          // Content chính
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 
              MediaQuery.of(context).padding.top + 16, // Add status bar height
              16, 
              20
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title, count badge and action buttons
                Row(
                  children: [
                    // Title
                    Text(
                      'Thông báo',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Unread count badge
                    if (unreadCount > 0)
                      _buildUnreadBadge(theme),
                    
                    const Spacer(),
                    
                    // Mark all read button
                    if (unreadCount > 0)
                      IconButton(
                        onPressed: onMarkAllReadTap,
                        icon: const Icon(
                          TablerIcons.checks,
                          color: Colors.white,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(44, 44),
                        ),
                        tooltip: 'Đánh dấu tất cả đã đọc',
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Filter button
                    IconButton(
                      onPressed: onFilterTap,
                      icon: const Icon(
                        TablerIcons.filter,
                        color: Colors.white,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(44, 44),
                      ),
                      tooltip: 'Lọc thông báo',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Date info
                Text(
                  _formatDate(now),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle with unread count
                Text(
                  unreadCount > 0 
                      ? 'Bạn có $unreadCount thông báo chưa đọc'
                      : 'Tất cả thông báo đã được đọc',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TablerIcons.bell,
            size: 14,
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            '$unreadCount mới',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      '', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];
    return '${weekdays[date.weekday]}, ${date.day} tháng ${date.month}, ${date.year}';
  }
} 