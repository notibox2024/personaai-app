import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:logger/logger.dart';

import '../../data/services/fcm_token_service.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../themes/colors.dart';

/// Debug widget để test FCM token functionality trong development
class FcmTokenDebugWidget extends StatefulWidget {
  const FcmTokenDebugWidget({super.key});

  @override
  State<FcmTokenDebugWidget> createState() => _FcmTokenDebugWidgetState();
}

class _FcmTokenDebugWidgetState extends State<FcmTokenDebugWidget> {
  final FcmTokenService _fcmTokenService = FcmTokenService();
  final FirebaseService _firebaseService = FirebaseService();
  final Logger _logger = Logger();
  
  String? _currentToken;
  String _lastResult = 'Chưa có kết quả';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentToken();
  }

  Future<void> _loadCurrentToken() async {
    try {
      final token = await _firebaseService.getToken();
      setState(() {
        _currentToken = token;
      });
    } catch (e) {
      _logger.e('Error loading FCM token: $e');
    }
  }

  Future<void> _updateFcmToken() async {
    setState(() {
      _isLoading = true;
      _lastResult = 'Đang cập nhật...';
    });

    try {
      final result = await _fcmTokenService.updateFcmToken();
      
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _lastResult = '✅ Thành công: ${result.message}\n'
              'Token ID: ${result.data?.tokenId}\n'
              'Employee ID: ${result.data?.employeeId}\n'
              'Device ID: ${result.data?.deviceId}\n'
              'Platform: ${result.data?.platform}';
        } else {
          _lastResult = '❌ Thất bại: ${result.message}';
        }
      });
      
      // Reload current token
      await _loadCurrentToken();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = '❌ Lỗi: $e';
      });
    }
  }

  Future<void> _checkServiceAvailability() async {
    setState(() {
      _isLoading = true;
      _lastResult = 'Đang kiểm tra...';
    });

    try {
      final isAvailable = await _fcmTokenService.checkServiceAvailability();
      
      setState(() {
        _isLoading = false;
        _lastResult = isAvailable 
            ? '✅ Service khả dụng'
            : '❌ Service không khả dụng';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = '❌ Lỗi kiểm tra: $e';
      });
    }
  }

  Future<void> _forceRefreshToken() async {
    setState(() {
      _isLoading = true;
      _lastResult = 'Đang force refresh...';
    });

    try {
      final result = await _fcmTokenService.forceRefreshToken();
      
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _lastResult = '✅ Force refresh thành công: ${result.message}';
        } else {
          _lastResult = '❌ Force refresh thất bại: ${result.message}';
        }
      });
      
      // Reload current token
      await _loadCurrentToken();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = '❌ Lỗi force refresh: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với brand styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: colorScheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.bell_ringing,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'FCM Token Debug',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  TablerIcons.code,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Token Section
          Text(
            'Current FCM Token:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _currentToken ?? 'Chưa có token',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Buttons (2 columns layout)
          Column(
            children: [
              // First row: Update Token + Check Service
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateFcmToken,
                      icon: _isLoading 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(TablerIcons.upload, size: 18),
                      label: const Text('Update Token'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _checkServiceAvailability,
                      icon: const Icon(TablerIcons.shield_check, size: 18),
                      label: const Text('Check Service'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row: Force Refresh + Reload Token
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _forceRefreshToken,
                      icon: const Icon(TablerIcons.refresh, size: 18),
                      label: const Text('Force Refresh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loadCurrentToken,
                      icon: const Icon(TablerIcons.reload, size: 18),
                      label: const Text('Reload Token'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Result Section
          Text(
            'Kết quả:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildResultContainer(context),
          const SizedBox(height: 12),
          
          // Info Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.info_circle,
                  size: 16,
                  color: colorScheme.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Widget này chỉ hiển thị trong development mode để test FCM token integration.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.info,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build result container với semantic colors
  Widget _buildResultContainer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine result type và colors
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData iconData;
    
    if (_lastResult.contains('✅') || _lastResult.contains('Thành công')) {
      backgroundColor = colorScheme.success.withValues(alpha: 0.08);
      borderColor = colorScheme.success.withValues(alpha: 0.2);
      textColor = colorScheme.success;
      iconData = TablerIcons.circle_check;
    } else if (_lastResult.contains('❌') || _lastResult.contains('Thất bại') || _lastResult.contains('Lỗi')) {
      backgroundColor = colorScheme.error.withValues(alpha: 0.08);
      borderColor = colorScheme.error.withValues(alpha: 0.2);
      textColor = colorScheme.error;
      iconData = TablerIcons.alert_circle;
    } else if (_lastResult.contains('Đang')) {
      backgroundColor = colorScheme.warning.withValues(alpha: 0.08);
      borderColor = colorScheme.warning.withValues(alpha: 0.2);
      textColor = colorScheme.warning;
      iconData = TablerIcons.clock;
    } else {
      backgroundColor = colorScheme.surfaceContainer;
      borderColor = colorScheme.outline.withValues(alpha: 0.2);
      textColor = colorScheme.onSurfaceVariant;
      iconData = TablerIcons.message;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastResult,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 