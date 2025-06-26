import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../services/location_service.dart';

/// Dialog yêu cầu quyền truy cập vị trí
class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const LocationPermissionDialog({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          TablerIcons.location,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 32,
        ),
      ),
      title: Text(
        'Quyền truy cập vị trí',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ứng dụng cần quyền truy cập vị trí để:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            context,
            icon: TablerIcons.clock_check,
            title: 'Chấm công chính xác',
            subtitle: 'Xác định vị trí khi chấm công vào/ra',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            context,
            icon: TablerIcons.map_pin,
            title: 'Xác minh địa điểm',
            subtitle: 'Đảm bảo bạn đang ở đúng nơi làm việc',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            context,
            icon: TablerIcons.shield_check,
            title: 'Bảo mật dữ liệu',
            subtitle: 'Vị trí chỉ được sử dụng cho mục đích chấm công',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPermissionDenied?.call();
          },
          child: Text(
            'Từ chối',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _requestPermission(context);
          },
          child: const Text('Cho phép'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    bool granted = await LocationService.requestLocationPermission();
    
    if (granted) {
      onPermissionGranted?.call();
    } else {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPermissionDeniedDialog(),
    );
  }

  /// Hiển thị dialog yêu cầu quyền location
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onPermissionGranted,
    VoidCallback? onPermissionDenied,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onPermissionGranted: onPermissionGranted,
        onPermissionDenied: onPermissionDenied,
      ),
    );
  }
}

/// Dialog hiển thị khi quyền location bị từ chối
class LocationPermissionDeniedDialog extends StatelessWidget {
  const LocationPermissionDeniedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          TablerIcons.location_off,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: 32,
        ),
      ),
      title: Text(
        'Quyền truy cập bị từ chối',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ứng dụng cần quyền truy cập vị trí để thực hiện chấm công. Vui lòng cấp quyền trong cài đặt.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.info_circle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cài đặt > Ứng dụng > PersonaAI > Quyền > Vị trí',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await LocationService.openAppSettings();
          },
          child: const Text('Mở cài đặt'),
        ),
      ],
    );
  }
}

/// Dialog hiển thị khi location service bị tắt
class LocationServiceDisabledDialog extends StatelessWidget {
  const LocationServiceDisabledDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          TablerIcons.gps,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
          size: 32,
        ),
      ),
      title: Text(
        'Dịch vụ vị trí chưa bật',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vui lòng bật dịch vụ vị trí (GPS) để sử dụng chức năng chấm công.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.settings,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cài đặt > Vị trí > Bật dịch vụ vị trí',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await LocationService.openLocationSettings();
          },
          child: const Text('Mở cài đặt'),
        ),
      ],
    );
  }

  /// Hiển thị dialog location service disabled
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LocationServiceDisabledDialog(),
    );
  }
} 