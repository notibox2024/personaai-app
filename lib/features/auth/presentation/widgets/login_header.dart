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
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24, mediaQuery.padding.top + 40, 24, 4),
      child: Column(
        children: [
          // Logo trực tiếp với màu
          SvgAsset.kienlongbankIcon(
            width: 120,
            height: 120,
            color: colorScheme.primary,
            fit: BoxFit.contain,
          ),
          
          const SizedBox(height: 32),
          
          // Tiêu đề
          Text(
            'Chào mừng trở lại!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Phụ đề  
          Text(
            'Đăng nhập để tiếp tục sử dụng ứng dụng',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 