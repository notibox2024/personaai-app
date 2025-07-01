import 'package:logger/logger.dart';

import 'firebase_service.dart';
import 'api_service.dart';
import 'token_manager.dart';
import 'device_info_service.dart';
import 'performance_monitor.dart';
import 'app_lifecycle_service.dart';
import 'weather_service.dart';
import 'notification_demo_service.dart';

/// Global coordination for infrastructure services
class GlobalServices {
  static final Logger _logger = Logger();
  static bool _initialized = false;

  /// Initialize all infrastructure services in proper order
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logger.i('🚀 Initializing global infrastructure services...');
      
      // Core infrastructure (order matters)
      await FirebaseService().initialize();
      await DeviceInfoService().initialize();
      await TokenManager().initialize();
      await PerformanceMonitor().initialize();
      
      // Network layer with proper configuration
      ApiService().initialize(
        baseUrl: 'https://api.personaai.com', // Thay đổi theo API thực tế của bạn
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 5),
      );
      
      // Feature support services
      await AppLifecycleService().initialize();
      
      // Services without initialize() method - just ensure they're created
      WeatherService(); // Singleton creation
      NotificationDemoService(); // Singleton creation
      
      _initialized = true;
      _logger.i('✅ Global services initialized successfully');
      
    } catch (e) {
      _logger.e('❌ Global services initialization failed: $e');
      rethrow;
    }
  }

  /// Dispose all global services
  static Future<void> dispose() async {
    try {
      AppLifecycleService().dispose();
      // Add other disposals as needed
      _initialized = false;
      _logger.i('✅ Global services disposed');
    } catch (e) {
      _logger.e('❌ Global services disposal error: $e');
    }
  }

  /// Check if global services are initialized
  static bool get isInitialized => _initialized;

  // Quick access to common services (optional)
  static FirebaseService get firebase => FirebaseService();
  static ApiService get api => ApiService();
  static TokenManager get tokenManager => TokenManager();
  static DeviceInfoService get deviceInfo => DeviceInfoService();
  static PerformanceMonitor get performanceMonitor => PerformanceMonitor();
} 