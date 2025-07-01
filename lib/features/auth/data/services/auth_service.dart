import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/auth_state.dart';
import '../models/login_request.dart';
import '../models/user_session.dart';
import '../repositories/auth_repository.dart';
import '../../../../shared/services/token_manager.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/constants/remote_config_keys.dart';

/// Service quản lý authentication state và auto-refresh logic
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Use getters instead of late final to avoid initialization conflicts
  AuthRepository get _authRepository => AuthRepository();
  TokenManager get _tokenManager => TokenManager();
  final logger = Logger();
  
  // State management
  final StreamController<AuthStateData> _authStateController = StreamController<AuthStateData>.broadcast();
  AuthStateData _currentState = AuthStateData.initial();
  
  // Auto-refresh timer
  Timer? _refreshTimer;
  bool _isInitialized = false;

  /// Stream of authentication state changes
  Stream<AuthStateData> get authStateStream => _authStateController.stream;
  
  /// Current authentication state
  AuthStateData get currentState => _currentState;
  
  /// Initialize AuthService
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('AuthService already initialized');
      return;
    }
    
    try {
      // Initialize repository (getter will create new instance if needed)
      await _authRepository.initialize();
      
      // Check existing authentication
      await _checkExistingAuth();
      
      // Start auto-refresh timer
      _startAutoRefreshTimer();
      
      _isInitialized = true;
      logger.i('AuthService initialized');
    } catch (e) {
      logger.e('AuthService initialization failed: $e');
      _updateState(AuthStateData.error('Failed to initialize auth service'));
    }
  }

  /// Check for existing authentication on app start
  Future<void> _checkExistingAuth() async {
    try {
      if (_authRepository.isLoggedIn) {
        final session = _authRepository.currentSession;
        if (session != null) {
          _updateState(AuthStateData.authenticated(session));
          logger.i('Existing authentication found for user: ${session.userId}');
          
          // Check if token needs refresh
          final shouldRefresh = await _authRepository.shouldAutoRefresh();
          if (shouldRefresh) {
            await _performTokenRefresh();
          }
        } else {
          _updateState(AuthStateData.unauthenticated());
        }
      } else {
        _updateState(AuthStateData.unauthenticated());
      }
    } catch (e) {
      logger.e('Error checking existing auth: $e');
      _updateState(AuthStateData.unauthenticated());
    }
  }

  /// Login with credentials
  Future<void> login(LoginRequest request) async {
    try {
      _updateState(AuthStateData.refreshing(_currentState.user));
      
      final result = await _authRepository.login(request);
      
      if (result.success && result.data != null) {
        final session = _authRepository.currentSession;
        if (session != null) {
          _updateState(AuthStateData.authenticated(session));
          logger.i('Login successful for user: ${request.username}');
        } else {
          _updateState(AuthStateData.error('Session creation failed'));
        }
      } else {
        _updateState(AuthStateData.error(result.error ?? 'Login failed'));
        logger.w('Login failed: ${result.error}');
      }
    } catch (e) {
      logger.e('Login error: $e');
      _updateState(AuthStateData.error('Login error: ${e.toString()}'));
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _updateState(AuthStateData.refreshing(_currentState.user));
      
      final result = await _authRepository.logout();
      
      _stopAutoRefreshTimer();
      _updateState(AuthStateData.unauthenticated());
      
      if (result.success) {
        logger.i('Logout successful');
      } else {
        logger.w('Logout had issues: ${result.error}');
      }
    } catch (e) {
      logger.e('Logout error: $e');
      // Still update to unauthenticated state
      _updateState(AuthStateData.unauthenticated());
    }
  }

  /// Refresh authentication token
  Future<bool> refreshToken() async {
    try {
      if (!_authRepository.isLoggedIn) {
        logger.w('Cannot refresh token: not logged in');
        return false;
      }

      final result = await _authRepository.refreshToken();
      
      if (result.success) {
        final session = _authRepository.currentSession;
        if (session != null) {
          _updateState(AuthStateData.authenticated(session));
          logger.i('Token refresh successful');
          return true;
        }
      } else {
        logger.w('Token refresh failed: ${result.error}');
        await logout(); // Force logout on refresh failure
      }
      
      return false;
    } catch (e) {
      logger.e('Token refresh error: $e');
      await logout(); // Force logout on error
      return false;
    }
  }

  /// Perform token refresh internally
  Future<void> _performTokenRefresh() async {
    if (_currentState.state == AuthState.refreshing) {
      return; // Already refreshing
    }
    
    try {
      _updateState(AuthStateData.refreshing(_currentState.user));
      final success = await refreshToken();
      
      if (!success) {
        logger.w('Auto token refresh failed');
      }
    } catch (e) {
      logger.e('Auto token refresh error: $e');
    }
  }

  /// Start auto-refresh timer
  void _startAutoRefreshTimer() {
    _stopAutoRefreshTimer(); // Stop existing timer
    
    if (!FirebaseService().getConfigBool(RemoteConfigKeys.enableAutoRefresh, defaultValue: true)) {
      logger.d('Auto refresh disabled via remote config');
      return;
    }
    
    // Check every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_authRepository.isLoggedIn) {
        final shouldRefresh = await _authRepository.shouldAutoRefresh();
        if (shouldRefresh) {
          logger.d('Auto refresh triggered');
          await _performTokenRefresh();
        }
      } else {
        logger.d('Auto refresh skipped: not logged in');
      }
    });
    
    logger.d('Auto-refresh timer started');
  }

  /// Stop auto-refresh timer
  void _stopAutoRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    logger.d('Auto-refresh timer stopped');
  }

  /// Update authentication state
  void _updateState(AuthStateData newState) {
    _currentState = newState;
    _authStateController.add(newState);
    
    if (kDebugMode) {
      logger.d('Auth state updated: ${newState.state}');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentState.isAuthenticated;
  
  /// Check if authentication is loading
  bool get isLoading => _currentState.isLoading;
  
  /// Get current user session
  UserSession? get currentUser => _currentState.user;
  
  /// Get authentication error
  String? get authError => _currentState.error;

  /// Validate current token
  Future<bool> validateToken() async {
    try {
      final response = await _authRepository.validateToken();
      return response.valid;
    } catch (e) {
      logger.e('Token validation error: $e');
      return false;
    }
  }

  /// Force refresh token
  Future<bool> forceRefreshToken() async {
    logger.i('Force token refresh requested');
    return await refreshToken();
  }

  /// Get authentication status
  Future<AuthStatus> getAuthStatus() async {
    return await _authRepository.getAuthStatus();
  }

  /// Check if token is about to expire
  Future<bool> isTokenNearExpiry() async {
    return await _tokenManager.shouldRefreshToken();
  }

  /// Get token time remaining
  Future<Duration?> getTokenTimeRemaining() async {
    return await _tokenManager.getTokenTimeRemaining();
  }

  /// Listen to authentication state changes
  StreamSubscription<AuthStateData> listenToAuthChanges(
    void Function(AuthStateData state) onAuthChanged
  ) {
    return _authStateController.stream.listen(onAuthChanged);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _stopAutoRefreshTimer();
    await _authStateController.close();
    _isInitialized = false;
    logger.i('AuthService disposed');
  }

  /// Debug: Print current auth state
  void debugCurrentState() {
    if (!kDebugMode) return;
    
    logger.d('=== AUTH SERVICE DEBUG ===');
    logger.d('State: ${_currentState.state}');
    logger.d('User: ${_currentState.user?.userId}');
    logger.d('Error: ${_currentState.error}');
    logger.d('Is Authenticated: $isAuthenticated');
    logger.d('Is Loading: $isLoading');
    logger.d('Auto-refresh Timer: ${_refreshTimer != null ? 'Active' : 'Inactive'}');
    logger.d('==========================');
  }
} 