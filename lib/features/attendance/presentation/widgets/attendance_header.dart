import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../themes/colors.dart';
import '../../data/models/attendance_session.dart';
import '../../../../shared/shared_exports.dart';

/// Widget header section có thể scroll được cho trang chấm công
class AttendanceHeader extends StatelessWidget {
  final VoidCallback? onHistoryTap;
  final AttendanceSession session;

  const AttendanceHeader({
    super.key,
    this.onHistoryTap,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

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
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 
              MediaQuery.of(context).padding.top + 16, // Add status bar height
              16, 
              20
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title, status chip and history button
                Row(
                  children: [
                    // Title
                    Text(
                      'Chấm công',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Status chip
                    _buildStatusChip(theme),
                    
                    const Spacer(),
                    
                    // History button
                    IconButton(
                      onPressed: onHistoryTap,
                      icon: const Icon(
                        TablerIcons.history,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      tooltip: 'Lịch sử chấm công',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Date info
                Text(
                  _formatDate(now),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // Real-time clock
                StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    final time = snapshot.data ?? DateTime.now();
                    return Text(
                      _formatTime(time),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color chipColor;
    String statusText;
    IconData statusIcon;

    switch (session.status) {
      case SessionStatus.active:
        chipColor = Colors.green;
        statusText = 'Đang làm việc';
        statusIcon = TablerIcons.clock;
        break;
      case SessionStatus.completed:
        chipColor = Colors.amber;
        statusText = 'Hoàn thành';
        statusIcon = TablerIcons.check;
        break;
      case SessionStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Chưa bắt đầu';
        statusIcon = TablerIcons.clock_pause;
        break;
      default:
        chipColor = Colors.red;
        statusText = 'Không hợp lệ';
        statusIcon = TablerIcons.alert_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      '', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];
    return '${weekdays[date.weekday]}, ${date.day} tháng ${date.month}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 