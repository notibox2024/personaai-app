import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../themes/colors.dart';
import '../../data/models/user_profile.dart';
import '../../../../shared/shared_exports.dart';

/// Widget header section cho trang cá nhân
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onEditTap;
  final VoidCallback? onSettingsTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onEditTap,
    this.onSettingsTap,
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 
              MediaQuery.of(context).padding.top + 16, // Add status bar height
              16, 
              24
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and actions
                Row(
                  children: [
                    // Title
                    Text(
                      'Cá nhân',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Status chip
                    _buildStatusChip(theme),
                    
                    const Spacer(),
                    
                    // Settings button
                    IconButton(
                      onPressed: onSettingsTap,
                      icon: const Icon(
                        TablerIcons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      tooltip: 'Cài đặt',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Profile info row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: profile.avatar != null 
                            ? NetworkImage(profile.avatar!) 
                            : null,
                        child: profile.avatar == null
                            ? Icon(
                                TablerIcons.user,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 32,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Name and position
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.position,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.department,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Edit button
                    IconButton(
                      onPressed: onEditTap,
                      icon: const Icon(
                        TablerIcons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        minimumSize: const Size(36, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      tooltip: 'Chỉnh sửa',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Additional info row
                Row(
                  children: [
                    _buildInfoItem(
                      icon: TablerIcons.calendar,
                      label: '${profile.yearsOfService} năm kinh nghiệm',
                      theme: theme,
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      icon: TablerIcons.mail,
                      label: profile.email,
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color chipColor;
    IconData statusIcon;

    switch (profile.status) {
      case UserStatus.active:
        chipColor = Colors.green;
        statusIcon = TablerIcons.check;
        break;
      case UserStatus.onLeave:
        chipColor = Colors.orange;
        statusIcon = TablerIcons.clock_pause;
        break;
      case UserStatus.probation:
        chipColor = Colors.blue;
        statusIcon = TablerIcons.hourglass;
        break;
      case UserStatus.inactive:
        chipColor = Colors.red;
        statusIcon = TablerIcons.x;
        break;
    }

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
            statusIcon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            profile.status.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 