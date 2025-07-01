import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/data/services/background_token_refresh_service.dart';
import 'firebase_service.dart';
import 'location_service.dart';

/// Service quản lý app lifecycle và background services
class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final logger = Logger();
  
  // Services
  late final AuthService _authService;
  late final BackgroundTokenRefreshService _backgroundRefreshService;
  late final FirebaseService _firebaseService;
  late final LocationService _locationService;
  // late final NotificationService _notificationService; // TODO: Implement NotificationService
  
  // State tracking
  AppLifecycleState? _lastLifecycleState;
  DateTime? _backgroundTime;
  Timer? _backgroundTimer;
  bool _isInitialized = false;
  
  // Background duration thresholds
  static const Duration _shortBackgroundDuration = Duration(minutes: 5);
  static const Duration _longBackgroundDuration = Duration(minutes: 30);

  /// Initialize app lifecycle service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize services
      _authService = AuthService();
      _backgroundRefreshService = BackgroundTokenRefreshService();
      _firebaseService = FirebaseService();
      _locationService = LocationService();
      // _notificationService = NotificationService(); // TODO: Implement NotificationService
      
      // Add lifecycle observer
      WidgetsBinding.instance.addObserver(this);
      
      _isInitialized = true;
      logger.i('AppLifecycleService initialized');
    } catch (e) {
      logger.e('AppLifecycleService initialization failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    logger.d('App lifecycle changed: ${_lastLifecycleState} -> $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
    
    _lastLifecycleState = state;
  }

  /// Handle app resumed from background
  Future<void> _handleAppResumed() async {
    try {
      logger.i('App resumed from background');
      
      // Calculate background duration
      final backgroundDuration = _backgroundTime != null 
          ? DateTime.now().difference(_backgroundTime!)
          : Duration.zero;
      
      logger.d('App was in background for: ${backgroundDuration.inMinutes} minutes');
      
      // Resume background services
      _backgroundRefreshService.resume();
      
      // Check auth status after long background
      if (backgroundDuration > _longBackgroundDuration) {
        await _handleLongBackgroundReturn();
      } else if (backgroundDuration > _shortBackgroundDuration) {
        await _handleShortBackgroundReturn();
      }
      
      // Resume location tracking if needed
      // await _locationService.resumeLocationTracking(); // TODO: Implement in LocationService
      
      // Clear background timer
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      _backgroundTime = null;
      
    } catch (e) {
      logger.e('Error handling app resume: $e');
    }
  }

  /// Handle app paused to background
  Future<void> _handleAppPaused() async {
    try {
      logger.i('App paused to background');
      
      _backgroundTime = DateTime.now();
      
      // Pause location tracking to save battery
      // await _locationService.pauseLocationTracking(); // TODO: Implement in LocationService
      
      // Keep background refresh service running
      // (it will pause itself based on remote config)
      
      // Start background timer for long-term background handling
      _startBackgroundTimer();
      
    } catch (e) {
      logger.e('Error handling app pause: $e');
    }
  }

  /// Handle app inactive (transitional state)
  Future<void> _handleAppInactive() async {
    logger.d('App became inactive');
    // Usually happens during transitions, no action needed
  }

  /// Handle app detached (about to be terminated)
  Future<void> _handleAppDetached() async {
    try {
      logger.w('App is being detached');
      
      // Save critical data
      await _saveAppState();
      
      // Pause all background services
      _backgroundRefreshService.pause();
      // await _locationService.pauseLocationTracking(); // TODO: Implement in LocationService
      
    } catch (e) {
      logger.e('Error handling app detach: $e');
    }
  }

  /// Handle app hidden (iOS specific)
  Future<void> _handleAppHidden() async {
    logger.d('App was hidden');
    // Similar to paused but more aggressive
    await _handleAppPaused();
  }

  /// Handle return after short background duration
  Future<void> _handleShortBackgroundReturn() async {
    logger.d('Handling short background return');
    
    // Check auth status
    if (_authService.isAuthenticated) {
      // Validate token if near expiry
      final isNearExpiry = _authService.isTokenNearExpiry;
      if (isNearExpiry) {
        await _authService.forceRefreshToken();
      }
    }
  }

  /// Handle return after long background duration
  Future<void> _handleLongBackgroundReturn() async {
    logger.d('Handling long background return');
    
    // Force token validation
    if (_authService.isAuthenticated) {
      final isValid = await _authService.validateToken();
      if (!isValid) {
        logger.w('Token invalid after long background, forcing re-auth');
        await _authService.logout();
      }
    }
    
    // Refresh Firebase token
    // await _firebaseService.refreshFCMToken(); // TODO: Implement in FirebaseService
    
    // Check for pending notifications
    await _checkPendingNotifications();
  }

  /// Start background timer for extended background handling
  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    
    // Set timer for very long background duration (6 hours)
    _backgroundTimer = Timer(const Duration(hours: 6), () async {
      logger.w('App in background for extended period, cleaning up');
      
      // Force logout after very long background
      if (_authService.isAuthenticated) {
        await _authService.logout();
      }
      
      // Clear sensitive data
      await _clearSensitiveData();
    });
  }

  /// Save app state before termination
  Future<void> _saveAppState() async {
    try {
      // Save last app usage time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_app_usage', DateTime.now().millisecondsSinceEpoch);
      
      // Save auth state
      if (_authService.isAuthenticated) {
        await prefs.setBool('was_authenticated', true);
      }
      
      logger.d('App state saved');
    } catch (e) {
      logger.e('Error saving app state: $e');
    }
  }

  /// Check for pending notifications after background return
  Future<void> _checkPendingNotifications() async {
    try {
      // TODO: Implement when NotificationService is available
      logger.d('Checking pending notifications (placeholder)');
      
      // // Check for pending local notifications
      // final pendingNotifications = await _notificationService.getPendingNotifications();
      // 
      // if (pendingNotifications.isNotEmpty) {
      //   logger.d('Found ${pendingNotifications.length} pending notifications');
      //   
      //   // Process notifications if needed
      //   for (final notification in pendingNotifications) {
      //     await _notificationService.processNotification(notification);
      //   }
      // }
    } catch (e) {
      logger.e('Error checking pending notifications: $e');
    }
  }

  /// Clear sensitive data for security
  Future<void> _clearSensitiveData() async {
    try {
      // Clear temporary cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('temp_data');
      await prefs.remove('cached_responses');
      
      // Clear location cache if old
      // await _locationService.clearOldLocationCache(); // TODO: Implement in LocationService
      
      logger.d('Sensitive data cleared');
    } catch (e) {
      logger.e('Error clearing sensitive data: $e');
    }
  }

  /// Force app to foreground (if possible)
  Future<void> bringAppToForeground() async {
    try {
      await SystemChannels.platform.invokeMethod('SystemNavigator.bringToForeground');
      logger.d('Attempted to bring app to foreground');
    } catch (e) {
      logger.w('Could not bring app to foreground: $e');
    }
  }

  /// Get app lifecycle statistics
  Map<String, dynamic> getLifecycleStats() {
    return {
      'is_initialized': _isInitialized,
      'current_state': _lastLifecycleState?.toString(),
      'background_time': _backgroundTime?.toIso8601String(),
      'has_background_timer': _backgroundTimer != null,
      'auth_service_initialized': _authService.isAuthenticated,
      'background_refresh_active': _backgroundRefreshService.isMonitoring,
    };
  }

  /// Manually trigger background return handling (for testing)
  Future<void> simulateBackgroundReturn({Duration? backgroundDuration}) async {
    final duration = backgroundDuration ?? const Duration(minutes: 10);
    _backgroundTime = DateTime.now().subtract(duration);
    
    if (duration > _longBackgroundDuration) {
      await _handleLongBackgroundReturn();
    } else if (duration > _shortBackgroundDuration) {
      await _handleShortBackgroundReturn();
    }
    
    _backgroundTime = null;
  }

  /// Dispose lifecycle service
  Future<void> dispose() async {
    try {
      WidgetsBinding.instance.removeObserver(this);
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      _isInitialized = false;
      
      logger.i('AppLifecycleService disposed');
    } catch (e) {
      logger.e('Error disposing AppLifecycleService: $e');
    }
  }

  /// Debug current lifecycle state
  void debugCurrentState() {
    if (!kDebugMode) return;
    
    logger.d('=== APP LIFECYCLE DEBUG ===');
    logger.d('Is Initialized: $_isInitialized');
    logger.d('Last State: $_lastLifecycleState');
    logger.d('Background Time: $_backgroundTime');
    logger.d('Background Timer Active: ${_backgroundTimer != null}');
    logger.d('Auth Service Active: ${_authService.isAuthenticated}');
    logger.d('Background Refresh Active: ${_backgroundRefreshService.isMonitoring}');
    logger.d('==========================');
  }
} 