import '../models/weather_data.dart';
import 'api_service.dart';
import 'dart:math' as math;

/// Service để lấy dữ liệu thời tiết từ Open-Meteo API
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final ApiService _apiService = ApiService();

  // Base URL cho Open-Meteo API
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  // Tọa độ mặc định (TP.HCM) - có thể thay đổi khi lấy được location từ device
  static const double _defaultLatitude = 10.75;
  static const double _defaultLongitude = 106.67;

  // Cache system
  static const Duration _cacheExpiration = Duration(hours: 1);
  static const double _cacheRadiusKm = 10.0; // Bán kính cache 10km
  final Map<String, _CachedWeatherData> _cache = {};

  /// Tính khoảng cách giữa hai điểm địa lý theo công thức Haversine (km)
  double _calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadiusKm = 6371;
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  /// Chuyển độ sang radian
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Tạo cache key từ latitude và longitude
  String _getCacheKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';
  }

  /// Tìm cache trong bán kính cho phép
  _CachedWeatherData? _findCacheInRadius(double latitude, double longitude) {
    final now = DateTime.now();
    
    for (final entry in _cache.entries) {
      final cachedData = entry.value;
      
      // Kiểm tra cache còn hạn không
      if (now.difference(cachedData.timestamp) >= _cacheExpiration) {
        continue;
      }
      
      // Tính khoảng cách từ vị trí hiện tại đến vị trí đã cache
      final double distance = _calculateDistance(
        latitude, longitude,
        cachedData.latitude, cachedData.longitude,
      );
      
      // Nếu trong bán kính cho phép thì trả về cache này
      if (distance <= _cacheRadiusKm) {
        return cachedData;
      }
    }
    
    return null;
  }

  /// Lấy dữ liệu từ cache trong bán kính
  WeatherData? _getFromCache(double latitude, double longitude) {
    final cachedData = _findCacheInRadius(latitude, longitude);
    return cachedData?.data;
  }

  /// Lưu dữ liệu vào cache
  void _saveToCache(String key, WeatherData data, double latitude, double longitude) {
    _cache[key] = _CachedWeatherData(
      data: data,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Xóa cache hết hạn
  void _cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, cachedData) => 
      now.difference(cachedData.timestamp) >= _cacheExpiration
    );
  }

  /// Xóa toàn bộ cache
  void clearCache() {
    _cache.clear();
  }

  /// Lấy thời tiết hiện tại với tọa độ mặc định
  Future<WeatherData> getCurrentWeather() async {
    return getCurrentWeatherByLocation(_defaultLatitude, _defaultLongitude);
  }

  /// Lấy thời tiết hiện tại theo tọa độ cụ thể
  Future<WeatherData> getCurrentWeatherByLocation(
    double latitude,
    double longitude,
  ) async {
    // Kiểm tra cache trong bán kính trước
    final cachedData = _getFromCache(latitude, longitude);
    if (cachedData != null) {
      return cachedData;
    }

    // Dọn dẹp cache hết hạn
    _cleanExpiredCache();

    try {
      final response = await _apiService.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current_weather': true,
          'timezone': 'auto', // Tự động detect timezone
        },
      );

      final weatherData = WeatherData.fromJson(response.data);
      
      // Lưu vào cache với tọa độ
      final cacheKey = _getCacheKey(latitude, longitude);
      _saveToCache(cacheKey, weatherData, latitude, longitude);
      
      return weatherData;
    } on ApiException catch (e) {
      throw WeatherException(
        message: 'Không thể lấy dữ liệu thời tiết: ${e.message}',
        type: WeatherExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      throw WeatherException(
        message: 'Lỗi không xác định khi lấy dữ liệu thời tiết',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Lấy thời tiết với forecast 7 ngày (tùy chọn mở rộng)
  Future<WeatherData> getWeatherForecast({
    double? latitude,
    double? longitude,
    int days = 7,
  }) async {
    final lat = latitude ?? _defaultLatitude;
    final lng = longitude ?? _defaultLongitude;

    // Kiểm tra cache trong bán kính trước (với prefix forecast)
    final existingCache = _findCacheInRadius(lat, lng);
    if (existingCache != null && existingCache.forecastDays == days) {
      return existingCache.data;
    }

    // Dọn dẹp cache hết hạn
    _cleanExpiredCache();

    try {
      final response = await _apiService.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current_weather': true,
          'daily': 'weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum',
          'forecast_days': days,
          'timezone': 'auto',
        },
      );

      final weatherData = WeatherData.fromJson(response.data);
      
      // Lưu vào cache với thông tin forecast
      final cacheKey = 'forecast_${days}_${_getCacheKey(lat, lng)}';
      _cache[cacheKey] = _CachedWeatherData(
        data: weatherData,
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
        forecastDays: days,
      );
      
      return weatherData;
    } on ApiException catch (e) {
      throw WeatherException(
        message: 'Không thể lấy dự báo thời tiết: ${e.message}',
        type: WeatherExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      throw WeatherException(
        message: 'Lỗi không xác định khi lấy dự báo thời tiết',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Kiểm tra tính khả dụng của API
  Future<bool> checkApiAvailability() async {
    try {
      await getCurrentWeather();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lấy thông tin thời tiết cho nhiều địa điểm
  Future<List<WeatherData>> getMultipleLocationsWeather(
    List<LocationCoordinate> locations,
  ) async {
    try {
      // Gọi API song song cho nhiều địa điểm
      final futures = locations.map((location) => 
        getCurrentWeatherByLocation(location.latitude, location.longitude)
      ).toList();

      return await Future.wait(futures);
    } catch (e) {
      throw WeatherException(
        message: 'Không thể lấy thời tiết cho nhiều địa điểm',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Lấy thời tiết theo tên thành phố (cần geocoding service)
  /// TODO: Implement geocoding để convert city name -> coordinates
  Future<WeatherData> getWeatherByCity(String cityName) async {
    WeatherData weatherData;
    
    // Tạm thời sử dụng coordinate mặc định
    // Trong tương lai có thể tích hợp với geocoding service
    switch (cityName.toLowerCase()) {
      case 'ho chi minh':
      case 'hcm':
      case 'saigon':
        weatherData = await getCurrentWeatherByLocation(10.75, 106.67);
        break;
      case 'hanoi':
      case 'ha noi':
        weatherData = await getCurrentWeatherByLocation(21.0285, 105.8542);
        break;
      case 'da nang':
        weatherData = await getCurrentWeatherByLocation(16.0544, 108.2022);
        break;
      default:
        weatherData = await getCurrentWeather(); // Fallback to default location
    }
    
    return weatherData;
  }

  /// Lấy thông tin cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    
    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) < _cacheExpiration) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }
    
    return {
      'total_entries': _cache.length,
      'valid_entries': validEntries,
      'expired_entries': expiredEntries,
      'cache_expiration_hours': _cacheExpiration.inHours,
      'cache_radius_km': _cacheRadiusKm,
    };
  }

  /// Lấy danh sách cache hiện tại với thông tin vị trí
  List<Map<String, dynamic>> getCacheDetails() {
    final now = DateTime.now();
    
    return _cache.entries.map((entry) {
      final cachedData = entry.value;
      final isValid = now.difference(cachedData.timestamp) < _cacheExpiration;
      
      return {
        'key': entry.key,
        'latitude': cachedData.latitude,
        'longitude': cachedData.longitude,
        'cached_at': cachedData.timestamp.toIso8601String(),
        'is_valid': isValid,
        'forecast_days': cachedData.forecastDays,
        'expires_in_minutes': isValid 
          ? _cacheExpiration.inMinutes - now.difference(cachedData.timestamp).inMinutes
          : 0,
      };
    }).toList();
  }
}

/// Model cho cache data với thông tin vị trí
class _CachedWeatherData {
  final WeatherData data;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int? forecastDays;

  const _CachedWeatherData({
    required this.data,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.forecastDays,
  });
}

/// Model cho tọa độ địa lý
class LocationCoordinate {
  final double latitude;
  final double longitude;
  final String? name;

  const LocationCoordinate({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  @override
  String toString() {
    return name ?? '$latitude, $longitude';
  }
}

/// Custom exception cho Weather Service
class WeatherException implements Exception {
  final String message;
  final WeatherExceptionType type;
  final Object? originalException;

  const WeatherException({
    required this.message,
    required this.type,
    this.originalException,
  });

  @override
  String toString() => 'WeatherException: $message';
}

/// Loại lỗi cho Weather Service
enum WeatherExceptionType {
  apiError,
  networkError,
  locationError,
  parseError,
  unknown,
}

/// Hằng số cho các thành phố phổ biến
class WeatherCities {
  static const hoChiMinh = LocationCoordinate(
    latitude: 10.75,
    longitude: 106.67,
    name: 'TP. Hồ Chí Minh',
  );

  static const hanoi = LocationCoordinate(
    latitude: 21.0285,
    longitude: 105.8542,
    name: 'Hà Nội',
  );

  static const daNang = LocationCoordinate(
    latitude: 16.0544,
    longitude: 108.2022,
    name: 'Đà Nẵng',
  );

  static const canTho = LocationCoordinate(
    latitude: 10.0452,
    longitude: 105.7469,
    name: 'Cần Thơ',
  );

  static const haiphong = LocationCoordinate(
    latitude: 20.8449,
    longitude: 106.6881,
    name: 'Hải Phòng',
  );

  static List<LocationCoordinate> get majorCities => [
    hoChiMinh,
    hanoi,
    daNang,
    canTho,
    haiphong,
  ];
} 