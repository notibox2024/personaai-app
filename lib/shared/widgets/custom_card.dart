import 'package:flutter/material.dart';

/// Widget card tùy chỉnh cho toàn bộ app
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 2,
      surfaceTintColor: Colors.transparent,
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
} 