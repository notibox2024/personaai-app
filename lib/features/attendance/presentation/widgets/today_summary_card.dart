import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../data/models/attendance_session.dart';
import '../../data/models/time_tracking.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Widget tóm tắt ca làm việc hôm nay
class TodaySummaryCard extends StatelessWidget {
  final TimeTracking timeTracking;
  final AttendanceSession session;

  const TodaySummaryCard({
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
                TablerIcons.calendar_event,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tóm tắt hôm nay',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _getTodayDateString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Work Timeline
          _buildWorkTimeline(theme),

          const SizedBox(height: 20),

          // Summary Stats
          _buildSummaryStats(theme),

          const SizedBox(height: 16),

          // Break Sessions
          if (timeTracking.breakSessions.isNotEmpty)
            _buildBreakSessions(theme),
        ],
      ),
    );
  }

  Widget _buildWorkTimeline(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline ca làm việc',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Timeline Items
        _buildTimelineItem(
          theme: theme,
          icon: TablerIcons.clock_hour_4,
          title: 'Vào làm',
          time: session.checkInTimeString,
          color: theme.colorScheme.primary,
          isCompleted: session.checkInTime != null,
        ),
        
        const SizedBox(height: 8),
        
        _buildTimelineItem(
          theme: theme,
          icon: TablerIcons.coffee,
          title: 'Nghỉ trưa',
          time: _getLunchBreakTime(),
          color: theme.colorScheme.secondary,
          isCompleted: _hasLunchBreak(),
        ),
        
        const SizedBox(height: 8),
        
        _buildTimelineItem(
          theme: theme,
          icon: TablerIcons.clock_hour_9,
          title: 'Ra về',
          time: session.checkOutTime != null 
              ? session.checkOutTimeString 
              : session.expectedEndTimeString,
          color: session.checkOutTime != null 
              ? Colors.green 
              : theme.colorScheme.onSurfaceVariant,
          isCompleted: session.checkOutTime != null,
          isExpected: session.checkOutTime == null,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String time,
    required Color color,
    required bool isCompleted,
    bool isExpected = false,
  }) {
    return Row(
      children: [
        // Timeline Indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted 
                ? color 
                : color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isCompleted ? 0 : 2,
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted 
                ? Colors.white 
                : color,
            size: 16,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isCompleted 
                      ? FontWeight.w600 
                      : FontWeight.w400,
                  color: isCompleted 
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  if (isExpected)
                    Text(
                      'dự kiến ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Text(
                    time,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted 
                          ? color
                          : theme.colorScheme.onSurfaceVariant,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Total Work Time
              Expanded(
                child: _buildStatColumn(
                  theme: theme,
                  label: 'Tổng làm việc',
                  value: timeTracking.currentWorkTimeString,
                  icon: TablerIcons.clock,
                  color: theme.colorScheme.primary,
                ),
              ),
              
              // Total Break Time
              Expanded(
                child: _buildStatColumn(
                  theme: theme,
                  label: 'Tổng nghỉ',
                  value: timeTracking.totalBreakTimeString,
                  icon: TablerIcons.coffee,
                  color: theme.colorScheme.secondary,
                ),
              ),
              
              // Overtime
              Expanded(
                child: _buildStatColumn(
                  theme: theme,
                  label: 'Tăng ca',
                  value: timeTracking.overtimeString,
                  icon: TablerIcons.clock_plus,
                  color: timeTracking.overtimeHours.inMinutes > 0
                      ? Colors.orange
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
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
    );
  }

  Widget _buildBreakSessions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử nghỉ giải lao',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...timeTracking.breakSessions.map((breakSession) =>
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getBreakIcon(breakSession.type),
                  color: theme.colorScheme.secondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    breakSession.typeDisplayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${breakSession.startTime.hour.toString().padLeft(2, '0')}:${breakSession.startTime.minute.toString().padLeft(2, '0')} - ${breakSession.endTime?.let((end) => '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}') ?? 'Đang diễn ra'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  breakSession.durationString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getBreakIcon(String type) {
    switch (type) {
             case 'lunch':
         return TablerIcons.tools_kitchen_2;
       case 'coffee':
         return TablerIcons.coffee;
       case 'rest':
         return TablerIcons.armchair_2;
       default:
         return TablerIcons.clock_pause;
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    final weekdays = [
      '', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'
    ];
    return '${weekdays[now.weekday]}, ${now.day}/${now.month}/${now.year}';
  }

  String _getLunchBreakTime() {
    final lunchBreak = timeTracking.breakSessions
        .where((session) => session.type == 'lunch')
        .firstOrNull;
    
    if (lunchBreak != null) {
      return '${lunchBreak.startTime.hour.toString().padLeft(2, '0')}:${lunchBreak.startTime.minute.toString().padLeft(2, '0')}';
    }
    
    return '12:00';
  }

  bool _hasLunchBreak() {
    return timeTracking.breakSessions
        .any((session) => session.type == 'lunch');
  }
}

// Extension helper
extension DateTimeNullableExtension on DateTime? {
  R? let<R>(R Function(DateTime) transform) {
    final self = this;
    return self != null ? transform(self) : null;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
} 