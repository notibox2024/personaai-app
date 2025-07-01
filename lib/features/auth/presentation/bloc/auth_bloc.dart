import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/login_request.dart';
import '../../data/models/user_session.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/background_token_refresh_service.dart';

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

class AuthTokenNearExpiry extends AuthEvent {
  final UserSession user;

  const AuthTokenNearExpiry(this.user);

  @override
  List<Object?> get props => [user];
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
  final bool isTokenNearExpiry;

  const AuthAuthenticated({
    required this.user,
    this.isTokenNearExpiry = false,
  });

  @override
  List<Object?> get props => [user, isTokenNearExpiry];
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

// ==================== AUTH BLOC ====================

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final AuthService _authService;
  final BackgroundTokenRefreshService _backgroundService;
  final logger = Logger();
  
  StreamSubscription<AuthStateData>? _authStateSubscription;
  Timer? _tokenExpiryCheckTimer;

  AuthBloc({
    AuthService? authService,
    BackgroundTokenRefreshService? backgroundService,
  })  : _authService = authService ?? AuthService(),
        _backgroundService = backgroundService ?? BackgroundTokenRefreshService(),
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
    on<AuthTokenNearExpiry>(_onTokenNearExpiry);
  }

  /// Initialize authentication
  Future<void> _onInitialize(AuthInitialize event, Emitter<AuthBlocState> emit) async {
    try {
      emit(const AuthLoading());
      
      // AuthService đã được initialize bởi AuthModule - không cần init lại
      // Listen to auth state changes từ service đã initialized
      _startListeningToAuthChanges();
      
      // Start token expiry monitoring
      _startTokenExpiryMonitoring();
      
      // Get initial auth state
      final currentState = _authService.currentState;
      add(AuthStateChanged(currentState));
      
      logger.i('AuthBloc initialized');
    } catch (e) {
      logger.e('AuthBloc initialization failed: $e');
      emit(AuthError(message: 'Khởi tạo authentication thất bại: ${e.toString()}'));
    }
  }

  /// Handle login
  Future<void> _onLogin(AuthLogin event, Emitter<AuthBlocState> emit) async {
    try {
      emit(const AuthLoading());
      
      await _authService.login(event.username, event.password);
      
      logger.i('Login attempt completed for user: ${event.username}');
    } catch (e) {
      logger.e('Login error: $e');
      emit(AuthError(message: 'Đăng nhập thất bại: ${e.toString()}'));
    }
  }

  /// Handle logout
  Future<void> _onLogout(AuthLogout event, Emitter<AuthBlocState> emit) async {
    try {
      emit(AuthRefreshing(user: _getCurrentUser()));
      
      await _authService.logout();
      
      logger.i('Logout completed');
    } catch (e) {
      logger.e('Logout error: $e');
      emit(AuthError(message: 'Đăng xuất thất bại: ${e.toString()}'));
    }
  }

  /// Handle token refresh
  Future<void> _onRefreshToken(AuthRefreshToken event, Emitter<AuthBlocState> emit) async {
    try {
      final currentUser = _getCurrentUser();
      if (currentUser == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      emit(AuthRefreshing(user: currentUser));
      
      final success = await _authService.refreshToken();
      
      if (success) {
        logger.i('Token refresh successful');
      } else {
        logger.w('Token refresh failed - user will be logged out');
      }
    } catch (e) {
      logger.e('Token refresh error: $e');
      emit(AuthError(message: 'Làm mới token thất bại: ${e.toString()}'));
    }
  }

  /// Handle force refresh
  Future<void> _onForceRefresh(AuthForceRefresh event, Emitter<AuthBlocState> emit) async {
    try {
      final currentUser = _getCurrentUser();
      emit(AuthRefreshing(user: currentUser));
      
      final success = await _authService.forceRefreshToken();
      
      if (success) {
        logger.i('Force token refresh successful');
      } else {
        logger.w('Force token refresh failed');
        emit(AuthError(message: 'Làm mới token thất bại'));
      }
    } catch (e) {
      logger.e('Force refresh error: $e');
      emit(AuthError(message: 'Làm mới token thất bại: ${e.toString()}'));
    }
  }

  /// Handle token validation
  Future<void> _onValidateToken(AuthValidateToken event, Emitter<AuthBlocState> emit) async {
    try {
      final isValid = await _authService.validateToken();
      
      if (!isValid) {
        logger.w('Token validation failed - user will be logged out');
        add(const AuthLogout());
      } else {
        logger.d('Token validation successful');
      }
    } catch (e) {
      logger.e('Token validation error: $e');
      emit(AuthError(message: 'Xác thực token thất bại: ${e.toString()}'));
    }
  }

  /// Handle auth state changes from AuthService
  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthBlocState> emit) {
    final authState = event.authState;
    
    switch (authState.state) {
      case AuthState.initial:
        emit(const AuthInitial());
        break;
        
      case AuthState.unauthenticated:
        emit(const AuthUnauthenticated());
        break;
        
      case AuthState.authenticated:
        if (authState.user != null) {
          emit(AuthAuthenticated(user: authState.user!));
          _checkTokenExpiry(authState.user!);
        } else {
          emit(const AuthUnauthenticated());
        }
        break;
        
      case AuthState.refreshing:
        emit(AuthRefreshing(user: authState.user));
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

  /// Handle token near expiry
  void _onTokenNearExpiry(AuthTokenNearExpiry event, Emitter<AuthBlocState> emit) {
    emit(AuthAuthenticated(
      user: event.user,
      isTokenNearExpiry: true,
    ));
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

  /// Start token expiry monitoring
  void _startTokenExpiryMonitoring() {
    _stopTokenExpiryMonitoring();
    
    _tokenExpiryCheckTimer = Timer.periodic(
      const Duration(minutes: 1), // Check every minute
      (timer) async {
        if (_authService.isAuthenticated) {
          final isNearExpiry = _authService.isTokenNearExpiry;
          final currentUser = _authService.currentUser;
          
          if (isNearExpiry && currentUser != null) {
            logger.d('Token near expiry detected');
            
            // Add event to emit state with expiry warning
            if (state is AuthAuthenticated) {
              add(AuthTokenNearExpiry(currentUser));
            }
            
            // Trigger auto refresh
            add(const AuthRefreshToken());
          }
        }
      },
    );
  }

  /// Stop token expiry monitoring
  void _stopTokenExpiryMonitoring() {
    _tokenExpiryCheckTimer?.cancel();
    _tokenExpiryCheckTimer = null;
  }

  /// Check token expiry for specific user
  Future<void> _checkTokenExpiry(UserSession user) async {
    try {
      final timeRemaining = await _authService.getTokenTimeRemaining();
      
      if (timeRemaining != null && timeRemaining.inMinutes <= 5) {
        logger.w('Token expires in ${timeRemaining.inMinutes} minutes');
        
        if (state is AuthAuthenticated) {
          // Use event to update state instead of direct emit
          add(AuthTokenNearExpiry(user));
        }
      }
    } catch (e) {
      logger.e('Error checking token expiry: $e');
    }
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
    logger.d('Background Service Refreshing: ${_backgroundService.isRefreshing}');
    logger.d('=======================');
  }

  @override
  Future<void> close() async {
    _authStateSubscription?.cancel();
    _stopTokenExpiryMonitoring();
    await _authService.dispose();
    await _backgroundService.dispose();
    
    logger.i('AuthBloc disposed');
    return super.close();
  }
} 