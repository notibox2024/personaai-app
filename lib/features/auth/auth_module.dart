import '../../shared/core/feature_module.dart';
import 'auth_provider.dart';
import 'data/services/auth_service.dart';

/// Auth Feature Module
/// Organizes auth-related services and provides public interface
class AuthModule extends FeatureModule with SingletonFeatureModule<AuthModule> {
  static AuthModule? _instance;
  bool _initialized = false;

  /// Singleton instance getter
  static AuthModule get instance {
    return _instance ??= AuthModule._internal();
  }

  AuthModule._internal();

  @override
  String get featureName => 'auth';

  @override
  bool get isInitialized => _initialized;

  // Feature-scoped service getters (internal singletons)
  AuthService get authService => AuthService();

  /// Public interface for other features
  AuthProvider get provider => authService;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      logInfo('Initializing auth module...');
      
      // Initialize auth services
      await authService.initialize();
      
      _initialized = true;
      logInfo('Auth module initialized successfully');
      
    } catch (e) {
      logError('Auth module initialization failed', e);
      rethrow;
    }
  }

  @override
  void dispose() {
    try {
      logInfo('Disposing auth module...');
      
      // Dispose services if they have dispose methods
      // AuthService is singleton, disposal is handled by its own lifecycle
      
      _initialized = false;
      logInfo('Auth module disposed');
      
    } catch (e) {
      logError('Auth module disposal error', e);
    }
  }

  /// For testing - reset module state
  static void resetForTesting() {
    _instance?._initialized = false;
    _instance = null;
  }
} 