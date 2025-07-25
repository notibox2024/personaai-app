import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/auth_state.dart';
import '../models/login_request.dart';
import '../models/user_session.dart';
import '../repositories/auth_repository.dart';
import 'user_profile_service.dart';
import '../../../../shared/services/token_manager.dart';
import '../../auth_provider.dart';

/// Service quản lý authentication state và auto-refresh logic
class AuthService implements AuthProvider {
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
  
  bool _isInitialized = false;

  /// Stream of authentication state changes
  @override
  Stream<AuthStateData> get authStateStream => _authStateController.stream;
  
  /// Current authentication state
  AuthStateData get currentState => _currentState;

  // AuthProvider interface implementation
  @override
  bool get isAuthenticated => _currentState.isAuthenticated;

  @override
  UserSession? get currentUser => _currentState.user;



  @override
  Future<bool> login(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      await _performLogin(request);
      return isAuthenticated;
    } catch (e) {
      logger.e('AuthProvider login error: $e');
      return false;
    }
  }

  /// Login with remember me option
  Future<bool> loginWithRememberMe(String username, String password, bool rememberMe) async {
    try {
      final request = LoginRequest(username: username, password: password);
      await _performLogin(request);
      
      // Save credentials if remember me is enabled
      if (isAuthenticated && rememberMe) {
        await _tokenManager.saveCredentials(
          username: username,
          password: password,
        );
        logger.i('Credentials saved for remember me');
      } else if (isAuthenticated && !rememberMe) {
        // Clear saved credentials if remember me is disabled
        await _tokenManager.clearSavedCredentials();
        logger.i('Saved credentials cleared (remember me disabled)');
      }
      
      return isAuthenticated;
    } catch (e) {
      logger.e('Login with remember me error: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _performLogout();
  }

  /// Logout with option to clear saved credentials
  Future<void> logoutAndClearCredentials() async {
    await _performLogout(clearCredentials: true);
  }

  @override
  Future<bool> refreshToken() async {
    return await _performRefreshToken();
  }

  @override
  Future<bool> validateToken() async {
    try {
      return await _tokenManager.isAccessTokenValid();
    } catch (e) {
      logger.e('Token validation error: $e');
      return false;
    }
  }

  @override
  Future<bool> forceRefreshToken() async {
    return await _performRefreshToken();
  }
  
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
          // Nếu session chưa có profile, thử lấy thông tin profile
          if (!session.hasCompleteProfile) {
            try {
              logger.i('Existing session found, fetching user profile...');
              
              final userProfileService = UserProfileService();
              final userProfile = await userProfileService.getCurrentUserProfile();
              
              // Cập nhật session với thông tin profile
              final updatedSession = session.copyWithProfile(userProfile);
              _authRepository.updateCurrentSession(updatedSession);
              
              _updateState(AuthStateData.authenticated(updatedSession));
              logger.i('Existing authentication with profile found for user: ${userProfile.fullName} (${userProfile.empCode})');
              
            } catch (e) {
              // Nếu lấy profile thất bại, vẫn cho authenticated nhưng không có profile
              logger.w('Failed to fetch user profile for existing session: $e');
              _updateState(AuthStateData.authenticated(session));
              logger.i('Existing authentication found but profile fetch failed for user: ${session.userId}');
            }
          } else {
            // Session đã có profile đầy đủ
            _updateState(AuthStateData.authenticated(session));
            logger.i('Existing authentication with profile found for user: ${session.preferredDisplayName}');
          }
          
          // Note: Token refresh is now handled by ApiService automatically
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

  /// Login with credentials (internal method)
  Future<void> _performLogin(LoginRequest request) async {
    try {
      _updateState(AuthStateData.refreshing(_currentState.user));
      
      final result = await _authRepository.login(request);
      
      if (result.success && result.data != null) {
        final session = _authRepository.currentSession;
        if (session != null) {
          // Login thành công, bây giờ lấy thông tin user profile
          try {
            logger.i('Login successful, fetching user profile...');
            
            final userProfileService = UserProfileService();
            final userProfile = await userProfileService.getCurrentUserProfile();
            
            // Cập nhật session với thông tin profile
            final updatedSession = session.copyWithProfile(userProfile);
            _authRepository.updateCurrentSession(updatedSession);
            
            _updateState(AuthStateData.authenticated(updatedSession));
            logger.i('Login and profile fetch successful for user: ${userProfile.fullName} (${userProfile.empCode})');
            
          } catch (e) {
            // Nếu lấy profile thất bại, vẫn cho login thành công nhưng không có profile
            logger.w('Failed to fetch user profile after login: $e');
            _updateState(AuthStateData.authenticated(session));
            logger.i('Login successful but profile fetch failed for user: ${request.username}');
          }
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

  /// Logout user (internal method)
  Future<void> _performLogout({bool clearCredentials = false}) async {
    try {
      _updateState(AuthStateData.refreshing(_currentState.user));
      
      final result = await _authRepository.logout();
      
      // Clear saved credentials if requested
      if (clearCredentials) {
        await _tokenManager.clearAll();
        logger.i('Logout with credentials cleared');
      }
      
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

  /// Refresh authentication token (internal method)
  Future<bool> _performRefreshToken() async {
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
        await _performLogout(); // Force logout on refresh failure
      }
      
      return false;
    } catch (e) {
      logger.e('Token refresh error: $e');
      await _performLogout(); // Force logout on error
      return false;
    }
  }

  /// Update authentication state
  void _updateState(AuthStateData newState) {
    _currentState = newState;
    _authStateController.add(newState);
    
    if (kDebugMode) {
      logger.d('Auth state updated: ${newState.state}');
    }
  }

  /// Check if authentication is loading
  bool get isLoading => _currentState.isLoading;
  
  /// Get authentication error
  String? get authError => _currentState.error;

  /// Get authentication status
  Future<AuthStatus> getAuthStatus() async {
    return await _authRepository.getAuthStatus();
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

  /// Refresh user profile information
  Future<bool> refreshUserProfile() async {
    try {
      if (!isAuthenticated || _currentState.user == null) {
        logger.w('Cannot refresh profile: user not authenticated');
        return false;
      }

      logger.i('Refreshing user profile...');
      
      final userProfileService = UserProfileService();
      final userProfile = await userProfileService.getCurrentUserProfile();
      
      // Cập nhật session với thông tin profile mới
      final currentSession = _currentState.user!;
      final updatedSession = currentSession.copyWithProfile(userProfile);
      _authRepository.updateCurrentSession(updatedSession);
      
      _updateState(AuthStateData.authenticated(updatedSession));
      logger.i('User profile refreshed successfully: ${userProfile.fullName} (${userProfile.empCode})');
      
      return true;
    } catch (e) {
      logger.e('Failed to refresh user profile: $e');
      return false;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
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
    logger.d('Token refresh: Handled by ApiService');
    logger.d('==========================');
  }
} 