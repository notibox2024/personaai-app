import 'notification_item.dart';

/// Simplified notification filter model
class NotificationFilter {
  final Set<NotificationType> types;
  final Set<NotificationStatus> statuses;
  final NotificationPriority? priority;
  final DateFilter? dateFilter;
  final bool showOnlyUnread;
  final bool showOnlyActionable;
  
  const NotificationFilter({
    this.types = const {},
    this.statuses = const {},
    this.priority,
    this.dateFilter,
    this.showOnlyUnread = false,
    this.showOnlyActionable = false,
  });
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return types.isNotEmpty ||
           statuses.isNotEmpty ||
           priority != null ||
           dateFilter != null ||
           showOnlyUnread ||
           showOnlyActionable;
  }
  
  /// Get human-readable filter description
  String get description {
    final parts = <String>[];
    
    if (types.isNotEmpty) {
      final typeNames = types.map((type) => _getTypeDisplayName(type)).join(', ');
      parts.add('Loại: $typeNames');
    }
    
    if (statuses.isNotEmpty) {
      final statusNames = statuses.map((status) => _getStatusDisplayName(status)).join(', ');
      parts.add('Trạng thái: $statusNames');
    }
    
    if (priority != null) {
      parts.add('Ưu tiên: ${_getPriorityDisplayName(priority!)}');
    }
    
    if (dateFilter != null) {
      parts.add('Thời gian: ${_getDateFilterDisplayName(dateFilter!)}');
    }
    
    if (showOnlyUnread) {
      parts.add('Chỉ chưa đọc');
    }
    
    if (showOnlyActionable) {
      parts.add('Cần xử lý');
    }
    
    return parts.isEmpty ? 'Tất cả thông báo' : parts.join(' • ');
  }
  
  /// Create copy with modified values
  NotificationFilter copyWith({
    Set<NotificationType>? types,
    Set<NotificationStatus>? statuses,
    NotificationPriority? priority,
    DateFilter? dateFilter,
    bool? showOnlyUnread,
    bool? showOnlyActionable,
  }) {
    return NotificationFilter(
      types: types ?? this.types,
      statuses: statuses ?? this.statuses,
      priority: priority ?? this.priority,
      dateFilter: dateFilter ?? this.dateFilter,
      showOnlyUnread: showOnlyUnread ?? this.showOnlyUnread,
      showOnlyActionable: showOnlyActionable ?? this.showOnlyActionable,
    );
  }
  
  /// Clear all filters
  NotificationFilter clear() {
    return const NotificationFilter();
  }
  
  /// Check if notification matches this filter
  bool matches(NotificationItem notification) {
    // Type filter
    if (types.isNotEmpty && !types.contains(notification.type)) {
      return false;
    }
    
    // Status filter
    if (statuses.isNotEmpty && !statuses.contains(notification.status)) {
      return false;
    }
    
    // Priority filter
    if (priority != null && notification.priority != priority) {
      return false;
    }
    
    // Date filter
    if (dateFilter != null) {
      final dateRange = _getDateRange(dateFilter!);
      final notificationTime = notification.createdAt.millisecondsSinceEpoch;
      
      if (notificationTime < dateRange['start']! || notificationTime > dateRange['end']!) {
        return false;
      }
    }
    
    // Show only unread filter
    if (showOnlyUnread && notification.status != NotificationStatus.unread) {
      return false;
    }
    
    // Show only actionable filter
    if (showOnlyActionable && !notification.isActionable) {
      return false;
    }
    
    return true;
  }
  
  /// Get filter statistics for a list of notifications
  FilterStatistics getStatistics(List<NotificationItem> notifications) {
    final filtered = notifications.where(matches).toList();
    
    return FilterStatistics(
      totalCount: notifications.length,
      filteredCount: filtered.length,
      unreadCount: filtered.where((n) => n.status == NotificationStatus.unread).length,
      actionableCount: filtered.where((n) => n.isActionable).length,
      typeBreakdown: _getTypeBreakdown(filtered),
      priorityBreakdown: _getPriorityBreakdown(filtered),
    );
  }
  
  /// Toggle specific type in filter
  NotificationFilter toggleType(NotificationType type) {
    final newTypes = Set<NotificationType>.from(types);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    return copyWith(types: newTypes);
  }
  
  /// Toggle specific status in filter
  NotificationFilter toggleStatus(NotificationStatus status) {
    final newStatuses = Set<NotificationStatus>.from(statuses);
    if (newStatuses.contains(status)) {
      newStatuses.remove(status);
    } else {
      newStatuses.add(status);
    }
    return copyWith(statuses: newStatuses);
  }
  
  /// Set priority filter (null to clear)
  NotificationFilter setPriority(NotificationPriority? newPriority) {
    return copyWith(priority: newPriority);
  }
  
  /// Set date filter (null to clear)
  NotificationFilter setDateFilter(DateFilter? newDateFilter) {
    return copyWith(dateFilter: newDateFilter);
  }
  
  /// Toggle unread only filter
  NotificationFilter toggleUnreadOnly() {
    return copyWith(showOnlyUnread: !showOnlyUnread);
  }
  
  /// Toggle actionable only filter
  NotificationFilter toggleActionableOnly() {
    return copyWith(showOnlyActionable: !showOnlyActionable);
  }
  
  // Helper methods for display names
  String _getTypeDisplayName(NotificationType type) {
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
  
  String _getStatusDisplayName(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.unread:
        return 'Chưa đọc';
      case NotificationStatus.read:
        return 'Đã đọc';
      case NotificationStatus.archived:
        return 'Lưu trữ';
    }
  }
  
  String _getPriorityDisplayName(NotificationPriority priority) {
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
  
  String _getDateFilterDisplayName(DateFilter dateFilter) {
    switch (dateFilter) {
      case DateFilter.today:
        return 'Hôm nay';
      case DateFilter.yesterday:
        return 'Hôm qua';
      case DateFilter.thisWeek:
        return 'Tuần này';
    }
  }
  
  /// Get date range for filtering
  Map<String, int> _getDateRange(DateFilter dateFilter) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    
    switch (dateFilter) {
      case DateFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case DateFilter.thisWeek:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    
    return {
      'start': startDate.millisecondsSinceEpoch,
      'end': endDate.millisecondsSinceEpoch,
    };
  }
  
  /// Get type breakdown for statistics
  Map<NotificationType, int> _getTypeBreakdown(List<NotificationItem> notifications) {
    final breakdown = <NotificationType, int>{};
    for (final notification in notifications) {
      breakdown[notification.type] = (breakdown[notification.type] ?? 0) + 1;
    }
    return breakdown;
  }
  
  /// Get priority breakdown for statistics
  Map<NotificationPriority, int> _getPriorityBreakdown(List<NotificationItem> notifications) {
    final breakdown = <NotificationPriority, int>{};
    for (final notification in notifications) {
      breakdown[notification.priority] = (breakdown[notification.priority] ?? 0) + 1;
    }
    return breakdown;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationFilter &&
        other.types == types &&
        other.statuses == statuses &&
        other.priority == priority &&
        other.dateFilter == dateFilter &&
        other.showOnlyUnread == showOnlyUnread &&
        other.showOnlyActionable == showOnlyActionable;
  }
  
  @override
  int get hashCode {
    return types.hashCode ^
        statuses.hashCode ^
        priority.hashCode ^
        dateFilter.hashCode ^
        showOnlyUnread.hashCode ^
        showOnlyActionable.hashCode;
  }
  
  @override
  String toString() {
    return 'NotificationFilter('
        'types: $types, '
        'statuses: $statuses, '
        'priority: $priority, '
        'dateFilter: $dateFilter, '
        'showOnlyUnread: $showOnlyUnread, '
        'showOnlyActionable: $showOnlyActionable'
        ')';
  }
}

