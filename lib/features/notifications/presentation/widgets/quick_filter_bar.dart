import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_filter.dart';

/// Quick filter bar với horizontal scrollable chips
class QuickFilterBar extends StatelessWidget {
  final NotificationFilter currentFilter;
  final Function(NotificationFilter) onFilterChanged;
  final int totalCount;
  final int filteredCount;
  
  const QuickFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Filter chips row
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Unread only filter
                _buildFilterChip(
                  context,
                  label: 'Chưa đọc',
                  icon: TablerIcons.mail,
                  isSelected: currentFilter.showOnlyUnread,
                  onTap: () => onFilterChanged(currentFilter.toggleUnreadOnly()),
                ),
                
                const SizedBox(width: 8),
                
                // Actionable only filter
                _buildFilterChip(
                  context,
                  label: 'Cần xử lý',
                  icon: TablerIcons.urgent,
                  isSelected: currentFilter.showOnlyActionable,
                  onTap: () => onFilterChanged(currentFilter.toggleActionableOnly()),
                ),
                
                const SizedBox(width: 8),
                
                // Date filters
                                 _buildFilterChip(
                   context,
                   label: 'Hôm nay',
                   icon: TablerIcons.calendar,
                   isSelected: currentFilter.dateFilter == DateFilter.today,
                   onTap: () => onFilterChanged(
                     currentFilter.setDateFilter(
                       currentFilter.dateFilter == DateFilter.today ? null : DateFilter.today,
                     ),
                   ),
                 ),
                 
                 const SizedBox(width: 8),
                 
                 _buildFilterChip(
                   context,
                   label: 'Tuần này',
                   icon: TablerIcons.calendar,
                  isSelected: currentFilter.dateFilter == DateFilter.thisWeek,
                  onTap: () => onFilterChanged(
                    currentFilter.setDateFilter(
                      currentFilter.dateFilter == DateFilter.thisWeek ? null : DateFilter.thisWeek,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Priority filters
                _buildFilterChip(
                  context,
                  label: 'Cao',
                  icon: TablerIcons.arrow_up,
                  color: Colors.orange,
                  isSelected: currentFilter.priority == NotificationPriority.high,
                  onTap: () => onFilterChanged(
                    currentFilter.setPriority(
                      currentFilter.priority == NotificationPriority.high 
                          ? null 
                          : NotificationPriority.high,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                _buildFilterChip(
                  context,
                  label: 'Khẩn cấp',
                  icon: TablerIcons.alert_triangle,
                  color: Colors.red,
                  isSelected: currentFilter.priority == NotificationPriority.urgent,
                  onTap: () => onFilterChanged(
                    currentFilter.setPriority(
                      currentFilter.priority == NotificationPriority.urgent 
                          ? null 
                          : NotificationPriority.urgent,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Type filters
                ..._buildTypeFilterChips(context),
                
                const SizedBox(width: 8),
                
                // Clear all filters
                if (currentFilter.hasActiveFilters)
                  _buildClearFiltersChip(context),
              ],
            ),
          ),
          
          // Filter count indicator
          if (currentFilter.hasActiveFilters)
            Container(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Hiển thị $filteredCount/$totalCount thông báo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build type filter chips
  List<Widget> _buildTypeFilterChips(BuildContext context) {
    final typeChips = <Widget>[];
    
    // Common types with icons
    final commonTypes = [
      (NotificationType.attendance, 'Chấm công', TablerIcons.clock, Colors.blue),
      (NotificationType.training, 'Đào tạo', TablerIcons.school, Colors.green),
             (NotificationType.leave, 'Nghỉ phép', TablerIcons.calendar_x, Colors.purple),
      (NotificationType.urgent, 'Khẩn cấp', TablerIcons.alert_triangle, Colors.red),
    ];
    
    for (final (type, label, icon, color) in commonTypes) {
      typeChips.add(
        _buildFilterChip(
          context,
          label: label,
          icon: icon,
          color: color,
          isSelected: currentFilter.types.contains(type),
          onTap: () => onFilterChanged(currentFilter.toggleType(type)),
        ),
      );
      typeChips.add(const SizedBox(width: 8));
    }
    
    return typeChips;
  }
  
  /// Build individual filter chip
  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? effectiveColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected 
                ? effectiveColor.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected 
                  ? effectiveColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? effectiveColor
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build clear all filters chip
  Widget _buildClearFiltersChip(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onFilterChanged(currentFilter.clear()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.x,
              size: 14,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Xóa bộ lọc',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 