import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../data/models/employee_info.dart';
import '../../../../themes/colors.dart';

/// Widget header section cho trang chủ
class HeaderSection extends StatelessWidget implements PreferredSizeWidget {
  final EmployeeInfo employee;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const HeaderSection({
    super.key,
    required this.employee,
    this.onNotificationTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: KienlongBankColors.primaryGradient,
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: employee.avatarUrl.isNotEmpty
                ? NetworkImage(employee.avatarUrl)
                : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: employee.avatarUrl.isEmpty
                ? Icon(
                    TablerIcons.user,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${employee.fullName}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              employee.position,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Notification button
          Stack(
            children: [
              IconButton(
                onPressed: onNotificationTap,
                icon: const Icon(
                  TablerIcons.bell,
                  color: Colors.white,
                ),
              ),
              if (employee.notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: KienlongBankColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${employee.notificationCount > 99 ? '99+' : employee.notificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Menu button
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(
              TablerIcons.menu_2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
        toolbarHeight: preferredSize.height,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
} 