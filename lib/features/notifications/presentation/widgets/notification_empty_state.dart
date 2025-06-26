import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Widget hiển thị trạng thái rỗng cho thông báo
class NotificationEmptyState extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  const NotificationEmptyState({
    super.key,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              hasActiveFilters 
                  ? TablerIcons.filter_off 
                  : TablerIcons.bell_off,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            hasActiveFilters 
                ? 'Không có thông báo nào'
                : 'Chưa có thông báo',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            hasActiveFilters 
                ? 'Không có thông báo nào phù hợp với bộ lọc hiện tại. Thử thay đổi bộ lọc để xem thêm thông báo.'
                : 'Khi có thông báo mới, chúng sẽ hiển thị tại đây. Bạn sẽ nhận được thông báo về chấm công, đào tạo và các hoạt động khác.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (hasActiveFilters) ...[
            const SizedBox(height: 24),
            
            // Clear filters button
            FilledButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(TablerIcons.filter_off),
              label: const Text('Xóa bộ lọc'),
            ),
          ] else ...[
            const SizedBox(height: 24),
            
            // Tips card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    TablerIcons.bulb,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mẹo: Bạn có thể bật thông báo đẩy để nhận cập nhật kịp thời',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 