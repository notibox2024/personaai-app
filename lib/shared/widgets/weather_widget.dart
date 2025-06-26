import 'package:flutter/material.dart';
import '../shared_exports.dart';

/// Widget hiển thị thông tin thời tiết compact
class WeatherWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool useWhiteText; // Sử dụng text màu trắng cho header

  const WeatherWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.onTap,
    this.showDetails = false,
    this.useWhiteText = false,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weatherData = widget.latitude != null && widget.longitude != null
          ? await _weatherService.getCurrentWeatherByLocation(
              widget.latitude!,
              widget.longitude!,
            )
          : await _weatherService.getCurrentWeather();

      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } on WeatherException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_weatherData == null) {
      return _buildEmptyState(theme);
    }

    return widget.showDetails
        ? _buildDetailedWeather(theme)
        : _buildCompactWeather(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Đang tải thời tiết...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 20,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadWeatherData,
          icon: Icon(
            Icons.refresh,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Thử lại',
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.cloud_off,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          'Không có dữ liệu thời tiết',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactWeather(ThemeData theme) {
    final weather = _weatherData!.currentWeather;
    final textColor = widget.useWhiteText ? Colors.white : theme.colorScheme.onSurface;
    final secondaryTextColor = widget.useWhiteText 
        ? Colors.white.withValues(alpha: 0.8) 
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        // Weather Icon
        Icon(
          weather.weatherIcon,
          size: 24,
          color: widget.useWhiteText ? Colors.white : weather.weatherColor,
        ),
        const SizedBox(width: 12),

        // Temperature and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temperature
              Text(
                weather.temperatureString,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              
              // Weather description
              Text(
                weather.weatherDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Refresh button (chỉ hiển thị khi không dùng white text)
        if (!widget.useWhiteText)
          IconButton(
            onPressed: _loadWeatherData,
            icon: Icon(
              Icons.refresh,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Cập nhật',
          ),
      ],
    );
  }

  Widget _buildDetailedWeather(ThemeData theme) {
    final weather = _weatherData!.currentWeather;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main weather info
        Row(
          children: [
            Icon(
              weather.weatherIcon,
              size: 32,
              color: weather.weatherColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.temperatureString,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    weather.weatherDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadWeatherData,
              icon: Icon(
                Icons.refresh,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Cập nhật',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Additional details
        Row(
          children: [
            // Wind info
            Expanded(
              child: _buildDetailRow(
                theme: theme,
                icon: Icons.air,
                label: 'Gió',
                value: '${weather.windspeedString} ${weather.windDirectionText}',
              ),
            ),
            const SizedBox(width: 16),
            // Time info
            Expanded(
              child: _buildDetailRow(
                theme: theme,
                icon: Icons.access_time,
                label: 'Cập nhật',
                value: weather.timeString,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Location info
        _buildDetailRow(
          theme: theme,
          icon: Icons.location_on,
          label: 'Vị trí',
          value: _weatherData!.locationString,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Column(
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
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 