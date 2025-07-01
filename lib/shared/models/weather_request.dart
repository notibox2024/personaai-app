/// Model for weather API request
class WeatherRequest {
  final double latitude;
  final double longitude;
  final bool currentWeather;
  final String timezone;
  final String temperatureUnit;
  final String windspeedUnit;
  final String precipitationUnit;

  const WeatherRequest({
    required this.latitude,
    required this.longitude,
    this.currentWeather = true,
    this.timezone = 'auto',
    this.temperatureUnit = 'celsius',
    this.windspeedUnit = 'kmh',
    this.precipitationUnit = 'mm',
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'currentWeather': currentWeather,
      'timezone': timezone,
      'temperatureUnit': temperatureUnit,
      'windspeedUnit': windspeedUnit,
      'precipitationUnit': precipitationUnit,
    };
  }

  /// Create from JSON
  factory WeatherRequest.fromJson(Map<String, dynamic> json) {
    return WeatherRequest(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      currentWeather: json['currentWeather'] as bool? ?? true,
      timezone: json['timezone'] as String? ?? 'auto',
      temperatureUnit: json['temperatureUnit'] as String? ?? 'celsius',
      windspeedUnit: json['windspeedUnit'] as String? ?? 'kmh',
      precipitationUnit: json['precipitationUnit'] as String? ?? 'mm',
    );
  }

  /// Copy with new values
  WeatherRequest copyWith({
    double? latitude,
    double? longitude,
    bool? currentWeather,
    String? timezone,
    String? temperatureUnit,
    String? windspeedUnit,
    String? precipitationUnit,
  }) {
    return WeatherRequest(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currentWeather: currentWeather ?? this.currentWeather,
      timezone: timezone ?? this.timezone,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      windspeedUnit: windspeedUnit ?? this.windspeedUnit,
      precipitationUnit: precipitationUnit ?? this.precipitationUnit,
    );
  }

  @override
  String toString() {
    return 'WeatherRequest(lat: $latitude, lng: $longitude, temp: $temperatureUnit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherRequest &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.currentWeather == currentWeather &&
        other.timezone == timezone &&
        other.temperatureUnit == temperatureUnit &&
        other.windspeedUnit == windspeedUnit &&
        other.precipitationUnit == precipitationUnit;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      currentWeather,
      timezone,
      temperatureUnit,
      windspeedUnit,
      precipitationUnit,
    );
  }
}

/// Temperature unit constants
class TemperatureUnit {
  static const String celsius = 'celsius';
  static const String fahrenheit = 'fahrenheit';
}

/// Wind speed unit constants
class WindSpeedUnit {
  static const String kmh = 'kmh';
  static const String ms = 'ms';
  static const String mph = 'mph';
  static const String kn = 'kn';
}

/// Precipitation unit constants
class PrecipitationUnit {
  static const String mm = 'mm';
  static const String inch = 'inch';
} 