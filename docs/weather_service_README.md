# Weather Service - Open-Meteo Integration

Weather Service tích hợp với [Open-Meteo API](https://api.open-meteo.com) để lấy dữ liệu thời tiết thời gian thực.

## Tính năng

✅ **Lấy thời tiết hiện tại** với tọa độ mặc định hoặc tùy chỉnh  
✅ **WMO Weather Codes mapping** với Tabler Icons và mô tả tiếng Việt  
✅ **Multi-location support** - lấy thời tiết nhiều địa điểm song song  
✅ **Built-in caching** và error handling  
✅ **Widget UI components** sẵn sàng sử dụng  

## Cài đặt

Weather Service đã được tích hợp sẵn và sử dụng Dio service có sẵn trong dự án.

```dart
import 'package:personaai/shared/shared_exports.dart';
```

## Sử dụng cơ bản

### 1. Lấy thời tiết hiện tại

```dart
final weatherService = WeatherService();

try {
  // Sử dụng tọa độ mặc định (TP.HCM)
  final weather = await weatherService.getCurrentWeather();
  
  print("Nhiệt độ: ${weather.currentWeather.temperatureString}");
  print("Mô tả: ${weather.currentWeather.weatherDescription}");
} on WeatherException catch (e) {
  print("Lỗi thời tiết: ${e.message}");
}
```

### 2. Lấy thời tiết theo tọa độ

```dart
try {
  final weather = await weatherService.getCurrentWeatherByLocation(
    21.0285, // Hà Nội latitude
    105.8542, // Hà Nội longitude
  );
  
  print("Thời tiết Hà Nội: ${weather.currentWeather.temperatureString}");
} catch (e) {
  print("Lỗi: $e");
}
```

### 3. Sử dụng các thành phố có sẵn

```dart
// Sử dụng constants có sẵn
final weather = await weatherService.getCurrentWeatherByLocation(
  WeatherCities.hanoi.latitude,
  WeatherCities.hanoi.longitude,
);

// Hoặc lấy thời tiết nhiều thành phố
final weathers = await weatherService.getMultipleLocationsWeather([
  WeatherCities.hoChiMinh,
  WeatherCities.hanoi,
  WeatherCities.daNang,
]);
```

## Weather Widget

### Compact Weather Widget

```dart
WeatherWidget(
  showDetails: false, // Hiển thị compact
  onTap: () {
    // Handle tap
  },
)
```

### Detailed Weather Widget

```dart
WeatherWidget(
  latitude: 10.75,
  longitude: 106.67,
  showDetails: true, // Hiển thị đầy đủ thông tin
  onTap: () {
    // Navigate to weather detail page
  },
)
```

## Weather Data Model

### CurrentWeather Properties

```dart
final weather = weatherData.currentWeather;

// Thông tin cơ bản
String temperature = weather.temperatureString; // "28°C"
String description = weather.weatherDescription; // "Mưa rào nhẹ"
IconData icon = weather.weatherIcon; // TablerIcons.cloud_rain
Color iconColor = weather.weatherColor; // Colors.blue

// Thông tin gió
String windSpeed = weather.windspeedString; // "12 km/h"
String windDirection = weather.windDirectionText; // "Tây Nam"

// Thời gian
String time = weather.timeString; // "14:30"
bool isDay = weather.isDay; // true/false
```

### WMO Weather Codes

Service hỗ trợ đầy đủ WMO weather codes với mapping tương ứng:

| Code | Mô tả | Icon | Màu |
|------|-------|------|-----|
| 0 | Trời quang | `sun`/`moon` | Orange/Indigo |
| 1-3 | Ít mây - Nhiều mây | `sun_high`/`cloud` | Grey |
| 45-48 | Sương mù | `cloud` | Grey |
| 51-57 | Mưa phùn | `droplet`/`snowflake` | Light Blue |
| 61-67 | Mưa | `cloud_rain`/`snowflake` | Blue |
| 71-77 | Tuyết | `snowflake` | Light Blue |
| 80-86 | Mưa rào/Tuyết rào | `cloud_rain`/`snowflake` | Blue |
| 95-99 | Dông | `bolt` | Purple |

## Error Handling

```dart
try {
  final weather = await weatherService.getCurrentWeather();
} on WeatherException catch (e) {
  switch (e.type) {
    case WeatherExceptionType.apiError:
      // Lỗi từ API
      break;
    case WeatherExceptionType.networkError:
      // Lỗi mạng
      break;
    case WeatherExceptionType.locationError:
      // Lỗi vị trí
      break;
    default:
      // Lỗi khác
  }
}
```

## API Configuration

Base URL: `https://api.open-meteo.com/v1`

**Endpoint chính:** `/forecast`

**Query Parameters:**
- `latitude`: Vĩ độ
- `longitude`: Kinh độ  
- `current_weather`: `true`
- `timezone`: `auto`

**Response format:** JSON theo chuẩn Open-Meteo

## Mở rộng

### Thêm thành phố mới

```dart
class WeatherCities {
  static const myCity = LocationCoordinate(
    latitude: 12.345,
    longitude: 67.890,
    name: 'Thành phố của tôi',
  );
}
```

### Forecast 7 ngày (WIP)

```dart
final forecast = await weatherService.getWeatherForecast(
  days: 7,
  latitude: 10.75,
  longitude: 106.67,
);
```

## Ví dụ hoàn chỉnh

```dart
class WeatherDemo extends StatefulWidget {
  @override
  _WeatherDemoState createState() => _WeatherDemoState();
}

class _WeatherDemoState extends State<WeatherDemo> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      setState(() {
        _weatherData = weather;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather Demo')),
      body: Column(
        children: [
          // Weather Widget
          WeatherWidget(showDetails: true),
          
          // Manual display
          if (_weatherData != null) ...[
            Text('Nhiệt độ: ${_weatherData!.currentWeather.temperatureString}'),
            Text('Mô tả: ${_weatherData!.currentWeather.weatherDescription}'),
            Icon(
              _weatherData!.currentWeather.weatherIcon,
              color: _weatherData!.currentWeather.weatherColor,
              size: 48,
            ),
          ],
        ],
      ),
    );
  }
}
```

## Lưu ý quan trọng

⚠️ **API Limits:** Open-Meteo API có giới hạn request, nên cache kết quả khi có thể  
⚠️ **Permissions:** Cần permission location khi lấy GPS coordinates  
⚠️ **Network:** Cần kiểm tra kết nối mạng trước khi gọi API  

## API Documentation

Tham khao đầy đủ: [Open-Meteo API Docs](https://open-meteo.com/en/docs) 