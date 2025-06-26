import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Model cho đơn vị đo thời tiết
class WeatherUnits {
  final String time;
  final String interval;
  final String temperature;
  final String windspeed;
  final String winddirection;
  final String isDay;
  final String weathercode;

  const WeatherUnits({
    required this.time,
    required this.interval,
    required this.temperature,
    required this.windspeed,
    required this.winddirection,
    required this.isDay,
    required this.weathercode,
  });

  factory WeatherUnits.fromJson(Map<String, dynamic> json) {
    return WeatherUnits(
      time: json['time'] ?? '',
      interval: json['interval'] ?? '',
      temperature: json['temperature'] ?? '',
      windspeed: json['windspeed'] ?? '',
      winddirection: json['winddirection'] ?? '',
      isDay: json['is_day'] ?? '',
      weathercode: json['weathercode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'interval': interval,
      'temperature': temperature,
      'windspeed': windspeed,
      'winddirection': winddirection,
      'is_day': isDay,
      'weathercode': weathercode,
    };
  }
}

/// Model cho thời tiết hiện tại
class CurrentWeather {
  final DateTime time;
  final int interval;
  final double temperature;
  final double windspeed;
  final int winddirection;
  final bool isDay;
  final int weathercode;

  const CurrentWeather({
    required this.time,
    required this.interval,
    required this.temperature,
    required this.windspeed,
    required this.winddirection,
    required this.isDay,
    required this.weathercode,
  });

  /// Lấy icon thời tiết dựa trên WMO weather code
  IconData get weatherIcon {
    switch (weathercode) {
      // Clear sky
      case 0:
        return isDay ? TablerIcons.sun : TablerIcons.moon;
      
      // Mainly clear, partly cloudy, overcast
      case 1:
        return isDay ? TablerIcons.sun : TablerIcons.moon;
      case 2:
        return isDay ? TablerIcons.sun_high : TablerIcons.moon_stars;
      case 3:
        return TablerIcons.cloud;
      
      // Fog and depositing rime fog
      case 45:
      case 48:
        return TablerIcons.cloud;
      
      // Drizzle: Light, moderate, and dense intensity
      case 51:
      case 53:
      case 55:
        return TablerIcons.droplet;
      
      // Freezing Drizzle: Light and dense intensity
      case 56:
      case 57:
        return TablerIcons.snowflake;
      
      // Rain: Slight, moderate and heavy intensity
      case 61:
      case 63:
      case 65:
        return TablerIcons.cloud_rain;
      
      // Freezing Rain: Light and heavy intensity
      case 66:
      case 67:
        return TablerIcons.snowflake;
      
      // Snow fall: Slight, moderate, and heavy intensity
      case 71:
      case 73:
      case 75:
        return TablerIcons.snowflake;
      
      // Snow grains
      case 77:
        return TablerIcons.snowflake;
      
      // Rain showers: Slight, moderate, and violent
      case 80:
      case 81:
      case 82:
        return TablerIcons.cloud_rain;
      
      // Snow showers slight and heavy
      case 85:
      case 86:
        return TablerIcons.snowflake;
      
      // Thunderstorm: Slight or moderate
      case 95:
        return TablerIcons.bolt;
      
      // Thunderstorm with slight and heavy hail
      case 96:
      case 99:
        return TablerIcons.bolt;
      
      default:
        return TablerIcons.cloud;
    }
  }

  /// Mô tả thời tiết bằng tiếng Việt
  String get weatherDescription {
    switch (weathercode) {
      case 0:
        return isDay ? 'Trời quang' : 'Đêm quang';
      case 1:
        return isDay ? 'Chủ yếu quang' : 'Đêm quang';
      case 2:
        return 'Ít mây';
      case 3:
        return 'Nhiều mây';
      case 45:
      case 48:
        return 'Sương mù';
      case 51:
        return 'Mưa phùn nhẹ';
      case 53:
        return 'Mưa phùn vừa';
      case 55:
        return 'Mưa phùn nặng';
      case 56:
      case 57:
        return 'Mưa phùn đóng băng';
      case 61:
        return 'Mưa nhẹ';
      case 63:
        return 'Mưa vừa';
      case 65:
        return 'Mưa to';
      case 66:
      case 67:
        return 'Mưa đóng băng';
      case 71:
        return 'Tuyết nhẹ';
      case 73:
        return 'Tuyết vừa';
      case 75:
        return 'Tuyết to';
      case 77:
        return 'Tuyết rơi';
      case 80:
        return 'Mưa rào nhẹ';
      case 81:
        return 'Mưa rào vừa';
      case 82:
        return 'Mưa rào to';
      case 85:
      case 86:
        return 'Tuyết rào';
      case 95:
        return 'Dông';
      case 96:
      case 99:
        return 'Dông kèm mưa đá';
      default:
        return 'Không xác định';
    }
  }

