import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../../shared/widgets/custom_card.dart';

/// Widget hàng ngang các hành động nhanh
class QuickActionsRow extends StatelessWidget {
  final VoidCallback onBreakTap;
  final VoidCallback onOvertimeTap;
  final VoidCallback onLeaveTap;
  final VoidCallback onReportTap;

  const QuickActionsRow({
    super.key,
    required this.onBreakTap,
    required this.onOvertimeTap,
    required this.onLeaveTap,
    required this.onReportTap,
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
                                 TablerIcons.bolt,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hành động nhanh',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Actions Grid
          Row(
            children: [
              // Break Request
              Expanded(
                child: _buildActionButton(
                  theme: theme,
                  icon: TablerIcons.coffee,
                  label: 'Nghỉ giải lao',
                  subtitle: 'Xin nghỉ',
                  color: theme.colorScheme.secondary,
                  onTap: onBreakTap,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Overtime Request
              Expanded(
                child: _buildActionButton(
                  theme: theme,
                  icon: TablerIcons.clock_plus,
                  label: 'Tăng ca',
                  subtitle: 'Đăng ký',
                  color: Colors.orange,
                  onTap: onOvertimeTap,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Leave Request
              Expanded(
                child: _buildActionButton(
                  theme: theme,
                  icon: TablerIcons.calendar_off,
                  label: 'Nghỉ phép',
                  subtitle: 'Xin nghỉ',
                  color: Colors.green,
                  onTap: onLeaveTap,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Incident Report
              Expanded(
                child: _buildActionButton(
                  theme: theme,
                  icon: TablerIcons.alert_triangle,
                  label: 'Báo cáo',
                  subtitle: 'Sự cố',
                  color: Colors.red,
                  onTap: onReportTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Label
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 2),
              
              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 