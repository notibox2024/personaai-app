import '../models/weather_data.dart';
import '../models/weather_request.dart';
import 'api_service.dart';
import 'token_manager.dart';
import 'dart:math' as math;
import 'package:logger/logger.dart';

/// Service để lấy dữ liệu thời tiết từ backend API
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Sử dụng getter để đảm bảo lấy ApiService singleton đã được khởi tạo
  ApiService get _apiService => ApiService();
  final Logger _logger = Logger();

  // Backend API endpoints
  static const String _baseEndpoint = '/api/v1/weather';
  static const String _currentEndpoint = '$_baseEndpoint/current';
  static const String _hanoiTestEndpoint = '$_baseEndpoint/hanoi';
  static const String _berlinTestEndpoint = '$_baseEndpoint/berlin';

  // Tọa độ mặc định (TP.HCM) - có thể thay đổi khi lấy được location từ device
  static const double _defaultLatitude = 10.75;
  static const double _defaultLongitude = 106.67;

  // Cache system
  static const Duration _cacheExpiration = Duration(minutes: 30); // Backend cache thời gian ngắn hơn
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

  /// Lấy thời tiết hiện tại theo tọa độ cụ thể (sử dụng POST endpoint)
  Future<WeatherData> getCurrentWeatherByLocation(
    double latitude,
    double longitude, {
    String temperatureUnit = TemperatureUnit.celsius,
    String windspeedUnit = WindSpeedUnit.kmh,
    String precipitationUnit = PrecipitationUnit.mm,
  }) async {
    // Kiểm tra cache trong bán kính trước
    final cachedData = _getFromCache(latitude, longitude);
    if (cachedData != null) {
      _logger.d('Weather data found in cache for $latitude, $longitude');
      return cachedData;
    }

    // Dọn dẹp cache hết hạn
    _cleanExpiredCache();

    try {
      _logger.i('Fetching weather from backend API for $latitude, $longitude');
      
      // Debug: Kiểm tra token availability
      final tokenManager = TokenManager();
      final hasToken = await tokenManager.getAccessToken() != null;
      _logger.d('Token available: $hasToken');
      
      // Tạo request model
      final request = WeatherRequest(
        latitude: latitude,
        longitude: longitude,
        currentWeather: true,
        timezone: 'auto',
        temperatureUnit: temperatureUnit,
        windspeedUnit: windspeedUnit,
        precipitationUnit: precipitationUnit,
      );

      // Gọi backend API với authentication
      final response = await _apiService.post(
        _currentEndpoint,
        data: request.toJson(),
      );

      final weatherData = WeatherData.fromJson(response.data);
      
      // Lưu vào cache với tọa độ
      final cacheKey = _getCacheKey(latitude, longitude);
      _saveToCache(cacheKey, weatherData, latitude, longitude);
      
      _logger.i('Weather data fetched successfully from backend');
      return weatherData;
      
    } on ApiException catch (e) {
      _logger.e('Backend weather API error: ${e.message}');
      throw WeatherException(
        message: 'Không thể lấy dữ liệu thời tiết từ backend: ${e.message}',
        type: WeatherExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      _logger.e('Unknown weather service error: $e');
      throw WeatherException(
        message: 'Lỗi không xác định khi lấy dữ liệu thời tiết',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Lấy thời tiết hiện tại theo tọa độ cụ thể (sử dụng GET endpoint đơn giản)
  Future<WeatherData> getCurrentWeatherSimple(
    double latitude,
    double longitude,
  ) async {
    // Kiểm tra cache trong bán kính trước
    final cachedData = _getFromCache(latitude, longitude);
    if (cachedData != null) {
      _logger.d('Weather data found in cache for $latitude, $longitude');
      return cachedData;
    }

    // Dọn dẹp cache hết hạn
    _cleanExpiredCache();

    try {
      _logger.i('Fetching weather from backend API (simple) for $latitude, $longitude');
      
      // Gọi backend API GET endpoint với query parameters
      final response = await _apiService.get(
        _currentEndpoint,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      final weatherData = WeatherData.fromJson(response.data);
      
      // Lưu vào cache với tọa độ
      final cacheKey = _getCacheKey(latitude, longitude);
      _saveToCache(cacheKey, weatherData, latitude, longitude);
      
      _logger.i('Weather data fetched successfully from backend (simple)');
      return weatherData;
      
    } on ApiException catch (e) {
      _logger.e('Backend weather API error: ${e.message}');
      throw WeatherException(
        message: 'Không thể lấy dữ liệu thời tiết từ backend: ${e.message}',
        type: WeatherExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      _logger.e('Unknown weather service error: $e');
      throw WeatherException(
        message: 'Lỗi không xác định khi lấy dữ liệu thời tiết',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Lấy thời tiết Hà Nội (test endpoint)
  Future<WeatherData> getHanoiWeather() async {
    try {
      _logger.i('Fetching Hanoi weather from test endpoint');
      
      final response = await _apiService.get(_hanoiTestEndpoint);
      final weatherData = WeatherData.fromJson(response.data);
      
      _logger.i('Hanoi weather data fetched successfully');
      return weatherData;
      
    } on ApiException catch (e) {
      _logger.e('Hanoi weather API error: ${e.message}');
      throw WeatherException(
        message: 'Không thể lấy dữ liệu thời tiết Hà Nội: ${e.message}',
        type: WeatherExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      _logger.e('Unknown Hanoi weather error: $e');
      throw WeatherException(
        message: 'Lỗi không xác định khi lấy thời tiết Hà Nội',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Lấy thời tiết Berlin (test endpoint)
  Future<WeatherData> getBerlinWeather() async {
    try {
      _logger.i('Fetching Berlin weather from test endpoint');
      
      final response = await _apiService.get(_berlinTestEndpoint);
      final weatherData = WeatherData.fromJson(response.data);
      
      _logger.i('Berlin weather data fetched successfully');
      return weatherData;
      
    } on ApiException catch (e) {
      _logger.e('Berlin weather API error: ${e.message}');
      throw WeatherException(
        message: 'Không thể lấy dữ liệu thời tiết Berlin: ${e.message}',
        type: WeatherExceptionType.apiError,
        originalException: e,
      );
    } catch (e) {
      _logger.e('Unknown Berlin weather error: $e');
      throw WeatherException(
        message: 'Lỗi không xác định khi lấy thời tiết Berlin',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Kiểm tra tính khả dụng của backend API
  Future<bool> checkApiAvailability() async {
    try {
      await getHanoiWeather(); // Sử dụng test endpoint không cần auth
      return true;
    } catch (e) {
      _logger.w('Backend weather API not available: $e');
      return false;
    }
  }

  /// Lấy thông tin thời tiết cho nhiều địa điểm
  Future<List<WeatherData>> getMultipleLocationsWeather(
    List<LocationCoordinate> locations, {
    String temperatureUnit = TemperatureUnit.celsius,
    String windspeedUnit = WindSpeedUnit.kmh,
    String precipitationUnit = PrecipitationUnit.mm,
  }) async {
    try {
      _logger.i('Fetching weather for ${locations.length} locations');
      
      // Gọi API song song cho nhiều địa điểm
      final futures = locations.map((location) => 
        getCurrentWeatherByLocation(
          location.latitude, 
          location.longitude,
          temperatureUnit: temperatureUnit,
          windspeedUnit: windspeedUnit,
          precipitationUnit: precipitationUnit,
        )
      ).toList();

      final results = await Future.wait(futures);
      _logger.i('Successfully fetched weather for ${results.length} locations');
      return results;
      
    } catch (e) {
      _logger.e('Error fetching multiple locations weather: $e');
      throw WeatherException(
        message: 'Không thể lấy thời tiết cho nhiều địa điểm',
        type: WeatherExceptionType.unknown,
        originalException: e,
      );
    }
  }

  /// Lấy thời tiết theo tên thành phố (sử dụng predefined coordinates)
  Future<WeatherData> getWeatherByCity(String cityName, {
    String temperatureUnit = TemperatureUnit.celsius,
    String windspeedUnit = WindSpeedUnit.kmh,
    String precipitationUnit = PrecipitationUnit.mm,
  }) async {
    WeatherData weatherData;
    
    _logger.i('Fetching weather for city: $cityName');
    
    // Sử dụng coordinate được định nghĩa sẵn
    switch (cityName.toLowerCase()) {
      case 'ho chi minh':
      case 'hcm':
      case 'saigon':
        weatherData = await getCurrentWeatherByLocation(
          WeatherCities.hoChiMinh.latitude, 
          WeatherCities.hoChiMinh.longitude,
          temperatureUnit: temperatureUnit,
          windspeedUnit: windspeedUnit,
          precipitationUnit: precipitationUnit,
        );
        break;
      case 'hanoi':
      case 'ha noi':
        // Có thể sử dụng test endpoint cho Hà Nội
        try {
          weatherData = await getHanoiWeather();
        } catch (e) {
          // Fallback to coordinate-based request
          weatherData = await getCurrentWeatherByLocation(
            WeatherCities.hanoi.latitude,
            WeatherCities.hanoi.longitude,
            temperatureUnit: temperatureUnit,
            windspeedUnit: windspeedUnit,
            precipitationUnit: precipitationUnit,
          );
        }
        break;
      case 'da nang':
        weatherData = await getCurrentWeatherByLocation(
          WeatherCities.daNang.latitude,
          WeatherCities.daNang.longitude,
          temperatureUnit: temperatureUnit,
          windspeedUnit: windspeedUnit,
          precipitationUnit: precipitationUnit,
        );
        break;
      case 'can tho':
        weatherData = await getCurrentWeatherByLocation(
          WeatherCities.canTho.latitude,
          WeatherCities.canTho.longitude,
          temperatureUnit: temperatureUnit,
          windspeedUnit: windspeedUnit,
          precipitationUnit: precipitationUnit,
        );
        break;
      case 'hai phong':
        weatherData = await getCurrentWeatherByLocation(
          WeatherCities.haiphong.latitude,
          WeatherCities.haiphong.longitude,
          temperatureUnit: temperatureUnit,
          windspeedUnit: windspeedUnit,
          precipitationUnit: precipitationUnit,
        );
        break;
      default:
        _logger.w('City not found: $cityName, using default location');
        weatherData = await getCurrentWeather(); // Fallback to default location
    }
    
    _logger.i('Successfully fetched weather for city: $cityName');
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
      'cache_expiration_minutes': _cacheExpiration.inMinutes,
      'cache_radius_km': _cacheRadiusKm,
      'backend_api': true,
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
        'expires_in_minutes': isValid 
          ? _cacheExpiration.inMinutes - now.difference(cachedData.timestamp).inMinutes
          : 0,
      };
    }).toList();
  }

  /// Test connectivity với tất cả endpoints
  Future<Map<String, bool>> testAllEndpoints() async {
    final results = <String, bool>{};
    
    try {
      await getHanoiWeather();
      results['hanoi_test'] = true;
    } catch (e) {
      results['hanoi_test'] = false;
    }
    
    try {
      await getBerlinWeather();
      results['berlin_test'] = true;
    } catch (e) {
      results['berlin_test'] = false;
    }
    
    try {
      await getCurrentWeatherSimple(21.0285, 105.8542); // Hanoi coordinates
      results['current_get'] = true;
    } catch (e) {
      results['current_get'] = false;
    }
    
    try {
      await getCurrentWeatherByLocation(21.0285, 105.8542); // Hanoi coordinates
      results['current_post'] = true;
    } catch (e) {
      results['current_post'] = false;
    }
    
    return results;
  }
}

/// Model cho cache data với thông tin vị trí
class _CachedWeatherData {
  final WeatherData data;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  const _CachedWeatherData({
    required this.data,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
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