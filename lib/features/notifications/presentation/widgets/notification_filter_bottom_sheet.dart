import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../data/models/notification_item.dart';

/// Model cho filter options
class NotificationFilter {
  final Set<NotificationType> types;
  final Set<NotificationStatus> statuses;
  final NotificationPriority? priority;

  const NotificationFilter({
    this.types = const {},
    this.statuses = const {},
    this.priority,
  });

  NotificationFilter copyWith({
    Set<NotificationType>? types,
    Set<NotificationStatus>? statuses,
    NotificationPriority? priority,
  }) {
    return NotificationFilter(
      types: types ?? this.types,
      statuses: statuses ?? this.statuses,
      priority: priority ?? this.priority,
    );
  }

  bool get hasActiveFilters => types.isNotEmpty || statuses.isNotEmpty || priority != null;

  NotificationFilter clear() {
    return const NotificationFilter();
  }
}

/// Bottom sheet để lọc thông báo
class NotificationFilterBottomSheet extends StatefulWidget {
  final NotificationFilter initialFilter;
  final Function(NotificationFilter) onApply;

  const NotificationFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<NotificationFilterBottomSheet> createState() => _NotificationFilterBottomSheetState();
}

class _NotificationFilterBottomSheetState extends State<NotificationFilterBottomSheet> {
  late NotificationFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

         return Container(
       constraints: BoxConstraints(
         maxHeight: MediaQuery.of(context).size.height * 0.75,
       ),
       decoration: BoxDecoration(
         color: theme.colorScheme.surface,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
       ),
       child: SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Lọc thông báo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Xóa bộ lọc'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(TablerIcons.x),
                  ),
                ],
              ),
            ),

            // Filter content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loại thông báo
                    _buildSection(
                      'Loại thông báo',
                      _buildTypeFilters(theme),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Trạng thái
                    _buildSection(
                      'Trạng thái',
                      _buildStatusFilters(theme),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Độ ưu tiên
                    _buildSection(
                      'Độ ưu tiên',
                      _buildPriorityFilters(theme),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
                             child: Row(
                 children: [
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () => Navigator.pop(context),
                       style: OutlinedButton.styleFrom(
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                         minimumSize: const Size(double.infinity, 48),
                       ),
                       child: const Text('Hủy'),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: FilledButton(
                       onPressed: _applyFilters,
                       style: FilledButton.styleFrom(
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                         minimumSize: const Size(double.infinity, 48),
                       ),
                       child: const Text('Áp dụng'),
                     ),
                   ),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildTypeFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NotificationType.values.map((type) {
        final isSelected = _filter.types.contains(type);
        return FilterChip(
          label: Text(_getTypeLabel(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filter = _filter.copyWith(
                  types: {..._filter.types, type},
                );
              } else {
                _filter = _filter.copyWith(
                  types: _filter.types.where((t) => t != type).toSet(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStatusFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NotificationStatus.values.map((status) {
        final isSelected = _filter.statuses.contains(status);
        return FilterChip(
          label: Text(_getStatusLabel(status)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filter = _filter.copyWith(
                  statuses: {..._filter.statuses, status},
                );
              } else {
                _filter = _filter.copyWith(
                  statuses: _filter.statuses.where((s) => s != status).toSet(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPriorityFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Tất cả'),
          selected: _filter.priority == null,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _filter = _filter.copyWith(priority: null);
              });
            }
          },
        ),
        ...NotificationPriority.values.map((priority) {
          final isSelected = _filter.priority == priority;
          return FilterChip(
            label: Text(_getPriorityLabel(priority)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _filter = _filter.copyWith(
                  priority: selected ? priority : null,
                );
              });
            },
          );
        }),
      ],
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.attendance:
        return 'Chấm công';
      case NotificationType.training:
        return 'Đào tạo';
      case NotificationType.leave:
        return 'Nghỉ phép';
      case NotificationType.overtime:
        return 'Tăng ca';
      case NotificationType.general:
        return 'Chung';
      case NotificationType.system:
        return 'Hệ thống';
      case NotificationType.urgent:
        return 'Khẩn cấp';
    }
  }

  String _getStatusLabel(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.unread:
        return 'Chưa đọc';
      case NotificationStatus.read:
        return 'Đã đọc';
      case NotificationStatus.archived:
        return 'Đã lưu trữ';
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Thấp';
      case NotificationPriority.normal:
        return 'Bình thường';
      case NotificationPriority.high:
        return 'Cao';
      case NotificationPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  void _clearFilters() {
    setState(() {
      _filter = _filter.clear();
    });
  }

  void _applyFilters() {
    widget.onApply(_filter);
    Navigator.pop(context);
  }

} 