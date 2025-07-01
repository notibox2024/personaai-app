import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';
import '../constants/remote_config_keys.dart';

/// Service thu thập thông tin thiết bị cho custom headers
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  late final DeviceInfoPlugin _deviceInfo;
  late final NetworkInfo _networkInfo;
  late final Connectivity _connectivity;
  late final SharedPreferences _prefs;
  final logger = Logger();

  // Cached values (initialized once)
  String? _deviceModel;
  String? _osVersion;
  String? _deviceId;
  String? _brand;
  String? _appVersion;
  String? _buildNumber;
  String? _bundleId;
  String? _sessionId;

  // Constants
  static const String _deviceIdKey = 'cached_device_id';
  static const String _deviceIdSalt = 'personaai_device_salt_2024';

  /// Initialize DeviceInfoService
  Future<void> initialize() async {
    try {
      _deviceInfo = DeviceInfoPlugin();
      _networkInfo = NetworkInfo();
      _connectivity = Connectivity();
      _prefs = await SharedPreferences.getInstance();

      // Generate session ID
      _sessionId = const Uuid().v4();

      // Cache static device information
      await _cacheDeviceInfo();
      await _cacheAppInfo();

      if (kDebugMode) {
        logger.i('DeviceInfoService initialized');
        logger.i('Session ID: $_sessionId');
      }
    } catch (e) {
      logger.e('Error initializing DeviceInfoService: $e');
      rethrow;
    }
  }

  /// Cache device information
  Future<void> _cacheDeviceInfo() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;
        _osVersion = iosInfo.systemVersion;
        _brand = 'Apple';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceModel = androidInfo.model;
        _osVersion = androidInfo.version.release;
        _brand = androidInfo.brand;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        _deviceModel = windowsInfo.computerName;
        _osVersion = windowsInfo.displayVersion;
        _brand = 'Microsoft';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        _deviceModel = macInfo.model;
        _osVersion = macInfo.osRelease;
        _brand = 'Apple';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        _deviceModel = linuxInfo.name;
        _osVersion = linuxInfo.version ?? 'Unknown';
        _brand = 'Linux';
      } else {
        _deviceModel = 'Unknown';
        _osVersion = 'Unknown';
        _brand = 'Unknown';
      }

      // Generate and cache device ID
      _deviceId = await _getOrCreateDeviceId();

    } catch (e) {
      logger.e('Error caching device info: $e');
      // Set fallback values
      _deviceModel = 'Unknown';
      _osVersion = 'Unknown';
      _brand = 'Unknown';
      _deviceId = await _generateFallbackDeviceId();
    }
  }

  /// Cache app information
  Future<void> _cacheAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _bundleId = packageInfo.packageName;
    } catch (e) {
      logger.e('Error caching app info: $e');
      // Set fallback values
      _appVersion = '1.0.0';
      _buildNumber = '1';
      _bundleId = 'com.unknown.app';
    }
  }

  /// Get or create device ID
  Future<String> _getOrCreateDeviceId() async {
    try {
      // 1. Try to get OS device ID
      String? osDeviceId = await _getOSDeviceId();
      
      // 2. Check cached ID
      String? cachedId = await _getCachedDeviceId();
      
      // 3. Validate consistency
      if (osDeviceId != null && cachedId != null) {
        String hashedOsId = _hashDeviceId(osDeviceId);
        if (hashedOsId != cachedId) {
          // OS ID changed, update cache
          await _cacheDeviceId(hashedOsId);
          FirebaseService().log('Device ID changed: OS ID updated');
          return hashedOsId;
        }
        return cachedId;
      }
      
      // 4. Create new ID if needed
      if (osDeviceId != null) {
        String hashedId = _hashDeviceId(osDeviceId);
        await _cacheDeviceId(hashedId);
        return hashedId;
      }
      
      // 5. Fallback to UUID
      if (cachedId != null) return cachedId;
      
      String fallbackId = _generateFallbackId();
      String hashedFallback = _hashDeviceId(fallbackId);
      await _cacheDeviceId(hashedFallback);
      FirebaseService().log('Device ID fallback generated');
      
      return hashedFallback;
      
    } catch (e) {
      // 6. Emergency fallback
      String emergencyId = 'emergency_${DateTime.now().millisecondsSinceEpoch}';
      return _hashDeviceId(emergencyId);
    }
  }

  /// Get OS device ID
  Future<String?> _getOSDeviceId() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      }
      return null;
    } catch (e) {
      logger.e('Error getting OS device ID: $e');
      return null;
    }
  }

  /// Generate fallback device ID
  String _generateFallbackId() {
    final uuid = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${uuid}_$timestamp';
  }

  /// Generate emergency fallback device ID
  Future<String> _generateFallbackDeviceId() async {
    final fallbackId = _generateFallbackId();
    final hashedId = _hashDeviceId(fallbackId);
    await _cacheDeviceId(hashedId);
    return hashedId;
  }

  /// Hash device ID với SHA-256
  String _hashDeviceId(String deviceId) {
    final bytes = utf8.encode(deviceId + _deviceIdSalt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Cache device ID trong SharedPreferences
  Future<void> _cacheDeviceId(String deviceId) async {
    try {
      await _prefs.setString(_deviceIdKey, deviceId);
    } catch (e) {
      logger.e('Error caching device ID: $e');
    }
  }

  /// Get cached device ID
  Future<String?> _getCachedDeviceId() async {
    try {
      return _prefs.getString(_deviceIdKey);
    } catch (e) {
      logger.e('Error getting cached device ID: $e');
      return null;
    }
  }

  /// Check if should include location headers
  bool _shouldIncludeLocationHeaders() {
    try {
      return FirebaseService().getConfigBool(RemoteConfigKeys.enableLocationHeaders, defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  /// Get device headers
  Future<Map<String, String>> getDeviceHeaders() async {
    try {
      if (!FirebaseService().getConfigBool(RemoteConfigKeys.enableDeviceHeaders, defaultValue: true)) {
        return {};
      }

      return {
        'X-Device-Platform': Platform.operatingSystem,
        if (_deviceModel != null) 'X-Device-Model': _deviceModel!,
        if (_osVersion != null) 'X-Device-OS-Version': _osVersion!,
        if (_deviceId != null) 'X-Device-ID': _deviceId!,
        if (_brand != null) 'X-Device-Brand': _brand!,
      };
    } catch (e) {
      logger.e('Error getting device headers: $e');
      return {};
    }
  }

  /// Get network headers
  Future<Map<String, String>> getNetworkHeaders() async {
    try {
      if (!FirebaseService().getConfigBool(RemoteConfigKeys.enableNetworkHeaders, defaultValue: true)) {
        return {};
      }

      final headers = <String, String>{};

      // Network type
      final connectivityResults = await _connectivity.checkConnectivity();
      final primaryResult = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
      headers['X-Network-Type'] = _mapConnectivityResult(primaryResult);

      // Network IP (if enabled)
      if (FirebaseService().getConfigBool(RemoteConfigKeys.enableIpTracking, defaultValue: false)) {
        try {
          final wifiIP = await _networkInfo.getWifiIP();
          if (wifiIP != null) {
            headers['X-Network-IP'] = wifiIP;
          }
        } catch (e) {
          // Ignore network IP errors
        }
      }

      // WiFi name (if location headers enabled)
      if (_shouldIncludeLocationHeaders() && primaryResult == ConnectivityResult.wifi) {
        try {
          final wifiName = await _networkInfo.getWifiName();
          if (wifiName != null && wifiName.isNotEmpty) {
            headers['X-Network-Wifi-Name'] = wifiName;
          }
        } catch (e) {
          // Ignore WiFi name errors
        }
      }

      return headers;
    } catch (e) {
      logger.e('Error getting network headers: $e');
      return {};
    }
  }

  /// Map connectivity result to string
  String _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'mobile';
      case ConnectivityResult.ethernet:
        return 'ethernet';
      case ConnectivityResult.vpn:
        return 'vpn';
      case ConnectivityResult.other:
        return 'other';
      case ConnectivityResult.none:
        return 'none';
      default:
        return 'unknown';
    }
  }

  /// Get app headers
  Future<Map<String, String>> getAppHeaders() async {
    try {
      final environment = kDebugMode ? 'development' : 'production';
      
      return {
        if (_appVersion != null) 'X-App-Version': _appVersion!,
        if (_buildNumber != null) 'X-App-Build': _buildNumber!,
        'X-App-Environment': environment,
        if (_bundleId != null) 'X-App-Bundle-ID': _bundleId!,
      };
    } catch (e) {
      logger.e('Error getting app headers: $e');
      return {};
    }
  }

  /// Get user context headers
  Future<Map<String, String>> getUserContextHeaders() async {
    try {
      final locale = Platform.localeName;
      final timezone = DateTime.now().timeZoneName;
      final userAgent = _buildUserAgent();

      return {
        'X-User-Agent': userAgent,
        'X-User-Language': locale,
        'X-User-Timezone': timezone,
      };
    } catch (e) {
      logger.e('Error getting user context headers: $e');
      return {};
    }
  }

  /// Build custom user agent string
  String _buildUserAgent() {
    final appName = 'PersonaAI';
    final version = _appVersion ?? '1.0.0';
    final platform = Platform.operatingSystem;
    final osVersion = _osVersion ?? 'Unknown';
    final deviceModel = _deviceModel ?? 'Unknown';
    
    return '$appName/$version ($platform $osVersion; $deviceModel) Flutter/3.16.0';
  }

  /// Get session headers
  Future<Map<String, String>> getSessionHeaders() async {
    try {
      final requestId = const Uuid().v4();
      final timestamp = DateTime.now().toIso8601String();

      return {
        if (_sessionId != null) 'X-Session-ID': _sessionId!,
        'X-Request-ID': requestId,
        'X-Request-Timestamp': timestamp,
      };
    } catch (e) {
      logger.e('Error getting session headers: $e');
      return {};
    }
  }

  /// Get all headers
  Future<Map<String, String>> getAllHeaders() async {
    try {
      final headers = <String, String>{};
      
      // Collect all headers in parallel
      final futures = await Future.wait([
        getDeviceHeaders(),
        getNetworkHeaders(),
        getAppHeaders(),
        getUserContextHeaders(),
        getSessionHeaders(),
      ]);

      // Merge all headers
      for (final headerMap in futures) {
        headers.addAll(headerMap);
      }

      if (kDebugMode) {
        logger.d('Generated ${headers.length} custom headers');
      }

      return headers;
    } catch (e) {
      logger.e('Error getting all headers: $e');
      return {};
    }
  }

  /// Debug: Print all headers (debug mode only)
  Future<void> debugHeaders() async {
    if (!kDebugMode) return;

    try {
      final headers = await getAllHeaders();
      logger.d('Custom Headers:');
      headers.forEach((key, value) {
        logger.d('  $key: $value');
      });
    } catch (e) {
      logger.e('Error debugging headers: $e');
    }
  }
} 