// Import dart:math for calculations
import 'dart:math' as math;

/// Enum cho trạng thái validation vị trí
enum LocationValidationStatus {
  valid('Hợp lệ'),
  invalid('Không hợp lệ'),
  warning('Cảnh báo'),
  checking('Đang kiểm tra');

  const LocationValidationStatus(this.displayName);
  final String displayName;
}

/// Model cho dữ liệu vị trí
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? address;
  final String? wifiSSID;
  final bool isInOfficeRadius;
  final bool isOfficeWifi;
  final LocationValidationStatus validationStatus;
  final String? validationMessage;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.address,
    this.wifiSSID,
    required this.isInOfficeRadius,
    required this.isOfficeWifi,
    required this.validationStatus,
    this.validationMessage,
    required this.timestamp,
  });

  /// Tính khoảng cách đến văn phòng (giả định văn phòng ở tọa độ cố định)
  double get distanceToOffice {
    // Tọa độ văn phòng mẫu (có thể config từ server)
    const double officeLat = 10.7769;
    
    // Tính khoảng cách theo công thức Haversine (đơn giản hóa)
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(officeLat - latitude);
    
    final double a = 
        (dLat / 2) * (dLat / 2) +
        (longitude * longitude) * (dLat / 2) * (dLat / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  /// Format khoảng cách
  String get distanceString {
    final distance = distanceToOffice;
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Format tọa độ hiển thị
  String get coordinatesString {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Format accuracy
  String get accuracyString {
    return '±${accuracy.round()}m';
  }

  /// Kiểm tra validation tổng thể
  bool get isValid => validationStatus == LocationValidationStatus.valid;

  /// Message hiển thị cho user
  String get displayMessage {
    if (validationMessage != null) return validationMessage!;
    
    switch (validationStatus) {
      case LocationValidationStatus.valid:
        return isOfficeWifi 
            ? 'Đang trong WiFi văn phòng'
            : 'Vị trí hợp lệ - $distanceString từ văn phòng';
      case LocationValidationStatus.invalid:
        return 'Vị trí không hợp lệ - $distanceString từ văn phòng';
      case LocationValidationStatus.warning:
        return 'Cảnh báo vị trí - $distanceString từ văn phòng';
      case LocationValidationStatus.checking:
        return 'Đang xác định vị trí...';
    }
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      address: json['address'],
      wifiSSID: json['wifiSSID'],
      isInOfficeRadius: json['isInOfficeRadius'] ?? false,
      isOfficeWifi: json['isOfficeWifi'] ?? false,
      validationStatus: LocationValidationStatus.values.firstWhere(
        (e) => e.name == json['validationStatus'],
        orElse: () => LocationValidationStatus.checking,
      ),
      validationMessage: json['validationMessage'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
      'wifiSSID': wifiSSID,
      'isInOfficeRadius': isInOfficeRadius,
      'isOfficeWifi': isOfficeWifi,
      'validationStatus': validationStatus.name,
      'validationMessage': validationMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    String? wifiSSID,
    bool? isInOfficeRadius,
    bool? isOfficeWifi,
    LocationValidationStatus? validationStatus,
    String? validationMessage,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      isInOfficeRadius: isInOfficeRadius ?? this.isInOfficeRadius,
      isOfficeWifi: isOfficeWifi ?? this.isOfficeWifi,
      validationStatus: validationStatus ?? this.validationStatus,
      validationMessage: validationMessage ?? this.validationMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 