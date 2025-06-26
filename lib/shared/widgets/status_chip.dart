import 'package:flutter/material.dart';

/// Widget hiển thị trạng thái dạng chip
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize != null ? fontSize! + 2 : 16,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 