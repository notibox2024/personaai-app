import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../data/models/location_data.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Widget hiển thị thông tin vị trí và validation
class LocationInfoCard extends StatelessWidget {
  final LocationData locationData;
  final VoidCallback onRefreshLocation;

  const LocationInfoCard({
    super.key,
    required this.locationData,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.map_pin,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin vị trí',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefreshLocation,
                icon: Icon(
                  TablerIcons.refresh,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Cập nhật vị trí',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Validation Status
          _buildValidationStatus(theme),

          const SizedBox(height: 16),

          // Location Details
          _buildLocationDetails(theme),

          const SizedBox(height: 16),

          // GPS & WiFi Info
          _buildTechnicalInfo(theme),
        ],
      ),
    );
  }

  Widget _buildValidationStatus(ThemeData theme) {
    final status = locationData.validationStatus;
    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    switch (status) {
      case LocationValidationStatus.valid:
        statusColor = Colors.green;
        statusIcon = TablerIcons.circle_check;
        statusTitle = 'Vị trí hợp lệ';
        break;
      case LocationValidationStatus.warning:
        statusColor = Colors.orange;
        statusIcon = TablerIcons.alert_triangle;
        statusTitle = 'Cảnh báo vị trí';
        break;
      case LocationValidationStatus.invalid:
        statusColor = Colors.red;
        statusIcon = TablerIcons.circle_x;
        statusTitle = 'Vị trí không hợp lệ';
        break;
      case LocationValidationStatus.checking:
        statusColor = theme.colorScheme.primary;
        statusIcon = TablerIcons.loader;
        statusTitle = 'Đang kiểm tra...';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationData.displayMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetails(ThemeData theme) {
    return Column(
      children: [
        // Address
        _buildLocationDetailRow(
          theme: theme,
          icon: TablerIcons.building,
          label: 'Địa chỉ',
          value: locationData.address ?? 'Không xác định',
          color: theme.colorScheme.primary,
        ),
        
        const SizedBox(height: 12),
        
        // Distance to office
        _buildLocationDetailRow(
          theme: theme,
          icon: TablerIcons.ruler,
          label: 'Khoảng cách văn phòng',
          value: locationData.distanceString,
          color: locationData.isInOfficeRadius
              ? Colors.green
              : Colors.orange,
        ),
        
        const SizedBox(height: 12),
        
        // Coordinates
        _buildLocationDetailRow(
          theme: theme,
          icon: TablerIcons.target,
          label: 'Tọa độ GPS',
          value: locationData.coordinatesString,
          color: theme.colorScheme.secondary,
          isMonospace: true,
        ),
      ],
    );
  }

  Widget _buildLocationDetailRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
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
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFeatures: isMonospace
                      ? [const FontFeature.tabularFigures()]
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin kỹ thuật',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // GPS Accuracy
              Expanded(
                child: _buildTechInfoItem(
                  theme: theme,
                  icon: TablerIcons.satellite,
                  label: 'Độ chính xác GPS',
                  value: locationData.accuracyString,
                  isGoodValue: locationData.accuracy <= 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // WiFi Status
              Expanded(
                child: _buildTechInfoItem(
                  theme: theme,
                  icon: TablerIcons.wifi,
                  label: 'WiFi văn phòng',
                  value: locationData.isOfficeWifi ? 'Kết nối' : 'Không kết nối',
                  isGoodValue: locationData.isOfficeWifi,
                ),
              ),
            ],
          ),
          
          if (locationData.wifiSSID != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  TablerIcons.wifi,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'SSID: ${locationData.wifiSSID}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTechInfoItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required bool isGoodValue,
  }) {
    final color = isGoodValue ? Colors.green : Colors.orange;

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 