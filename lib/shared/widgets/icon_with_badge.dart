import 'package:flutter/material.dart';

/// Widget icon với badge số hiển thị ở góc trên bên phải
class IconWithBadge extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final int badgeCount;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final double? badgeSize;

  const IconWithBadge({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconSize = 22,
    this.badgeCount = 0,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Icon chính
        Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
        
        // Badge
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: BoxConstraints(
                minWidth: badgeSize ?? 16,
                minHeight: badgeSize ?? 16,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular((badgeSize ?? 16) / 2),
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: TextStyle(
                    color: badgeTextColor ?? Colors.white,
                    fontSize: badgeCount > 99 ? 8 : 9,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 