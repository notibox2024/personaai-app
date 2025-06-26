import 'package:flutter/material.dart';

/// Widget button hành động nhanh
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = iconColor ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withValues(alpha: 0.08),
          highlightColor: primaryColor.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container với background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 