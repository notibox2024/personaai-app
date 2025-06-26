import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../shared/widgets/quick_action_button.dart';

/// Model cho quick action
class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Widget grid hành động nhanh
class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsGrid({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return QuickActionButton(
                icon: action.icon,
                label: action.label,
                onTap: action.onTap,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Factory method để tạo quick actions mặc định
  static List<QuickAction> getDefaultActions({
    VoidCallback? onCheckInTap,
    VoidCallback? onLeaveRequestTap,
    VoidCallback? onPayrollTap,
    VoidCallback? onChatTap,
  }) {
    return [
      QuickAction(
        id: 'checkin',
        label: 'Công',
        icon: TablerIcons.clock,
        onTap: onCheckInTap ?? () {},
      ),
      QuickAction(
        id: 'leave',
        label: 'Đơn từ',
        icon: TablerIcons.file_text,
        onTap: onLeaveRequestTap ?? () {},
      ),
      QuickAction(
        id: 'payroll',
        label: 'Lương',
        icon: TablerIcons.report_money,
        onTap: onPayrollTap ?? () {},
      ),
      QuickAction(
        id: 'chat',
        label: 'Chat',
        icon: TablerIcons.message_circle,
        onTap: onChatTap ?? () {},
      ),
    ];
  }
} 