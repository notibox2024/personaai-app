import 'data/models/auth_state.dart';
import 'data/models/user_session.dart';

/// Public interface for authentication functionality
/// Used by other features to access auth state without direct service coupling
abstract class AuthProvider {
  /// Current authentication state
  bool get isAuthenticated;
  
  /// Current user session (if authenticated)
  UserSession? get currentUser;
  
  /// Stream of authentication state changes
  Stream<AuthStateData> get authStateStream;
  
  /// Login with username/password
  Future<bool> login(String username, String password);
  
  /// Logout current user
  Future<void> logout();
  
  /// Refresh authentication token
  Future<bool> refreshToken();
  
  /// Validate current token
  Future<bool> validateToken();
  
  /// Force refresh token
  Future<bool> forceRefreshToken();
} 