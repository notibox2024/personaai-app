import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../features/auth/data/models/auth_response.dart';

/// Service quản lý JWT tokens với secure storage
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  final logger = Logger();

  // Secure storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresAtKey = 'token_expires_at';
  static const String _refreshExpiresAtKey = 'refresh_expires_at';

  // SharedPreferences keys
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _lastLoginKey = 'last_login';
  static const String _autoLoginEnabledKey = 'auto_login_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  // Secure storage keys for remember me feature
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';

  /// Initialize TokenManager
  Future<void> initialize() async {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    
    _prefs = await SharedPreferences.getInstance();
    
    if (kDebugMode) {
      logger.i('TokenManager initialized');
    }
  }

  /// Save tokens từ AuthResponse
  Future<void> saveTokens(AuthResponse authResponse) async {
    try {
      // Save tokens to secure storage
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: authResponse.accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: authResponse.refreshToken),
        _secureStorage.write(key: _tokenExpiresAtKey, value: authResponse.expiresAt.toIso8601String()),
        _secureStorage.write(key: _refreshExpiresAtKey, value: authResponse.refreshExpiresAt.toIso8601String()),
      ]);

      if (kDebugMode) {
        logger.i('Tokens saved successfully');
        logger.i('Access token expires at: ${authResponse.expiresAt}');
        logger.i('Refresh token expires at: ${authResponse.refreshExpiresAt}');
      }
    } catch (e) {
      logger.e('Error saving tokens: $e');
      rethrow;
    }
  }

  /// Save user metadata
  Future<void> saveUserMetadata({
    required String userId,
    required String username,
    bool? autoLoginEnabled,
    bool? biometricEnabled,
  }) async {
    try {
      await Future.wait([
        _prefs.setString(_userIdKey, userId),
        _prefs.setString(_usernameKey, username),
        _prefs.setString(_lastLoginKey, DateTime.now().toIso8601String()),
        if (autoLoginEnabled != null) _prefs.setBool(_autoLoginEnabledKey, autoLoginEnabled),
        if (biometricEnabled != null) _prefs.setBool(_biometricEnabledKey, biometricEnabled),
      ]);

      if (kDebugMode) {
        logger.i('User metadata saved for user: $username');
      }
    } catch (e) {
      logger.e('Error saving user metadata: $e');
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      logger.e('Error getting access token: $e');
      return null;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      logger.e('Error getting refresh token: $e');
      return null;
    }
  }

  /// Get token expiration time
  Future<DateTime?> getTokenExpirationTime() async {
    try {
      final expiresAtString = await _secureStorage.read(key: _tokenExpiresAtKey);
      if (expiresAtString != null) {
        return DateTime.parse(expiresAtString);
      }
      return null;
    } catch (e) {
      logger.e('Error getting token expiration time: $e');
      return null;
    }
  }

  /// Get refresh token expiration time
  Future<DateTime?> getRefreshTokenExpirationTime() async {
    try {
      final expiresAtString = await _secureStorage.read(key: _refreshExpiresAtKey);
      if (expiresAtString != null) {
        return DateTime.parse(expiresAtString);
      }
      return null;
    } catch (e) {
      logger.e('Error getting refresh token expiration time: $e');
      return null;
    }
  }

  /// Check if access token is valid (not expired)
  Future<bool> isAccessTokenValid() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final expiresAt = await getTokenExpirationTime();
      if (expiresAt == null) return false;

      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      logger.e('Error checking access token validity: $e');
      return false;
    }
  }

  /// Check if refresh token is valid (not expired)
  Future<bool> isRefreshTokenValid() async {
    try {
      final token = await getRefreshToken();
      if (token == null) return false;

      final expiresAt = await getRefreshTokenExpirationTime();
      if (expiresAt == null) return false;

      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      logger.e('Error checking refresh token validity: $e');
      return false;
    }
  }

  /// Check if should refresh token (expires in < 2 minutes)
  Future<bool> shouldRefreshToken() async {
    try {
      final expiresAt = await getTokenExpirationTime();
      if (expiresAt == null) return false;

      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);
      
      // Refresh if expires in less than 2 minutes
      return timeUntilExpiry.inMinutes < 2;
    } catch (e) {
      logger.e('Error checking if should refresh token: $e');
      return false;
    }
  }

  /// Get current AuthResponse from stored tokens
  Future<AuthResponse?> getCurrentAuthResponse() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final expiresAt = await getTokenExpirationTime();
      final refreshExpiresAt = await getRefreshTokenExpirationTime();

      if (accessToken == null || refreshToken == null || expiresAt == null || refreshExpiresAt == null) {
        return null;
      }

      return AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: 'Bearer',
        expiresIn: expiresAt.difference(DateTime.now()).inSeconds,
        refreshExpiresIn: refreshExpiresAt.difference(DateTime.now()).inSeconds,
        scope: 'openid profile email',
        sessionState: '',
        issuedAt: DateTime.now(),
        expiresAt: expiresAt,
        refreshExpiresAt: refreshExpiresAt,
      );
    } catch (e) {
      logger.e('Error getting current auth response: $e');
      return null;
    }
  }

  /// Clear all tokens and metadata
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        // Clear secure storage
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _tokenExpiresAtKey),
        _secureStorage.delete(key: _refreshExpiresAtKey),
        
        // Clear user metadata
        _prefs.remove(_userIdKey),
        _prefs.remove(_usernameKey),
        _prefs.remove(_lastLoginKey),
        _prefs.remove(_autoLoginEnabledKey),
        _prefs.remove(_biometricEnabledKey),
      ]);

      if (kDebugMode) {
        logger.i('All tokens and metadata cleared');
      }
    } catch (e) {
      logger.e('Error clearing tokens: $e');
      rethrow;
    }
  }

  /// Clear all tokens, metadata, and saved credentials (for complete logout)
  Future<void> clearAll() async {
    try {
      await Future.wait([
        // Clear secure storage (tokens + credentials)
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _tokenExpiresAtKey),
        _secureStorage.delete(key: _refreshExpiresAtKey),
        _secureStorage.delete(key: _savedUsernameKey),
        _secureStorage.delete(key: _savedPasswordKey),
        
        // Clear user metadata
        _prefs.remove(_userIdKey),
        _prefs.remove(_usernameKey),
        _prefs.remove(_lastLoginKey),
        _prefs.remove(_autoLoginEnabledKey),
        _prefs.remove(_biometricEnabledKey),
      ]);

      if (kDebugMode) {
        logger.i('All tokens, metadata, and saved credentials cleared');
      }
    } catch (e) {
      logger.e('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Get user metadata
  Future<Map<String, dynamic>> getUserMetadata() async {
    return {
      'user_id': _prefs.getString(_userIdKey),
      'username': _prefs.getString(_usernameKey),
      'last_login': _prefs.getString(_lastLoginKey),
      'auto_login_enabled': _prefs.getBool(_autoLoginEnabledKey) ?? false,
      'biometric_enabled': _prefs.getBool(_biometricEnabledKey) ?? false,
    };
  }

  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    try {
      final hasAccessToken = await getAccessToken() != null;
      final hasRefreshToken = await getRefreshToken() != null;
      final refreshTokenValid = await isRefreshTokenValid();
      
      return hasAccessToken && hasRefreshToken && refreshTokenValid;
    } catch (e) {
      logger.e('Error checking valid session: $e');
      return false;
    }
  }

  /// Get token time remaining
  Future<Duration?> getTokenTimeRemaining() async {
    try {
      final expiresAt = await getTokenExpirationTime();
      if (expiresAt == null) return null;

      final now = DateTime.now();
      if (now.isAfter(expiresAt)) return Duration.zero;

      return expiresAt.difference(now);
    } catch (e) {
      logger.e('Error getting token time remaining: $e');
      return null;
    }
  }

  /// Save credentials for "Remember Me" feature
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(key: _savedUsernameKey, value: username),
        _secureStorage.write(key: _savedPasswordKey, value: password),
        _prefs.setBool(_autoLoginEnabledKey, true),
      ]);

      if (kDebugMode) {
        logger.i('Credentials saved for remember me: $username');
      }
    } catch (e) {
      logger.e('Error saving credentials: $e');
      rethrow;
    }
  }

  /// Get saved credentials for "Remember Me" feature
  Future<Map<String, String?>> getSavedCredentials() async {
    try {
      final isRememberMeEnabled = _prefs.getBool(_autoLoginEnabledKey) ?? false;
      
      if (!isRememberMeEnabled) {
        return {'username': null, 'password': null};
      }

      final username = await _secureStorage.read(key: _savedUsernameKey);
      final password = await _secureStorage.read(key: _savedPasswordKey);

      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      logger.e('Error getting saved credentials: $e');
      return {'username': null, 'password': null};
    }
  }

  /// Clear saved credentials
  Future<void> clearSavedCredentials() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _savedUsernameKey),
        _secureStorage.delete(key: _savedPasswordKey),
        _prefs.setBool(_autoLoginEnabledKey, false),
      ]);

      if (kDebugMode) {
        logger.i('Saved credentials cleared');
      }
    } catch (e) {
      logger.e('Error clearing saved credentials: $e');
    }
  }

  /// Check if remember me is enabled
  bool get isRememberMeEnabled => _prefs.getBool(_autoLoginEnabledKey) ?? false;

  /// Debug: Print token status (only in debug mode)
  Future<void> debugTokenStatus() async {
    if (!kDebugMode) return;

    try {
      final hasAccess = await getAccessToken() != null;
      final hasRefresh = await getRefreshToken() != null;
      final isAccessValid = await isAccessTokenValid();
      final isRefreshValid = await isRefreshTokenValid();
      final shouldRefresh = await shouldRefreshToken();
      final timeRemaining = await getTokenTimeRemaining();
      final savedCredentials = await getSavedCredentials();

      logger.d('Token Status:');
      logger.d('  - Has access token: $hasAccess');
      logger.d('  - Has refresh token: $hasRefresh');
      logger.d('  - Access token valid: $isAccessValid');
      logger.d('  - Refresh token valid: $isRefreshValid');
      logger.d('  - Should refresh: $shouldRefresh');
      logger.d('  - Time remaining: $timeRemaining');
      logger.d('  - Remember me enabled: $isRememberMeEnabled');
      logger.d('  - Has saved username: ${savedCredentials['username'] != null}');
    } catch (e) {
      logger.e('Error debugging token status: $e');
    }
  }
} 