import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/models/user_profile.dart';

/// Widget card hiển thị thông tin cá nhân chi tiết
class PersonalInfoCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onEditTap;

  const PersonalInfoCard({
    super.key,
    required this.profile,
    this.onEditTap,
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
                TablerIcons.user_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin cá nhân',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEditTap,
                icon: Icon(
                  TablerIcons.edit,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Chỉnh sửa',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Info grid
          _buildInfoGrid(theme),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(ThemeData theme) {
    return Column(
      children: [
        // Row 1: Mã NV, Ngày sinh
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.id,
                label: 'Mã nhân viên',
                value: profile.employeeId,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.cake,
                label: 'Ngày sinh',
                value: profile.birthDate != null 
                    ? _formatDate(profile.birthDate!) 
                    : 'Chưa cập nhật',
                theme: theme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Row 2: Điện thoại, Email
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.phone,
                label: 'Điện thoại',
                value: profile.phone ?? 'Chưa cập nhật',
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.mail,
                label: 'Email',
                value: profile.email,
                theme: theme,
              ),
            ),
          ],
        ),

        if (profile.address != null) ...[
          const SizedBox(height: 16),
          
          // Address (full width)
          _buildInfoItem(
            icon: TablerIcons.map_pin,
            label: 'Địa chỉ',
            value: profile.address!,
            theme: theme,
            isFullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: isFullWidth 
          ? Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 