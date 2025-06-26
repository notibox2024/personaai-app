import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../data/models/attendance_info.dart';
import '../../../../../shared/widgets/custom_card.dart';
import '../../../../../shared/widgets/status_chip.dart';

/// Widget card hiển thị thông tin chấm công hôm nay
class AttendanceCard extends StatelessWidget {
  final AttendanceInfo attendanceInfo;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.attendanceInfo,
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
                TablerIcons.clock,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chấm Công Hôm Nay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusChip(
                text: attendanceInfo.status.displayName,
                color: attendanceInfo.status.color,
                icon: attendanceInfo.status == AttendanceStatus.working
                    ? TablerIcons.point_filled
                    : null,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Time information
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giờ vào',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          attendanceInfo.checkInTimeString,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: attendanceInfo.checkInTime != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (attendanceInfo.isLate) ...[
                          const SizedBox(width: 4),
                          Icon(
                            TablerIcons.alert_circle,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giờ ra',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          attendanceInfo.checkOutTimeString,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: attendanceInfo.checkOutTime != null
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (attendanceInfo.isEarlyLeave) ...[
                          const SizedBox(width: 4),
                          Icon(
                            TablerIcons.alert_circle,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Work time and location
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng giờ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attendanceInfo.workedTimeString,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (attendanceInfo.location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  TablerIcons.map_pin,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attendanceInfo.location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 