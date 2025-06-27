import 'package:flutter/material.dart';

/// Custom painter để tạo pattern trang trí cho background
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    const dotRadius = 2.0;

    // Vẽ pattern chấm tròn
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x + (y % (spacing * 2) == 0 ? 0 : spacing / 2), y),
          dotRadius,
          Paint()..color = color,
        );
      }
    }

    // Vẽ thêm một số đường chéo trang trí
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (double i = -size.height; i < size.width; i += spacing * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 