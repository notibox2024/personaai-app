import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Widget footer cho màn hình đăng nhập
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Màu tương phản với background cam
    final primaryTextColor = theme.brightness == Brightness.light 
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.85);
    
    final secondaryTextColor = theme.brightness == Brightness.light 
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.75);
    
    final dividerColor = theme.brightness == Brightness.light 
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.25);
    
    final buttonTextColor = theme.brightness == Brightness.light 
        ? Colors.white
        : Colors.white.withValues(alpha: 0.95);
    
    return Column(
      children: [
        // Divider với text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'hoặc',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryTextColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: 1,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Đăng ký mới
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chưa có tài khoản? ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: primaryTextColor,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _handleRegister(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Đăng ký ngay',
                style: TextStyle(
                  color: buttonTextColor,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Hỗ trợ
        TextButton.icon(
          onPressed: () => _handleSupport(context),
          icon: Icon(
            TablerIcons.headset,
            color: primaryTextColor,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          label: Text(
            'Hỗ trợ kỹ thuật',
            style: TextStyle(
              color: primaryTextColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Version info
        Text(
          'Phiên bản 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Copyright
        Text(
          '© 2024 KienLongBank. Tất cả quyền được bảo lưu.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: secondaryTextColor.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Xử lý đăng ký
  void _handleRegister(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đăng ký sẽ được phát triển sau'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Xử lý hỗ trợ
  void _handleSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hỗ trợ kỹ thuật'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liên hệ hỗ trợ:'),
            SizedBox(height: 8),
            Text('📧 Email: support@kienlongbank.com'),
            Text('📞 Hotline: 1900 1234'),
            Text('🕒 Thời gian: 8:00 - 17:00 (T2-T6)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
} 