import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service xử lý location và permissions cho chức năng chấm công
class LocationService {
  static const double _accuracyThreshold = 100.0; // 100 mét
  
  /// Kiểm tra và yêu cầu quyền truy cập vị trí
  static Future<bool> requestLocationPermission() async {
    try {
      // Kiểm tra xem location service có được bật không
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location service chưa được bật
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Quyền bị từ chối vĩnh viễn, cần mở settings
        return false;
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Lấy vị trí hiện tại với độ chính xác cao
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra xem vị trí hiện tại có trong phạm vi cho phép chấm công không
  static bool isWithinAllowedRange(
    Position currentPosition,
    double targetLatitude,
    double targetLongitude,
    {double radiusInMeters = 100.0}
  ) {
    double distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );

    return distance <= radiusInMeters;
  }

  /// Tính khoảng cách từ vị trí hiện tại đến địa điểm làm việc
  static double calculateDistanceToWorkplace(
    Position currentPosition,
    double workplaceLatitude,
    double workplaceLongitude,
  ) {
    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      workplaceLatitude,
      workplaceLongitude,
    );
  }

  /// Kiểm tra độ chính xác của vị trí có đủ tốt không
  static bool isLocationAccurate(Position position) {
    return position.accuracy <= _accuracyThreshold;
  }

  /// Mở cài đặt location
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Mở cài đặt app để cấp quyền
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Lấy thông tin địa chỉ từ tọa độ (nếu cần)
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // TODO: Implement reverse geocoding nếu cần
      // Có thể sử dụng package geocoding hoặc Google Maps API
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      return 'Không xác định được địa chỉ';
    }
  }

  /// Kiểm tra trạng thái quyền location
  static Future<LocationPermissionStatus> getLocationPermissionStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      default:
        return LocationPermissionStatus.denied;
    }
  }
}

/// Enum cho trạng thái quyền location
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  serviceDisabled,
}

/// Model cho thông tin location của workplace
class WorkplaceLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final String address;

  const WorkplaceLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 100.0,
    required this.address,
  });

  factory WorkplaceLocation.fromJson(Map<String, dynamic> json) {
    return WorkplaceLocation(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radiusInMeters: json['radiusInMeters']?.toDouble() ?? 100.0,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'address': address,
    };
  }
}

/// Model cho check-in location
class CheckInLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String address;

  const CheckInLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.address,
  });

  factory CheckInLocation.fromPosition(Position position, String address) {
    return CheckInLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
      address: address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
    };
  }
} 