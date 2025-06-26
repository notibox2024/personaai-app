import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/shared_exports.dart';

/// Widget welcome banner
class WelcomeBanner extends StatefulWidget {
  final String employeeName;
  final Position? currentPosition;
  final bool isLocationLoading;
  final VoidCallback? onLocationRefresh;

  const WelcomeBanner({
    super.key,
    required this.employeeName,
    this.currentPosition,
    this.isLocationLoading = false,
    this.onLocationRefresh,
  });

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> {
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  @override
  void didUpdateWidget(WelcomeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reload weather khi position thay đổi
    if (oldWidget.currentPosition != widget.currentPosition) {
      _loadWeatherData();
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      WeatherData? weatherData;
      
      // Sử dụng location thật nếu có, không thì fallback về mock
      if (widget.currentPosition != null) {
        weatherData = await _weatherService.getCurrentWeatherByLocation(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        );
      } else {
        // Fallback về mock location
        weatherData = await _weatherService.getCurrentWeather();  
      }
      
      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekdays = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateString = '${weekdays[now.weekday % 7]}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final greeting = _getGreeting(now.hour);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Tech pattern background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: TechPatternPainter(
                  primaryColor: theme.colorScheme.primary.withValues(alpha: 0.03),
                  secondaryColor: theme.colorScheme.secondary.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Greeting section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getGreetingIcon(now.hour),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chúc bạn một ngày tuyệt vời!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date and time info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Date info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              TablerIcons.calendar,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hôm nay',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateString,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  
                  // Time and weather
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                TablerIcons.clock,
                                color: theme.colorScheme.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentTime,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildWeatherInfo(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(ThemeData theme) {
    // Hiển thị loading state với location loading
    if (_isLoadingWeather || widget.isLocationLoading) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.isLocationLoading ? 'Đang lấy vị trí...' : 'Đang tải...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (_weatherData == null) {
      return Row(
        children: [
          Icon(
            TablerIcons.cloud_off,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.currentPosition == null ? 'Không có GPS' : 'Không có dữ liệu',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.currentPosition == null && widget.onLocationRefresh != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onLocationRefresh,
              child: Icon(
                TablerIcons.refresh,
                color: theme.colorScheme.primary,
                size: 14,
              ),
            ),
          ],
        ],
      );
    }

    final weather = _weatherData!.currentWeather;
    
    return Row(
      children: [
        Icon(
          weather.weatherIcon,
          color: weather.weatherColor,
          size: 16,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${weather.temperatureString} ${weather.weatherDescription}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: weather.weatherColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // GPS indicator cho weather chính xác
        if (widget.currentPosition != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'GPS',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 6) {
      return 'Chúc ngủ ngon! 🌙';
    } else if (hour < 12) {
      return 'Chào buổi sáng! ☀️';
    } else if (hour < 18) {
      return 'Chào buổi chiều! 🌤️';
    } else {
      return 'Chào buổi tối! 🌆';
    }
  }

  IconData _getGreetingIcon(int hour) {
    if (hour < 6) {
      return TablerIcons.moon;
    } else if (hour < 12) {
      return TablerIcons.sun;
    } else if (hour < 18) {
      return TablerIcons.sun_high;
    } else {
      return TablerIcons.sunset;
    }
  }
}

/// Custom painter để vẽ họa tiết công nghệ làm nền
class TechPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const TechPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final secondaryPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Vẽ lưới circuit
    _drawCircuitGrid(canvas, size, primaryPaint);
    
    // Vẽ các đường kết nối
    _drawConnections(canvas, size, secondaryPaint);
    
    // Vẽ các nút circuit
    _drawCircuitNodes(canvas, size, primaryPaint);
  }

  void _drawCircuitGrid(Canvas canvas, Size size, Paint paint) {
    const double spacing = 40;
    
    // Vẽ đường ngang
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Vẽ đường dọc
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawConnections(Canvas canvas, Size size, Paint paint) {
    const double spacing = 40;
    
    // Vẽ các đường kết nối chéo
    for (double x = 0; x < size.width; x += spacing * 2) {
      for (double y = 0; y < size.height; y += spacing * 2) {
        // Đường chéo ngắn
        canvas.drawLine(
          Offset(x, y),
          Offset(x + spacing * 0.5, y + spacing * 0.5),
          paint,
        );
        
        // Đường chéo ngược
        canvas.drawLine(
          Offset(x + spacing, y),
          Offset(x + spacing * 0.5, y + spacing * 0.5),
          paint,
        );
      }
    }
  }

  void _drawCircuitNodes(Canvas canvas, Size size, Paint paint) {
    const double spacing = 40;
    final nodePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Vẽ các nút tại giao điểm
    for (double x = spacing; x < size.width; x += spacing * 2) {
      for (double y = spacing; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 2, nodePaint);
      }
    }
    
    // Vẽ một số hình chữ nhật nhỏ (IC chips)
    final chipPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
      
    for (double x = spacing * 1.5; x < size.width; x += spacing * 3) {
      for (double y = spacing * 1.5; y < size.height; y += spacing * 3) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 4, y - 2, 8, 4),
            const Radius.circular(1),
          ),
          chipPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension GradientScale on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withValues(alpha: opacity)).toList(),
    );
  }
} 