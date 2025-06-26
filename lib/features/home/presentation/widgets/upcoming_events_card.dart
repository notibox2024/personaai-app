import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../data/models/upcoming_event.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Widget card hiển thị sự kiện sắp tới
class UpcomingEventsCard extends StatelessWidget {
  final List<UpcomingEvent> events;
  final VoidCallback? onSeeAllTap;
  final Function(UpcomingEvent)? onEventTap;

  const UpcomingEventsCard({
    super.key,
    required this.events,
    this.onSeeAllTap,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEvents = events.take(4).toList();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.calendar_event,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sự Kiện Sắp Tới',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          if (displayEvents.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    TablerIcons.calendar_off,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không có sự kiện nào',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 16),
            
            // Event items
            ...displayEvents.map((event) => 
              _EventItem(
                event: event,
                onTap: () => onEventTap?.call(event),
              ),
            ),
            
            if (onSeeAllTap != null && events.length > 4) ...[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              InkWell(
                onTap: onSeeAllTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        TablerIcons.calendar,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Xem lịch đầy đủ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Widget item sự kiện
class _EventItem extends StatelessWidget {
  final UpcomingEvent event;
  final VoidCallback? onTap;

  const _EventItem({
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: event.isToday 
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: event.isToday 
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and emoji
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: event.type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          event.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.dateString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: event.isToday 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: event.isToday 
                            ? FontWeight.w600 
                            : FontWeight.w400,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.isOptional)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tùy chọn',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          event.type.icon,
                          size: 14,
                          color: event.type.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.type.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: event.type.color,
                            fontSize: 12,
                          ),
                        ),
                        if (event.timeString.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            TablerIcons.clock,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.timeString,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    if (event.location != null && event.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            TablerIcons.map_pin,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 