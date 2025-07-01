import 'package:logger/logger.dart';

/// Abstract base class for all feature modules
/// Provides structure for feature-scoped service organization
abstract class FeatureModule {
  final Logger _logger = Logger();
  
  /// Unique name for this feature module
  String get featureName;
  
  /// Whether this module has been initialized
  bool get isInitialized;
  
  /// Initialize all services in this feature module
  Future<void> initialize();
  
  /// Dispose all services in this feature module
  void dispose();
  
  /// Log helper for feature modules
  void logInfo(String message) {
    _logger.i('[$featureName] $message');
  }
  
  void logError(String message, [dynamic error]) {
    _logger.e('[$featureName] $message', error: error);
  }
  
  void logWarning(String message) {
    _logger.w('[$featureName] $message');
  }
}

/// Mixin for modules that need singleton instance management
mixin SingletonFeatureModule<T extends FeatureModule> on FeatureModule {
  static final Map<Type, FeatureModule> _instances = {};
  
  /// Get singleton instance of this feature module
  static T getInstance<T extends FeatureModule>(T Function() factory) {
    return _instances.putIfAbsent(T, factory) as T;
  }
  
  /// Clear singleton instance (for testing)
  static void clearInstance<T extends FeatureModule>() {
    _instances.remove(T);
  }
  
  /// Clear all instances (for testing)
  static void clearAllInstances() {
    _instances.clear();
  }
} 