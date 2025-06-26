import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../data/models/employee_info.dart';
import '../../../../themes/colors.dart';
import '../../../../shared/shared_exports.dart';

/// Widget header section có thể scroll được
class ScrollableHeader extends StatelessWidget {
  final EmployeeInfo employee;
  final VoidCallback? onThemeToggle;

  const ScrollableHeader({
    super.key,
    required this.employee,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.headerColor,
      ),
      child: Stack(
        children: [
          // Background icon chìm mờ ở góc dưới bên phải
          Positioned(
            bottom: -40,
            right: -30,
            child: Opacity(
              opacity: 0.1,
              child: SvgAsset.kienlongbankIcon(
                width: 160,
                height: 160,
                color: Colors.white,
              ),
            ),
          ),
          
          // Content chính
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Row(
                children: [
                  // Avatar và thông tin nhân viên
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: employee.avatarUrl.isNotEmpty
                              ? NetworkImage(employee.avatarUrl)
                              : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: employee.avatarUrl.isEmpty
                              ? Icon(
                                  TablerIcons.user,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, ${employee.fullName}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                employee.position,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Theme toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: onThemeToggle,
                      icon: Icon(
                        _getThemeIcon(context),
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Chuyển đổi theme',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  /// Lấy icon theme phù hợp với theme hiện tại
  IconData _getThemeIcon(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    switch (brightness) {
      case Brightness.light:
        return TablerIcons.moon; // Đang light mode, hiển thị moon để chuyển sang dark
      case Brightness.dark:
        return TablerIcons.sun; // Đang dark mode, hiển thị sun để chuyển sang light
    }
  }
} 