/// Date filter options
enum DateFilter {
  today,
  yesterday,
  thisWeek,
}

/// Filter statistics for analytics and UI display
class FilterStatistics {
  final int totalCount;
  final int filteredCount;
  final int unreadCount;
  final int actionableCount;
  final Map<NotificationType, int> typeBreakdown;
  final Map<NotificationPriority, int> priorityBreakdown;
  
  const FilterStatistics({
    required this.totalCount,
    required this.filteredCount,
    required this.unreadCount,
    required this.actionableCount,
    required this.typeBreakdown,
    required this.priorityBreakdown,
  });
  
  /// Calculate filter efficiency (how much it reduces the dataset)
  double get filterEfficiency {
    if (totalCount == 0) return 0.0;
    return (totalCount - filteredCount) / totalCount;
  }
  
  /// Get most common notification type
  NotificationType? get mostCommonType {
    if (typeBreakdown.isEmpty) return null;
    
    var maxCount = 0;
    NotificationType? mostCommon;
    
    for (final entry in typeBreakdown.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }
    
    return mostCommon;
  }
  
  /// Get most common notification priority
  NotificationPriority? get mostCommonPriority {
    if (priorityBreakdown.isEmpty) return null;
    
    var maxCount = 0;
    NotificationPriority? mostCommon;
    
    for (final entry in priorityBreakdown.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }
    
    return mostCommon;
  }
  
  @override
  String toString() {
    return 'FilterStatistics('
        'total: $totalCount, '
        'filtered: $filteredCount, '
        'unread: $unreadCount, '
        'actionable: $actionableCount'
        ')';
  }
} 