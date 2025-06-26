import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../themes/colors.dart';
import '../../../../shared/shared_exports.dart';

/// Header widget cho trang đào tạo
class TrainingHeader extends StatelessWidget {
  final VoidCallback? onHistoryTap;
  final String employeeName;
  final int completedCourses;
  final int inProgressCourses;
  final int certificates;

  const TrainingHeader({
    super.key,
    this.onHistoryTap,
    required this.employeeName,
    required this.completedCourses,
    required this.inProgressCourses,
    required this.certificates,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title + History Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đào tạo',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (onHistoryTap != null)
                        IconButton(
                          onPressed: onHistoryTap,
                          icon: Icon(
                            TablerIcons.history,
                            color: theme.colorScheme.onPrimary,
                          ),
                          tooltip: 'Lịch sử học tập',
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Welcome Text
                  Text(
                    'Xin chào, $employeeName!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Tiếp tục hành trình học tập của bạn',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: TablerIcons.book_2,
                          label: 'Đang học',
                          value: inProgressCourses.toString(),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: TablerIcons.check,
                          label: 'Hoàn thành',
                          value: completedCourses.toString(),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: TablerIcons.certificate,
                          label: 'Chứng chỉ',
                          value: certificates.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 