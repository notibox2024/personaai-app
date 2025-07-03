import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'firebase_service.dart';
import 'api_service.dart';
import 'token_manager.dart';
import 'device_info_service.dart';
import 'performance_monitor.dart';
import 'app_lifecycle_service.dart';
import 'weather_service.dart';
import 'notification_demo_service.dart';
import 'navigation_service.dart';
import '../../features/auth/data/services/fcm_token_service.dart';

/// Global services initializer và coordinator
/// Setup các services và wire up callbacks giữa chúng
class GlobalServices {
  static final GlobalServices _instance = GlobalServices._internal();
  factory GlobalServices() => _instance;
  GlobalServices._internal();

  final logger = Logger();
  bool _isInitialized = false;
  bool _isHandlingAuthRequired = false; // Flag để tránh multiple auth dialogs

  /// Initialize all global services và setup callbacks
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('GlobalServices already initialized');
      return;
    }

    try {
      logger.i('Initializing global services...');

      // Initialize core services first
      await _initializeCoreServices();
      
      // Setup service callbacks
      _setupServiceCallbacks();
      
      _isInitialized = true;
      logger.i('Global services initialized successfully');
    } catch (e) {
      logger.e('GlobalServices initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize core services trong order phù hợp
  Future<void> _initializeCoreServices() async {
    // 1. FirebaseService - cần setup sau Firebase.initializeApp() từ main.dart
    await FirebaseService().initialize();
    logger.d('✓ FirebaseService initialized');

    // 2. DeviceInfoService - cần explicit initialize cho connectivity
    await DeviceInfoService().initialize();
    logger.d('✓ DeviceInfoService initialized');

    // 3. TokenManager - cần có trước để ApiService có thể sử dụng
    await TokenManager().initialize();
    logger.d('✓ TokenManager initialized');

    // 4. ApiService - phụ thuộc vào các services trên
    await ApiService().initialize();
    logger.d('✓ ApiService initialized');

    // 5. NavigationService - ready to use
    // NavigationService không cần explicit initialization
    logger.d('✓ NavigationService ready');
  }

  /// Setup callbacks giữa các services
  void _setupServiceCallbacks() {
    logger.d('Setting up service callbacks...');
    
    // Setup ApiService auth required callback
    ApiService().setAuthRequiredCallback(() {
      _handleAuthRequired();
    });
    
    // Setup FCM token refresh listener
    FcmTokenService().setupTokenRefreshListener();
    
    logger.d('✓ Service callbacks configured');
    logger.d('✓ FCM token refresh listener setup');
  }

  /// Handle khi ApiService require authentication
  Future<void> _handleAuthRequired() async {
    // Tránh multiple auth dialogs
    if (_isHandlingAuthRequired) {
      logger.d('Already handling auth required - skipping');
      return;
    }
    
    try {
      _isHandlingAuthRequired = true;
      logger.w('Authentication required - navigating to login');
      
      // Show dialog trước khi navigate (user-friendly)
      await NavigationService().showAuthRequiredDialog();
      
    } catch (e) {
      logger.e('Error handling auth required: $e');
      
      // Fallback - direct navigate
      await NavigationService().navigateToLogin();
    } finally {
      // Reset flag sau 5 giây để cho phép retry nếu cần
      Future.delayed(const Duration(seconds: 5), () {
        _isHandlingAuthRequired = false;
      });
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Reset auth required flag để tránh loop
  void resetAuthRequiredFlag() {
    _isHandlingAuthRequired = false;
    logger.d('Auth required flag reset');
  }

  /// Dispose all services (for testing hoặc app shutdown)
  Future<void> dispose() async {
    try {
      logger.i('Disposing global services...');
      
      // Clear callbacks
      ApiService().setAuthRequiredCallback(null);
      
      // Note: Các services khác có thể có dispose methods riêng
      // nhưng thường không cần dispose vì chúng là singletons
      
      _isInitialized = false;
      logger.i('Global services disposed');
    } catch (e) {
      logger.e('Error disposing global services: $e');
    }
  }

  /// Debug current services state
  void debugServicesState() {
    if (!kDebugMode) return;
    
    logger.d('=== GLOBAL SERVICES DEBUG ===');
    logger.d('Is Initialized: $_isInitialized');
    logger.d('TokenManager: ${TokenManager()}');
    logger.d('ApiService: ${ApiService()}');
    logger.d('NavigationService: ${NavigationService()}');
    logger.d('=============================');
  }

  // Quick access to common services (optional)
  static FirebaseService get firebase => FirebaseService();
  static ApiService get api => ApiService();
  static TokenManager get tokenManager => TokenManager();
  static DeviceInfoService get deviceInfo => DeviceInfoService();
  static PerformanceMonitor get performanceMonitor => PerformanceMonitor();
} 