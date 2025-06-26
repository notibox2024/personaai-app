import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/models/user_profile.dart';

/// Widget card hiển thị thông tin công việc
class WorkInfoCard extends StatelessWidget {
  final UserProfile profile;

  const WorkInfoCard({
    super.key,
    required this.profile,
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
                TablerIcons.briefcase,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin công việc',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Work info grid
          _buildWorkInfoGrid(theme),

          const SizedBox(height: 16),

          // Timeline section
          _buildTimelineSection(theme),
        ],
      ),
    );
  }

  Widget _buildWorkInfoGrid(ThemeData theme) {
    return Column(
      children: [
        // Row 1: Chức vụ, Phòng ban
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.crown,
                label: 'Chức vụ',
                value: profile.position,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.building,
                label: 'Phòng ban',
                value: profile.department,
                theme: theme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2: Loại hợp đồng, Lịch làm việc
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.file_text,
                label: 'Loại hợp đồng',
                value: profile.workInfo.contractType,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                icon: TablerIcons.clock,
                label: 'Lịch làm việc',
                value: profile.workInfo.workSchedule,
                theme: theme,
              ),
            ),
          ],
        ),

        if (profile.workInfo.managerName != null) ...[
          const SizedBox(height: 12),
          
          // Manager info (full width)
          _buildInfoItem(
            icon: TablerIcons.user_star,
            label: 'Quản lý trực tiếp',
            value: profile.workInfo.managerName!,
            theme: theme,
            isFullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    final joinDate = profile.joinDate;
    final yearsOfService = profile.yearsOfService;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              TablerIcons.calendar_event,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Timeline info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian làm việc',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$yearsOfService năm',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tham gia từ ${_formatDate(joinDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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