import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Widget grid các hành động nhanh cho trang cá nhân
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onEditProfileTap;
  final VoidCallback? onChangePasswordTap;
  final VoidCallback? onPayrollTap;
  final VoidCallback? onLeaveRequestTap;
  final VoidCallback? onDocumentsTap;
  final VoidCallback? onEmergencyContactTap;

  const QuickActionsGrid({
    super.key,
    this.onEditProfileTap,
    this.onChangePasswordTap,
    this.onPayrollTap,
    this.onLeaveRequestTap,
    this.onDocumentsTap,
    this.onEmergencyContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.apps,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thao tác nhanh',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Actions grid
         _buildActionsGrid(theme),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(ThemeData theme) {
    final actions = [
      _ActionItem(
        icon: TablerIcons.edit,
        label: 'Chỉnh sửa',
        subtitle: 'Thông tin',
        color: theme.colorScheme.primary,
        onTap: onEditProfileTap,
      ),
      _ActionItem(
        icon: TablerIcons.lock,
        label: 'Đổi mật khẩu',
        subtitle: 'Bảo mật',
        color: const Color(0xFF4CAF50),
        onTap: onChangePasswordTap,
      ),
      _ActionItem(
        icon: TablerIcons.wallet,
        label: 'Bảng lương',
        subtitle: 'Xem chi tiết',
        color: const Color(0xFFFF9800),
        onTap: onPayrollTap,
      ),
      _ActionItem(
        icon: TablerIcons.calendar_plus,
        label: 'Xin nghỉ phép',
        subtitle: 'Tạo đơn',
        color: const Color(0xFF2196F3),
        onTap: onLeaveRequestTap,
      ),
      _ActionItem(
        icon: TablerIcons.file_text,
        label: 'Tài liệu',
        subtitle: 'Cá nhân',
        color: const Color(0xFF9C27B0),
        onTap: onDocumentsTap,
      ),
      _ActionItem(
        icon: TablerIcons.phone,
        label: 'Liên hệ',
        subtitle: 'Khẩn cấp',
        color: const Color(0xFFF44336),
        onTap: onEmergencyContactTap,
      ),
    ];

    return Column(
      children: [
        // Row 1: First 2 actions
        Row(
          children: [
            Expanded(child: _buildActionButton(actions[0], theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(actions[1], theme)),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 2: Next 2 actions
        Row(
          children: [
            Expanded(child: _buildActionButton(actions[2], theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(actions[3], theme)),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 3: Last 2 actions
        Row(
          children: [
            Expanded(child: _buildActionButton(actions[4], theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(actions[5], theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(_ActionItem action, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: action.color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 18,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model cho action item
class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
} 