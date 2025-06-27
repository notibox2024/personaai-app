import 'package:flutter/material.dart';
import '../../../../shared/widgets/svg_asset.dart';

/// Widget header cho màn hình đăng nhập
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    
    // Màu tương phản với background cam
    final iconColor = theme.brightness == Brightness.light 
        ? Colors.white 
        : Colors.white.withValues(alpha: 0.9);
    
    final titleColor = theme.brightness == Brightness.light 
        ? Colors.white 
        : Colors.white.withValues(alpha: 0.95);
        
    final subtitleColor = theme.brightness == Brightness.light 
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.8);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24, mediaQuery.padding.top + 40, 24, 4),
      child: Column(
        children: [
          // Logo với màu trắng để tương phản với background cam
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: SvgAsset.kienlongbankIcon(
              width: 80,
              height: 80,
              color: iconColor,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Tiêu đề với màu trắng
          Text(
            'Chào mừng trở lại!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Phụ đề với màu trắng nhẹ
          Text(
            'Đăng nhập để tiếp tục sử dụng ứng dụng',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: subtitleColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 