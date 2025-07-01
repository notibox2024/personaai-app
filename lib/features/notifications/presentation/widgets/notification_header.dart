import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../themes/colors.dart';
import '../../../../shared/shared_exports.dart';

/// Enhanced notification header với search và bulk actions
class NotificationHeader extends StatefulWidget {
  final VoidCallback? onFilterTap;
  final VoidCallback? onMarkAllReadTap;
  final Function(String)? onSearchChanged;
  final VoidCallback? onBulkDeleteTap;
  final int unreadCount;
  final int totalCount;
  final bool isSearchMode;
  final String searchQuery;

  const NotificationHeader({
    super.key,
    this.onFilterTap,
    this.onMarkAllReadTap,
    this.onSearchChanged,
    this.onBulkDeleteTap,
    this.unreadCount = 0,
    this.totalCount = 0,
    this.isSearchMode = false,
    this.searchQuery = '',
  });

  @override
  State<NotificationHeader> createState() => _NotificationHeaderState();
}

class _NotificationHeaderState extends State<NotificationHeader> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _searchAnimation;
  late TextEditingController _searchController;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _searchController = TextEditingController(text: widget.searchQuery);
    _isSearchExpanded = widget.isSearchMode;
    
    if (_isSearchExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    // Stop and dispose animation safely
    try {
      _animationController.stop();
      _animationController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
    
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.headerColor,
      ),
      child: Stack(
        children: [
          // Background icon
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
          
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 
              MediaQuery.of(context).padding.top + 16,
              16, 
              20
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(
                      'Thông báo',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    if (widget.unreadCount > 0)
                      _buildUnreadBadge(theme),
                    
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search button
                        IconButton(
                          onPressed: _toggleSearch,
                          icon: Icon(
                            _isSearchExpanded ? TablerIcons.x : TablerIcons.search,
                            color: Colors.white,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _isSearchExpanded 
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(44, 44),
                          ),
                          tooltip: _isSearchExpanded ? 'Đóng tìm kiếm' : 'Tìm kiếm',
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Mark all read button
                        if (widget.unreadCount > 0)
                          IconButton(
                            onPressed: widget.onMarkAllReadTap,
                            icon: const Icon(
                              TablerIcons.checks,
                              color: Colors.white,
                              size: 22,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(44, 44),
                            ),
                            tooltip: 'Đánh dấu tất cả đã đọc',
                          ),
                        
                        const SizedBox(width: 8),
                        
                        // Filter button
                        IconButton(
                          onPressed: widget.onFilterTap,
                          icon: const Icon(
                            TablerIcons.filter,
                            color: Colors.white,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(44, 44),
                          ),
                          tooltip: 'Lọc thông báo',
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search bar with enhanced animation
                AnimatedBuilder(
                  animation: _searchAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: SizeTransition(
                        sizeFactor: _searchAnimation,
                        child: FadeTransition(
                          opacity: _searchAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeOutBack,
                            )),
                            child: _buildSearchBar(theme),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (_isSearchExpanded) const SizedBox(height: 16),

                // Date and subtitle
                Text(
                  _formatDate(now),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _getSubtitleText(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        // Glass morphism effect
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.onSearchChanged,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm thông báo...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              TablerIcons.search,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged?.call('');
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TablerIcons.x,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 16,
                      ),
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          // Remove default TextField background
          filled: false,
        ),
        // Auto focus when expanded
        autofocus: _isSearchExpanded,
      ),
    );
  }

  Widget _buildUnreadBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TablerIcons.bell,
            size: 14,
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.unreadCount} mới',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });

    if (_isSearchExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      _searchController.clear();
      widget.onSearchChanged?.call('');
      FocusScope.of(context).unfocus();
    }
  }

  String _getSubtitleText() {
    if (_isSearchExpanded) {
      if (_searchController.text.isEmpty) {
        return 'Nhập từ khóa để tìm kiếm trong ${widget.totalCount} thông báo';
      } else {
        return 'Tìm thấy ${widget.totalCount} kết quả';
      }
    } else {
      return widget.unreadCount > 0 
          ? 'Bạn có ${widget.unreadCount} thông báo chưa đọc'
          : 'Tất cả thông báo đã được đọc';
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      '', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];
    return '${weekdays[date.weekday]}, ${date.day} tháng ${date.month}, ${date.year}';
  }
} 