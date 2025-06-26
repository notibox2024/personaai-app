import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../data/models/monthly_stats.dart';
import '../../../../../shared/widgets/custom_card.dart';
import '../../../../../themes/colors.dart';

/// Widget card hiển thị thống kê tháng
class MonthlyStatsCard extends StatelessWidget {
  final MonthlyStats monthlyStats;
  final VoidCallback? onTap;

  const MonthlyStatsCard({
    super.key,
    required this.monthlyStats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.chart_bar,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thống Kê Tháng ${monthlyStats.monthYearString}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Work days progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ngày làm việc',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${monthlyStats.workDaysCompleted}/${monthlyStats.totalWorkDays}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: monthlyStats.completionPercentage / 100,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: TablerIcons.calendar_off,
                  label: 'Ngày nghỉ còn lại',
                  value: '${monthlyStats.remainingLeaveDays}',
                  color: KienlongBankColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  icon: TablerIcons.clock_plus,
                  label: 'Giờ overtime',
                  value: monthlyStats.overtimeString,
                  color: KienlongBankColors.warning,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Performance rating
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPerformanceColor(monthlyStats.performanceRating).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPerformanceColor(monthlyStats.performanceRating).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.trophy,
                  color: _getPerformanceColor(monthlyStats.performanceRating),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hiệu suất: ${monthlyStats.performanceLevel}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Điểm: ${monthlyStats.ratingString}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getPerformanceColor(monthlyStats.performanceRating),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double rating) {
    if (rating >= 9.0) return KienlongBankColors.success;
    if (rating >= 7.0) return KienlongBankColors.info;
    if (rating >= 5.0) return KienlongBankColors.warning;
    return KienlongBankColors.error;
  }
}

/// Widget item thống kê nhỏ
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 