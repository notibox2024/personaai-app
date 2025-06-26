import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../../shared/widgets/custom_card.dart';
import '../../../../themes/colors.dart';
import '../../data/models/attendance_session.dart';

/// Trang lịch sử chấm công
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<AttendanceSession> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  void _loadHistoryData() {
    setState(() => _isLoading = true);
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _sessions = _generateMockHistory();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set status bar style cho trang này
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surfaceContainerLowest,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarDividerColor: theme.colorScheme.outline,
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.headerColor,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40), // Space for back button
                        Text(
                          'Lịch sử chấm công',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Xem chi tiết các phiên làm việc',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                TablerIcons.arrow_left,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showFilterOptions,
                icon: const Icon(
                  TablerIcons.filter,
                  color: Colors.white,
                ),
                tooltip: 'Lọc dữ liệu',
              ),
            ],
          ),

          // Month/Year selector
          SliverToBoxAdapter(
            child: _buildMonthYearSelector(theme),
          ),

          // Summary stats
          SliverToBoxAdapter(
            child: _buildSummaryStats(theme),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Sessions list
          _isLoading
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                )
              : _sessions.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(theme),
                    )
                                        : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final session = _sessions[index];
                              return _buildSessionCard(session, theme);
                            },
                            childCount: _sessions.length,
                          ),
                        ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector(ThemeData theme) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.calendar,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Chọn tháng/năm',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$_selectedMonth/$_selectedYear',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Year selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) {
                final year = DateTime.now().year - 2 + index;
                final isSelected = year == _selectedYear;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildQuickSelectButton(
                    text: year.toString(),
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedYear = year);
                      _loadHistoryData();
                    },
                    theme: theme,
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Month selector - horizontal layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildQuickSelectButton(
                    text: month.toString(),
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedMonth = month);
                      _loadHistoryData();
                    },
                    theme: theme,
                    minWidth: 36,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    double? minWidth,
  }) {
    return Material(
      color: isSelected 
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(
            minWidth: minWidth ?? 48,
            minHeight: 36,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected 
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected 
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(ThemeData theme) {
    final totalDays = _sessions.length;
    final completedDays = _sessions.where((s) => s.status == SessionStatus.completed).length;
    final totalWorkTime = _sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.totalWorkTime,
    );

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê tháng ${_getMonthName(_selectedMonth)} $_selectedYear',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme: theme,
                    icon: TablerIcons.calendar_check,
                    label: 'Tổng ngày',
                    value: totalDays.toString(),
                    color: theme.colorScheme.primary,
                    paddingOverride: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    theme: theme,
                    icon: TablerIcons.check,
                    label: 'Hoàn thành',
                    value: completedDays.toString(),
                    color: Colors.green,
                     paddingOverride: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    theme: theme,
                    icon: TablerIcons.clock,
                    label: 'Tổng giờ',
                    value: '${totalWorkTime.inHours}h',
                    color: theme.colorScheme.secondary,
                    paddingOverride: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    EdgeInsetsGeometry? paddingOverride,
  }) {
    return Container(
      padding: paddingOverride ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(AttendanceSession session, ThemeData theme) {
    return CustomCard(
      onTap: () => _showSessionDetail(session),
      child: Row(
        children: [
          // Date
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  session.checkInTime?.day.toString().padLeft(2, '0') ?? '--',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _getMonthName(session.checkInTime?.month ?? 1, short: true),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Session info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getWeekdayName(session.checkInTime?.weekday ?? 1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(session.status, theme),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      TablerIcons.clock,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${session.checkInTimeString} - ${session.checkOutTimeString}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      TablerIcons.hourglass,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tổng: ${session.workTimeString}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Icon(
            TablerIcons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status, ThemeData theme) {
    Color color;
    IconData icon;
    
    switch (status) {
      case SessionStatus.active:
        color = Colors.green;
        icon = TablerIcons.clock;
        break;
      case SessionStatus.completed:
        color = theme.colorScheme.primary;
        icon = TablerIcons.check;
        break;
      case SessionStatus.pending:
        color = Colors.orange;
        icon = TablerIcons.clock_pause;
        break;
      default:
        color = Colors.red;
        icon = TablerIcons.alert_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            TablerIcons.calendar_x,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Không tìm thấy lịch sử chấm công\ntrong tháng ${_getMonthName(_selectedMonth)} $_selectedYear',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSessionDetail(AttendanceSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _buildSessionDetailContent(session, scrollController),
          );
        },
      ),
    );
  }

  Widget _buildSessionDetailContent(AttendanceSession session, ScrollController scrollController) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      TablerIcons.calendar_event,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chi tiết phiên làm việc',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildStatusBadge(session.status, theme),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Date and time info
                _buildDetailSection(
                  theme: theme,
                  title: 'Thời gian',
                  items: [
                    _buildDetailItem(
                      icon: TablerIcons.calendar,
                      label: 'Ngày',
                      value: session.checkInTime != null
                          ? '${_getWeekdayName(session.checkInTime!.weekday)}, ${session.checkInTime!.day}/${session.checkInTime!.month}/${session.checkInTime!.year}'
                          : 'Chưa xác định',
                    ),
                    _buildDetailItem(
                      icon: TablerIcons.clock,
                      label: 'Giờ vào',
                      value: session.checkInTimeString,
                    ),
                    _buildDetailItem(
                      icon: TablerIcons.clock,
                      label: 'Giờ ra',
                      value: session.checkOutTimeString,
                    ),
                    _buildDetailItem(
                      icon: TablerIcons.hourglass,
                      label: 'Tổng thời gian',
                      value: session.workTimeString,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Location info
                _buildDetailSection(
                  theme: theme,
                  title: 'Vị trí',
                  items: [
                    _buildDetailItem(
                      icon: TablerIcons.map_pin,
                      label: 'Vị trí check-in',
                      value: session.checkInLocation ?? 'Chưa xác định',
                    ),
                    _buildDetailItem(
                      icon: TablerIcons.map_pin,
                      label: 'Vị trí check-out',
                      value: session.checkOutLocation ?? 'Chưa xác định',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Additional info
                _buildDetailSection(
                  theme: theme,
                  title: 'Thông tin khác',
                  items: [
                    _buildDetailItem(
                      icon: TablerIcons.category,
                      label: 'Loại ca',
                      value: session.sessionType.displayName,
                    ),
                    _buildDetailItem(
                      icon: TablerIcons.shield_check,
                      label: 'Xác thực',
                      value: session.isValidated ? 'Đã xác thực' : 'Chưa xác thực',
                    ),
                    if (session.notes?.isNotEmpty == true)
                      _buildDetailItem(
                        icon: TablerIcons.note,
                        label: 'Ghi chú',
                        value: session.notes!,
                      ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection({
    required ThemeData theme,
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.map((item) => item).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    // TODO: Implement filter options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng lọc đang phát triển')),
    );
  }

  String _getMonthName(int month, {bool short = false}) {
    const monthNames = [
      '1', '2', '3', '4', '5', '6',
      '7', '8', '9', '10', '11', '12'
    ];
    const shortNames = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
    ];
    
    if (month < 1 || month > 12) return short ? 'T1' : '1';
    return short ? shortNames[month - 1] : monthNames[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];
    if (weekday < 1 || weekday > 7) return 'Thứ Hai';
    return weekdays[weekday - 1];
  }

  List<AttendanceSession> _generateMockHistory() {
    final sessions = <AttendanceSession>[];
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      
      // Skip weekends and future dates
      if (date.weekday > 5 || date.isAfter(now)) continue;
      
      final checkInTime = DateTime(date.year, date.month, date.day, 8, 15 + (day % 30));
      final checkOutTime = day % 7 != 0 ? DateTime(date.year, date.month, date.day, 17, 30 + (day % 20)) : null;
      
      sessions.add(AttendanceSession(
        sessionId: 'session_${_selectedYear}_${_selectedMonth}_$day',
        employeeId: 'EMP001',
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        sessionType: day % 10 == 0 ? SessionType.overtime : SessionType.normal,
        status: checkOutTime != null ? SessionStatus.completed : SessionStatus.active,
        checkInLocation: 'Văn phòng chính - Tầng 5',
        checkOutLocation: checkOutTime != null ? 'Văn phòng chính - Tầng 5' : null,
        notes: day % 5 == 0 ? 'Làm việc tại dự án KienlongBank Mobile' : null,
        isValidated: true,
      ));
    }
    
    return sessions.reversed.toList(); // Latest first
  }
} 