  /// Màu cho icon thời tiết
  Color get weatherColor {
    switch (weathercode) {
      case 0:
      case 1:
        return isDay ? Colors.orange : Colors.indigo;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.grey.shade700;
      case 45:
      case 48:
        return Colors.grey.shade500;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Colors.lightBlue;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Colors.blue;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Colors.lightBlue.shade200;
      case 95:
      case 96:
      case 99:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Format nhiệt độ
  String get temperatureString => '${temperature.round()}°C';

  /// Format tốc độ gió
  String get windspeedString => '${windspeed.round()} km/h';

  /// Hướng gió bằng text
  String get windDirectionText {
    if (winddirection >= 337.5 || winddirection < 22.5) return 'Bắc';
    if (winddirection >= 22.5 && winddirection < 67.5) return 'Đông Bắc';
    if (winddirection >= 67.5 && winddirection < 112.5) return 'Đông';
    if (winddirection >= 112.5 && winddirection < 157.5) return 'Đông Nam';
    if (winddirection >= 157.5 && winddirection < 202.5) return 'Nam';
    if (winddirection >= 202.5 && winddirection < 247.5) return 'Tây Nam';
    if (winddirection >= 247.5 && winddirection < 292.5) return 'Tây';
    if (winddirection >= 292.5 && winddirection < 337.5) return 'Tây Bắc';
    return 'Không xác định';
  }

  /// Format thời gian
  String get timeString {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: DateTime.parse(json['time']),
      interval: json['interval'] ?? 0,
      temperature: (json['temperature'] as num).toDouble(),
      windspeed: (json['windspeed'] as num).toDouble(),
      winddirection: json['winddirection'] ?? 0,
      isDay: json['is_day'] == 1,
      weathercode: json['weathercode'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'interval': interval,
      'temperature': temperature,
      'windspeed': windspeed,
      'winddirection': winddirection,
      'is_day': isDay ? 1 : 0,
      'weathercode': weathercode,
    };
  }
}

/// Model chính cho dữ liệu thời tiết
class WeatherData {
  final double latitude;
  final double longitude;
  final double generationtimeMs;
  final int utcOffsetSeconds;
  final String timezone;
  final String timezoneAbbreviation;
  final double elevation;
  final WeatherUnits currentWeatherUnits;
  final CurrentWeather currentWeather;

  const WeatherData({
    required this.latitude,
    required this.longitude,
    required this.generationtimeMs,
    required this.utcOffsetSeconds,
    required this.timezone,
    required this.timezoneAbbreviation,
    required this.elevation,
    required this.currentWeatherUnits,
    required this.currentWeather,
  });

  /// Thông tin vị trí
  String get locationString => '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';

  /// Thông tin độ cao
  String get elevationString => '${elevation.round()}m';

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      generationtimeMs: (json['generationtime_ms'] as num).toDouble(),
      utcOffsetSeconds: json['utc_offset_seconds'] ?? 0,
      timezone: json['timezone'] ?? '',
      timezoneAbbreviation: json['timezone_abbreviation'] ?? '',
      elevation: (json['elevation'] as num).toDouble(),
      currentWeatherUnits: WeatherUnits.fromJson(json['current_weather_units']),
      currentWeather: CurrentWeather.fromJson(json['current_weather']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'generationtime_ms': generationtimeMs,
      'utc_offset_seconds': utcOffsetSeconds,
      'timezone': timezone,
      'timezone_abbreviation': timezoneAbbreviation,
      'elevation': elevation,
      'current_weather_units': currentWeatherUnits.toJson(),
      'current_weather': currentWeather.toJson(),
    };
  }
} 