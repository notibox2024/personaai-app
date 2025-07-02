import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/login_request.dart';
import '../../data/models/user_session.dart';
import '../../data/services/auth_service.dart';
import '../../../../shared/services/token_manager.dart';

// ==================== AUTH EVENTS ====================

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitialize extends AuthEvent {
  const AuthInitialize();
}

class AuthLogin extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const AuthLogin({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}

class AuthRefreshToken extends AuthEvent {
  const AuthRefreshToken();
}

class AuthForceRefresh extends AuthEvent {
  const AuthForceRefresh();
}

class AuthValidateToken extends AuthEvent {
  const AuthValidateToken();
}

class AuthStateChanged extends AuthEvent {
  final AuthStateData authState;

  const AuthStateChanged(this.authState);

  @override
  List<Object?> get props => [authState];
}

class AuthClearError extends AuthEvent {
  const AuthClearError();
}

class AuthLoadSavedCredentials extends AuthEvent {
  const AuthLoadSavedCredentials();
}

class AuthAutoLogin extends AuthEvent {
  const AuthAutoLogin();
}

// ==================== AUTH STATES ====================

abstract class AuthBlocState extends Equatable {
  const AuthBlocState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthBlocState {
  const AuthInitial();
}

class AuthLoading extends AuthBlocState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthBlocState {
  final UserSession user;

  const AuthAuthenticated({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthBlocState {
  const AuthUnauthenticated();
}

class AuthRefreshing extends AuthBlocState {
  final UserSession? user;

  const AuthRefreshing({this.user});

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthBlocState {
  final String message;
  final UserSession? user;

  const AuthError({
    required this.message,
    this.user,
  });

  @override
  List<Object?> get props => [message, user];
}

class AuthTokenExpired extends AuthBlocState {
  final UserSession? user;

  const AuthTokenExpired({this.user});

  @override
  List<Object?> get props => [user];
}

class AuthCredentialsLoaded extends AuthBlocState {
  final String? username;
  final String? password;
  final bool hasCredentials;

  const AuthCredentialsLoaded({
    this.username,
    this.password,
    this.hasCredentials = false,
  });

  @override
  List<Object?> get props => [username, password, hasCredentials];
}

// ==================== AUTH BLOC ====================

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final AuthService _authService;
  final logger = Logger();
  
  StreamSubscription<AuthStateData>? _authStateSubscription;

  AuthBloc({
    AuthService? authService,
  })  : _authService = authService ?? AuthService(),
        super(const AuthInitial()) {
    
    // Register event handlers
    on<AuthInitialize>(_onInitialize);
    on<AuthLogin>(_onLogin);
    on<AuthLogout>(_onLogout);
    on<AuthRefreshToken>(_onRefreshToken);
    on<AuthForceRefresh>(_onForceRefresh);
    on<AuthValidateToken>(_onValidateToken);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthClearError>(_onClearError);
    on<AuthLoadSavedCredentials>(_onLoadSavedCredentials);
    on<AuthAutoLogin>(_onAutoLogin);
  }

  /// Initialize authentication
  Future<void> _onInitialize(AuthInitialize event, Emitter<AuthBlocState> emit) async {
    try {
      emit(const AuthLoading());
      
      // AuthService đã được initialize bởi AuthModule - không cần init lại
      // Listen to auth state changes từ service đã initialized
      _startListeningToAuthChanges();
      
      // Check if user is already authenticated
      final currentAuthState = _authService.currentState;
      
      if (currentAuthState.state == AuthState.authenticated && currentAuthState.user != null) {
        emit(AuthAuthenticated(user: currentAuthState.user!));
        logger.i('User already authenticated: ${currentAuthState.user!.preferredDisplayName}');
      } else {
        emit(const AuthUnauthenticated());
        logger.d('No authenticated user found');
      }
      
    } catch (e) {
      logger.e('Error during auth initialization: $e');
      emit(AuthError(message: 'Lỗi khởi tạo authentication: ${e.toString()}'));
    }
  }

  /// Handle login
  Future<void> _onLogin(AuthLogin event, Emitter<AuthBlocState> emit) async {
    try {
      emit(const AuthLoading());
      
      await _authService.loginWithRememberMe(
        event.username,
        event.password,
        event.rememberMe,
      );
      
      logger.i('Login attempt completed for user: ${event.username} (Remember me: ${event.rememberMe})');
      
      // State sẽ được update qua _onAuthStateChanged khi service stream emit
      
    } catch (e) {
      logger.e('Login error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle logout
  Future<void> _onLogout(AuthLogout event, Emitter<AuthBlocState> emit) async {
    try {
      emit(const AuthLoading());
      await _authService.logout();
      logger.i('User logged out successfully');
      
      // State sẽ được update qua _onAuthStateChanged
      
    } catch (e) {
      logger.e('Logout error: $e');
      emit(AuthError(message: 'Lỗi khi đăng xuất: ${e.toString()}'));
    }
  }

  /// Handle token refresh
  Future<void> _onRefreshToken(AuthRefreshToken event, Emitter<AuthBlocState> emit) async {
    try {
      final currentUser = _getCurrentUser();
      emit(AuthRefreshing(user: currentUser));
      
      await _authService.refreshToken();
      logger.i('Token refresh completed');
      
      // State sẽ được update qua _onAuthStateChanged
      
    } catch (e) {
      logger.e('Token refresh error: $e');
      emit(AuthError(
        message: 'Lỗi làm mới token: ${e.toString()}',
        user: _getCurrentUser(),
      ));
    }
  }

  /// Handle force refresh
  Future<void> _onForceRefresh(AuthForceRefresh event, Emitter<AuthBlocState> emit) async {
    try {
      final currentUser = _getCurrentUser();
      emit(AuthRefreshing(user: currentUser));
      
      await _authService.forceRefreshToken();
      logger.i('Force refresh completed');
      
      // State sẽ được update qua _onAuthStateChanged
      
    } catch (e) {
      logger.e('Force refresh error: $e');
      emit(AuthError(
        message: 'Lỗi force refresh: ${e.toString()}',
        user: _getCurrentUser(),
      ));
    }
  }

  /// Handle token validation
  Future<void> _onValidateToken(AuthValidateToken event, Emitter<AuthBlocState> emit) async {
    try {
      final isValid = await _authService.validateToken();
      
      if (!isValid) {
        logger.w('Token validation failed');
        emit(const AuthUnauthenticated());
      } else {
        logger.d('Token validation passed');
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          emit(AuthAuthenticated(user: currentUser));
        }
      }
    } catch (e) {
      logger.e('Token validation error: $e');
      emit(AuthError(message: 'Lỗi kiểm tra token: ${e.toString()}'));
    }
  }

  /// Handle auth state changes from service
  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthBlocState> emit) {
    final authState = event.authState;
    
    switch (authState.state) {
      case AuthState.initial:
        emit(const AuthInitial());
        break;
        
      case AuthState.refreshing:
        emit(AuthRefreshing(user: authState.user));
        break;
        
      case AuthState.authenticated:
        if (authState.user != null) {
          emit(AuthAuthenticated(user: authState.user!));
        }
        break;
        
      case AuthState.unauthenticated:
        emit(const AuthUnauthenticated());
        break;
        
      case AuthState.error:
        emit(AuthError(
          message: authState.error ?? 'Lỗi authentication không xác định',
          user: authState.user,
        ));
        break;
    }
    
    logger.d('AuthBloc state updated: ${authState.state}');
  }

  /// Clear error state
  void _onClearError(AuthClearError event, Emitter<AuthBlocState> emit) {
    final currentUser = _getCurrentUser();
    if (currentUser != null) {
      emit(AuthAuthenticated(user: currentUser));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Load saved credentials for auto-fill
  Future<void> _onLoadSavedCredentials(AuthLoadSavedCredentials event, Emitter<AuthBlocState> emit) async {
    try {
      final tokenManager = TokenManager();
      final savedCredentials = await tokenManager.getSavedCredentials();
      
      final username = savedCredentials['username'];
      final password = savedCredentials['password'];
      final hasCredentials = username != null && password != null;
      
      emit(AuthCredentialsLoaded(
        username: username,
        password: password,
        hasCredentials: hasCredentials,
      ));
      
      if (kDebugMode) {
        logger.i('Saved credentials loaded: ${hasCredentials ? 'Found' : 'None'}');
      }
    } catch (e) {
      logger.e('Error loading saved credentials: $e');
      emit(const AuthCredentialsLoaded(hasCredentials: false));
    }
  }

  /// Attempt auto login with saved credentials
  Future<void> _onAutoLogin(AuthAutoLogin event, Emitter<AuthBlocState> emit) async {
    try {
      final tokenManager = TokenManager();
      
      // Check if remember me is enabled
      if (!tokenManager.isRememberMeEnabled) {
        logger.d('Auto login disabled - remember me not enabled');
        return;
      }

      // Check if we have a valid refresh token first
      final hasValidSession = await tokenManager.hasValidSession();
      if (hasValidSession) {
        logger.i('Auto login skipped - valid session exists');
        return;
      }

      // Try auto login with saved credentials
      final savedCredentials = await tokenManager.getSavedCredentials();
      final username = savedCredentials['username'];
      final password = savedCredentials['password'];
      
      if (username != null && password != null) {
        logger.i('Attempting auto login for user: $username');
        emit(const AuthLoading());
        
        await _authService.loginWithRememberMe(username, password, true);
        
        logger.i('Auto login completed for user: $username');
      } else {
        logger.w('Auto login failed - no saved credentials');
      }
    } catch (e) {
      logger.e('Auto login error: $e');
      emit(AuthError(message: 'Auto login failed: ${e.toString()}'));
    }
  }

  /// Start listening to auth service state changes
  void _startListeningToAuthChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authService.authStateStream.listen(
      (authState) => add(AuthStateChanged(authState)),
      onError: (error) {
        logger.e('Auth state stream error: $error');
        add(AuthStateChanged(AuthStateData.error('Auth stream error')));
      },
    );
  }

  /// Get current user from state
  UserSession? _getCurrentUser() {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    } else if (state is AuthRefreshing) {
      return (state as AuthRefreshing).user;
    } else if (state is AuthError) {
      return (state as AuthError).user;
    }
    return null;
  }

  /// Public getters
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _authService.isLoading;
  UserSession? get currentUser => _authService.currentUser;
  String? get authError => _authService.authError;

  /// Debug current state
  void debugCurrentState() {
    logger.d('=== AUTH BLOC DEBUG ===');
    logger.d('BLoC State: ${state.runtimeType}');
    logger.d('Service Authenticated: ${_authService.isAuthenticated}');
    logger.d('Service Loading: ${_authService.isLoading}');
    logger.d('Current User: ${_authService.currentUser?.userId}');
    logger.d('Token Refresh: Handled by ApiService');
    logger.d('=======================');
  }

  @override
  Future<void> close() async {
    _authStateSubscription?.cancel();
    await _authService.dispose();
    
    logger.i('AuthBloc disposed');
    return super.close();
  }
} 