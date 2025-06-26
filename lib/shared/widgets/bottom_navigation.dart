import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'icon_with_badge.dart';

/// Model cho bottom navigation item
class BottomNavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final int badgeCount;

  const BottomNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badgeCount = 0,
  });
}

/// Widget bottom navigation bar tùy chỉnh
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with background
                        Container(
                          width: 34, // Fixed container size
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: item.badgeCount > 0 
                                ? IconWithBadge(
                                    icon: isSelected && item.activeIcon != null 
                                        ? item.activeIcon! 
                                        : item.icon,
                                    iconColor: isSelected 
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    iconSize: 22,
                                    badgeCount: item.badgeCount,
                                  )
                                : Icon(
                                    isSelected && item.activeIcon != null 
                                        ? item.activeIcon! 
                                        : item.icon,
                                    color: isSelected 
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        Text(
                          item.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected 
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.w400,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Factory method để tạo default navigation items
  static List<BottomNavItem> getDefaultItems() {
    return [
      const BottomNavItem(
        id: 'home',
        label: 'Trang chủ',
        icon: TablerIcons.home,
        activeIcon: TablerIcons.home, // Sử dụng cùng icon để tránh lệch
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
      const BottomNavItem(
        id: 'notifications',
        label: 'Thông báo',
        icon: TablerIcons.bell,
        activeIcon: TablerIcons.bell,
      ),
      const BottomNavItem(
        id: 'profile',
        label: 'Cá nhân',
        icon: TablerIcons.user,
        activeIcon: TablerIcons.user,
      ),
    ];
  }
} 