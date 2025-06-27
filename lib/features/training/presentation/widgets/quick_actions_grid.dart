import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Widget hiển thị lưới các hành động nhanh
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onContinueLearning;
  final VoidCallback? onExplore;
  final VoidCallback? onCertificates;

  const QuickActionsGrid({
    super.key,
    this.onContinueLearning,
    this.onExplore,
    this.onCertificates,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: TablerIcons.player_play,
              label: 'Tiếp tục học',
              onTap: onContinueLearning ?? () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: TablerIcons.search,
              label: 'Khám phá',
              onTap: onExplore ?? () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: TablerIcons.certificate,
              label: 'Chứng chỉ',
              onTap: onCertificates ?? () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 