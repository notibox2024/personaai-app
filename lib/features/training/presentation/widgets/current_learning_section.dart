import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

// Models
import '../../data/models/training_progress.dart';

// Shared widgets
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/status_chip.dart';

/// Widget hiển thị section khóa học đang học
class CurrentLearningSection extends StatelessWidget {
  final List<TrainingProgress> progressList;
  final Function(TrainingProgress)? onContinueCourse;

  const CurrentLearningSection({
    super.key,
    required this.progressList,
    this.onContinueCourse,
  });

  @override
  Widget build(BuildContext context) {
    if (progressList.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: progressList.length,
        itemBuilder: (context, index) {
          final progress = progressList[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 16), // chỉ card từ thứ 2 trở đi mới có margin
            child: _buildProgressCard(context, progress),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, TrainingProgress progress) {
    final theme = Theme.of(context);
    
    return CustomCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Flutter Development',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(
                  text: progress.status.displayName,
                  color: _getStatusColor(progress.status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progressPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.completedLessons}/${progress.totalLessons} bài học • ${progress.progressPercentage.toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  TablerIcons.clock,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.totalStudyTime.inHours}h ${progress.totalStudyTime.inMinutes.remainder(60)}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => onContinueCourse?.call(progress),
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            TablerIcons.book_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có khóa học nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy đăng ký khóa học đầu tiên của bạn',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TrainingStatus status) {
    switch (status) {
      case TrainingStatus.notStarted:
        return Colors.grey;
      case TrainingStatus.inProgress:
        return Colors.blue;
      case TrainingStatus.completed:
        return Colors.green;
      case TrainingStatus.suspended:
        return Colors.orange;
    }
  }
} 