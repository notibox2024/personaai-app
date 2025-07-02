import 'package:logger/logger.dart';

import 'shared/services/global_services.dart';
import 'features/auth/auth_module.dart';

/// Central coordinator for all application modules and services
class AppModules {
  static final Logger _logger = Logger();
  static bool _initialized = false;

  /// Initialize all modules in proper order
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.i('🚀 Initializing application modules...');

      // Phase 1: Initialize global infrastructure services
      await GlobalServices().initialize();

      // Phase 2: Initialize feature modules
      await AuthModule.instance.initialize();
      
      // Add other feature modules here as they're created:
      // await HomeModule.instance.initialize();
      // await NotificationModule.instance.initialize();
      // await ProfileModule.instance.initialize();

      _initialized = true;
      _logger.i('✅ All application modules initialized successfully');

    } catch (e) {
      _logger.e('❌ Application modules initialization failed: $e');
      rethrow;
    }
  }

  /// Dispose all modules
  static Future<void> dispose() async {
    try {
      _logger.i('🔄 Disposing application modules...');

      // Dispose feature modules first
      AuthModule.instance.dispose();
      
      // Then dispose global services
      await GlobalServices().dispose();

      _initialized = false;
      _logger.i('✅ All application modules disposed');

    } catch (e) {
      _logger.e('❌ Application modules disposal error: $e');
    }
  }

  /// Check if all modules are initialized
  static bool get isInitialized => _initialized;

  /// Reset for testing
  static void resetForTesting() {
    _initialized = false;
    AuthModule.resetForTesting();
    // Add other module resets as needed
  }
} 