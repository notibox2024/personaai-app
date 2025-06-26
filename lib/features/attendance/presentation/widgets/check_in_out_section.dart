import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/attendance_session.dart';
import '../../data/models/location_data.dart';
import '../../../../shared/shared_exports.dart';

/// Widget section chính cho chấm công vào/ra
class CheckInOutSection extends StatefulWidget {
  final AttendanceSession session;
  final LocationData locationData;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const CheckInOutSection({
    super.key,
    required this.session,
    required this.locationData,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  State<CheckInOutSection> createState() => _CheckInOutSectionState();
}

class _CheckInOutSectionState extends State<CheckInOutSection>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Start pulse animation only if session is active
    if (widget.session.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CheckInOutSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation based on session status
    if (widget.session.isActive && !oldWidget.session.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.session.isActive && oldWidget.session.isActive) {
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
              child: Column(
          children: [
            // Location Status
            _buildLocationStatus(),
            
            const SizedBox(height: 24),
          
          // Main Check-in/out Button
          _buildMainButton(),
          
          const SizedBox(height: 24),
          
          // Session Info
          if (widget.session.checkInTime != null)
            _buildSessionInfo(),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    final theme = Theme.of(context);
    final status = widget.locationData.validationStatus;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case LocationValidationStatus.valid:
        statusColor = Colors.green;
        statusIcon = TablerIcons.circle_check;
        break;
      case LocationValidationStatus.warning:
        statusColor = Colors.orange;
        statusIcon = TablerIcons.alert_triangle;
        break;
      case LocationValidationStatus.invalid:
        statusColor = Colors.red;
        statusIcon = TablerIcons.circle_x;
        break;
      case LocationValidationStatus.checking:
        statusColor = theme.colorScheme.primary;
        statusIcon = TablerIcons.loader;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.locationData.displayMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final theme = Theme.of(context);
    final isCheckIn = widget.session.checkInTime == null;
    final canPerformAction = widget.locationData.isValid && !widget.isLoading;
    
    Color buttonColor;
    Color textColor;
    String buttonText;
    IconData buttonIcon;
    
    if (isCheckIn) {
      buttonColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      buttonText = 'Chấm công vào';
      buttonIcon = TablerIcons.clock_hour_4;
    } else if (widget.session.status == SessionStatus.completed) {
      buttonColor = theme.colorScheme.tertiary;
      textColor = theme.colorScheme.onTertiary;
      buttonText = 'Đã hoàn thành';
      buttonIcon = TablerIcons.check;
    } else {
      buttonColor = theme.colorScheme.secondary;
      textColor = theme.colorScheme.onSecondary;
      buttonText = 'Chấm công ra';
      buttonIcon = TablerIcons.clock_hour_9;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.session.isActive ? _pulseAnimation.value : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple Effect
              if (widget.isLoading)
                AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 160 * (1 + _rippleAnimation.value * 0.3),
                      height: 160 * (1 + _rippleAnimation.value * 0.3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: buttonColor.withValues(alpha: 1 - _rippleAnimation.value),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              
              // Main Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canPerformAction && widget.session.status != SessionStatus.completed
                      ? (isCheckIn ? widget.onCheckIn : widget.onCheckOut)
                      : null,
                  borderRadius: BorderRadius.circular(80),
                  splashColor: textColor.withValues(alpha: 0.2),
                  highlightColor: textColor.withValues(alpha: 0.1),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: canPerformAction || widget.session.status == SessionStatus.completed
                          ? buttonColor
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: canPerformAction || widget.session.status == SessionStatus.completed
                          ? [
                              BoxShadow(
                                color: buttonColor.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: textColor,
                              strokeWidth: 3,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            buttonIcon,
                            size: 32,
                            color: canPerformAction || widget.session.status == SessionStatus.completed
                                ? textColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            buttonText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: canPerformAction || widget.session.status == SessionStatus.completed
                                  ? textColor
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionInfo() {
    final theme = Theme.of(context);
    final session = widget.session;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Check-in info
          Expanded(
            child: Column(
              children: [
                Icon(
                  TablerIcons.clock_hour_4,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  'Vào làm',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  session.checkInTimeString,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          
          // Check-out info
          Expanded(
            child: Column(
              children: [
                Icon(
                  TablerIcons.clock_hour_9,
                  color: session.checkOutTime != null 
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ra về',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  session.checkOutTimeString,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: session.checkOutTime != null 
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


} 