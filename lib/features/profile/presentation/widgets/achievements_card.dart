import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/models/user_profile.dart';

/// Widget card hiển thị thành tựu của nhân viên
class AchievementsCard extends StatelessWidget {
  final List<Achievement> achievements;
  final VoidCallback? onViewAllTap;

  const AchievementsCard({
    super.key,
    required this.achievements,
    this.onViewAllTap,
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
                TablerIcons.trophy,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thành tựu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (achievements.length > 2)
                TextButton(
                  onPressed: onViewAllTap,
                  child: Text(
                    'Xem tất cả',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (achievements.isEmpty)
            _buildEmptyState(theme)
          else
            _buildAchievementsList(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            TablerIcons.trophy_off,
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có thành tựu',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tiếp tục cố gắng để đạt được thành tựu đầu tiên!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(ThemeData theme) {
    final displayAchievements = achievements.take(2).toList();
    
    return Column(
      children: [
        ...displayAchievements.asMap().entries.map((entry) {
          final index = entry.key;
          final achievement = entry.value;
          
          return Column(
            children: [
              if (index > 0) const SizedBox(height: 12),
              _buildAchievementItem(achievement, theme),
            ],
          );
        }),
        
        if (achievements.length > 2) ...[
          const SizedBox(height: 12),
          _buildMoreAchievements(theme),
        ],
      ],
    );
  }

  Widget _buildAchievementItem(Achievement achievement, ThemeData theme) {
    final typeColor = _getAchievementTypeColor(achievement.type);
    final typeIcon = _getAchievementTypeIcon(achievement.type);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      TablerIcons.calendar,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(achievement.dateEarned),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              achievement.type.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreAchievements(ThemeData theme) {
    final remainingCount = achievements.length - 2;
    
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
      child: Row(
        children: [
          Icon(
            TablerIcons.dots,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Và $remainingCount thành tựu khác',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAchievementTypeColor(AchievementType type) {
    switch (type) {
      case AchievementType.performance:
        return const Color(0xFFFF9800); // Orange
      case AchievementType.attendance:
        return const Color(0xFF4CAF50); // Green
      case AchievementType.training:
        return const Color(0xFF2196F3); // Blue
      case AchievementType.special:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  IconData _getAchievementTypeIcon(AchievementType type) {
    switch (type) {
      case AchievementType.performance:
        return TablerIcons.trending_up;
      case AchievementType.attendance:
        return TablerIcons.clock_check;
      case AchievementType.training:
        return TablerIcons.school;
      case AchievementType.special:
        return TablerIcons.star_filled;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 