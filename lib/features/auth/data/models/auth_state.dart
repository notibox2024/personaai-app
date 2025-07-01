import 'user_session.dart';

/// Enum cho trạng thái authentication
enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  refreshing,
  error
}

/// Data class chứa auth state và user info
class AuthStateData {
  final AuthState state;
  final UserSession? user;
  final String? error;

  const AuthStateData({
    required this.state,
    this.user,
    this.error,
  });

  /// Factory constructors cho common states
  factory AuthStateData.initial() {
    return const AuthStateData(state: AuthState.initial);
  }

  factory AuthStateData.authenticated(UserSession user) {
    return AuthStateData(
      state: AuthState.authenticated,
      user: user,
    );
  }

  factory AuthStateData.unauthenticated() {
    return const AuthStateData(state: AuthState.unauthenticated);
  }

  factory AuthStateData.refreshing(UserSession? user) {
    return AuthStateData(
      state: AuthState.refreshing,
      user: user,
    );
  }

  factory AuthStateData.error(String error, {UserSession? user}) {
    return AuthStateData(
      state: AuthState.error,
      error: error,
      user: user,
    );
  }

  /// Helper getters
  bool get isAuthenticated => state == AuthState.authenticated && user != null;
  bool get isUnauthenticated => state == AuthState.unauthenticated;
  bool get isLoading => state == AuthState.refreshing;
  bool get hasError => state == AuthState.error && error != null;

  /// Copy with new values
  AuthStateData copyWith({
    AuthState? state,
    UserSession? user,
    String? error,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AuthStateData(state: $state, user: ${user?.userId}, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthStateData &&
        other.state == state &&
        other.user == user &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(state, user, error);
  }
} 