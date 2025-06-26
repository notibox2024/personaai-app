import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../data/models/attendance_session.dart';
import '../../data/models/time_tracking.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Widget hiển thị trạng thái hiện tại của ca làm việc
class CurrentStatusCard extends StatelessWidget {
  final TimeTracking timeTracking;
  final AttendanceSession session;

  const CurrentStatusCard({
    super.key,
    required this.timeTracking,
    required this.session,
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
                TablerIcons.clock,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Trạng thái hiện tại',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (session.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đang hoạt động',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Work Progress Bar
          _buildWorkProgressSection(theme),

          const SizedBox(height: 20),

          // Time Stats Grid
          _buildTimeStatsGrid(theme),

          if (timeTracking.isOnBreak) ...[
            const SizedBox(height: 16),
            _buildBreakStatus(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkProgressSection(ThemeData theme) {
    final progress = timeTracking.workProgress;
    final progressPercentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến độ ca làm việc',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$progressPercentage%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0
              ? 'Đã hoàn thành ca làm việc tiêu chuẩn'
              : 'Còn ${timeTracking.timeUntilEndWorkString} đến hết ca',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStatsGrid(ThemeData theme) {
    return Row(
      children: [
        // Thời gian làm việc
        Expanded(
          child: _buildStatItem(
            theme: theme,
            icon: TablerIcons.clock_hour_4,
            label: 'Đã làm việc',
            value: timeTracking.currentWorkTimeString,
            color: theme.colorScheme.primary,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Thời gian nghỉ
        Expanded(
          child: _buildStatItem(
            theme: theme,
            icon: TablerIcons.coffee,
            label: 'Tổng nghỉ',
            value: timeTracking.totalBreakTimeString,
            color: theme.colorScheme.secondary,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Hiệu suất
        Expanded(
          child: _buildStatItem(
            theme: theme,
            icon: TablerIcons.trending_up,
            label: 'Hiệu suất',
            value: timeTracking.efficiencyString,
            color: timeTracking.efficiencyScore >= 0.8
                ? Colors.green
                : timeTracking.efficiencyScore >= 0.6
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.clock_pause,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang nghỉ giải lao',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Thời gian nghỉ: ${timeTracking.currentBreakString}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Đang nghỉ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 