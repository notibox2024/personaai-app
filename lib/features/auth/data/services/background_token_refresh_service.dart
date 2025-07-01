import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'auth_service.dart';
import '../../../../shared/services/token_manager.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/services/performance_monitor.dart';
import '../../../../shared/constants/remote_config_keys.dart';

/// Service xử lý automatic token refresh ở background với performance monitoring
class BackgroundTokenRefreshService {
  static final BackgroundTokenRefreshService _instance = BackgroundTokenRefreshService._internal();
  factory BackgroundTokenRefreshService() => _instance;
  BackgroundTokenRefreshService._internal();

  // Use getters instead of late final to avoid initialization conflicts
  AuthService get _authService => AuthService();
  TokenManager get _tokenManager => TokenManager();
  final logger = Logger();
  
  // Use getter instead of late final to avoid initialization conflicts
  PerformanceMonitor get _performanceMonitor => PerformanceMonitor();
  
  Timer? _backgroundTimer;
  Timer? _networkRetryTimer;
  Timer? _healthCheckTimer;
  bool _isRefreshing = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isMonitoring = false;
  int _retryCount = 0;
  int _successfulRefreshes = 0;
  int _failedRefreshes = 0;
  DateTime? _lastSuccessfulRefresh;
  DateTime? _lastFailedRefresh;
  static const int maxRetryAttempts = 3;
  final Completer<void> _initCompleter = Completer<void>();
  
  /// Initialize background service với performance monitoring
  Future<void> initialize() async {
    // Handle concurrent initialization attempts
    if (_isInitialized) return;
    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }
    
    _isInitializing = true;
    _performanceMonitor.startOperation('background_token_service_init');
    bool operationEnded = false;
    
    try {
      // Services đã được initialize bởi GlobalServices và AuthModule
      // Chỉ cần start health check monitoring
      _startHealthCheckMonitoring();
      
      _isInitialized = true;
      _performanceMonitor.endOperation('background_token_service_init');
      operationEnded = true;
      _recordServiceHealth(true, 'Initialized successfully');
      
      logger.i('BackgroundTokenRefreshService initialized with monitoring');
      
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      if (!operationEnded) {
        _performanceMonitor.endOperation('background_token_service_init');
      }
      _recordServiceHealth(false, 'Initialization failed', error: e.toString());
      logger.e('BackgroundTokenRefreshService initialization failed: $e');
      
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Start background monitoring for token refresh
  void _startBackgroundMonitoring() {
    if (_isMonitoring) return;
    
    _stopBackgroundMonitoring(); // Stop existing timer
    
    // Check if background refresh is enabled
    final backgroundRefreshEnabled = FirebaseService().getConfigBool(
      RemoteConfigKeys.enableAutoRefresh, 
      defaultValue: true
    );
    
    if (!backgroundRefreshEnabled) {
      logger.d('Background token refresh disabled via remote config');
      _recordServiceHealth(false, 'Disabled via remote config');
      return;
    }
    
    // Check every 60 seconds for token refresh needs
    _backgroundTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      await _performBackgroundCheck();
    });
    
    _isMonitoring = true;
    _recordServiceHealth(true, 'Monitoring started');
    logger.d('Background token refresh monitoring started');
  }

  /// Perform background check for token refresh
  Future<void> _performBackgroundCheck() async {
    if (_isRefreshing) {
      logger.d('Skipping background check: refresh already in progress');
      return;
    }
    
    _performanceMonitor.startOperation('background_check');
    bool operationEnded = false;
    
    try {
      // Check if user is authenticated
      if (!_authService.isAuthenticated) {
        logger.d('Skipping background check: user not authenticated');
        _performanceMonitor.endOperation('background_check');
        operationEnded = true;
        return;
      }
      
      // Check if token needs refresh
      final shouldRefresh = await _tokenManager.shouldRefreshToken();
      if (!shouldRefresh) {
        _retryCount = 0; // Reset retry count on success
        _performanceMonitor.endOperation('background_check');
        operationEnded = true;
        return;
      }
      
      logger.i('Background token refresh needed');
      await _performBackgroundRefresh();
      _performanceMonitor.endOperation('background_check');
      operationEnded = true;
      
    } catch (e) {
      if (!operationEnded) {
        _performanceMonitor.endOperation('background_check');
      }
      logger.e('Background check error: $e');
      _handleRefreshError();
    }
  }

  /// Perform background token refresh với performance tracking
  Future<void> _performBackgroundRefresh() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    _performanceMonitor.startOperation('background_token_refresh');
    
    try {
      logger.i('Starting background token refresh');
      
      final success = await _authService.refreshToken();
      
      if (success) {
        _successfulRefreshes++;
        _lastSuccessfulRefresh = DateTime.now();
        logger.i('Background token refresh successful');
        _retryCount = 0; // Reset retry count on success
        _stopNetworkRetry(); // Stop any retry timer
        
        _performanceMonitor.recordOperation(
          'background_token_refresh',
          Duration.zero,
          success: true,
        );
        
        _recordServiceHealth(true, 'Token refresh successful', metrics: {
          'successful_refreshes': _successfulRefreshes,
          'failed_refreshes': _failedRefreshes,
          'last_successful_refresh': _lastSuccessfulRefresh?.toIso8601String(),
        });
      } else {
        _failedRefreshes++;
        _lastFailedRefresh = DateTime.now();
        logger.w('Background token refresh failed');
        _handleRefreshError();
        
        _performanceMonitor.recordOperation(
          'background_token_refresh',
          Duration.zero,
          success: false,
          error: 'Token refresh returned false',
        );
      }
      
    } catch (e) {
      _failedRefreshes++;
      _lastFailedRefresh = DateTime.now();
      logger.e('Background token refresh error: $e');
      _handleRefreshError();
      
      _performanceMonitor.recordOperation(
        'background_token_refresh',
        Duration.zero,
        success: false,
        error: e.toString(),
      );
    } finally {
      _isRefreshing = false;
      _performanceMonitor.endOperation('background_token_refresh');
    }
  }

  /// Handle refresh error with retry logic
  void _handleRefreshError() {
    _retryCount++;
    
    if (_retryCount <= maxRetryAttempts) {
      // Calculate exponential backoff delay
      final delay = Duration(seconds: _calculateRetryDelay());
      logger.w('Background refresh failed. Retry ${_retryCount}/$maxRetryAttempts in ${delay.inSeconds}s');
      
      _recordServiceHealth(false, 'Refresh failed, retrying', metrics: {
        'retry_count': _retryCount,
        'max_retries': maxRetryAttempts,
        'next_retry_seconds': delay.inSeconds,
      });
      
      _scheduleRetry(delay);
    } else {
      logger.e('Background refresh failed after $maxRetryAttempts attempts. Stopping retries.');
      _retryCount = 0;
      
      _recordServiceHealth(false, 'Max retries exceeded', error: 'Failed after $maxRetryAttempts attempts');
      
      // Force logout if all retries failed
      _forceLogoutOnMaxRetries();
    }
  }

  /// Record service health status
  void _recordServiceHealth(bool isHealthy, String status, {
    Map<String, dynamic>? metrics,
    String? error,
  }) {
    _performanceMonitor.recordServiceHealth(
      'background_token_refresh_service',
      isHealthy: isHealthy,
      status: status,
      metrics: {
        'is_monitoring': _isMonitoring,
        'is_refreshing': _isRefreshing,
        'retry_count': _retryCount,
        'successful_refreshes': _successfulRefreshes,
        'failed_refreshes': _failedRefreshes,
        'last_successful_refresh': _lastSuccessfulRefresh?.toIso8601String(),
        'last_failed_refresh': _lastFailedRefresh?.toIso8601String(),
        ...metrics ?? {},
      },
      error: error,
    );
  }

  /// Start health check monitoring
  void _startHealthCheckMonitoring() {
    _healthCheckTimer?.cancel();
    
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performHealthCheck();
    });
  }

  /// Perform health check
  void _performHealthCheck() {
    try {
      final now = DateTime.now();
      
      // Check if service is running normally
      bool isHealthy = _isInitialized && 
                      (_isMonitoring || !_authService.isAuthenticated);
      
      // Check for stuck refresh operations
      if (_isRefreshing && _lastFailedRefresh != null) {
        final timeSinceLastRefresh = now.difference(_lastFailedRefresh!);
        if (timeSinceLastRefresh.inMinutes > 10) {
          isHealthy = false;
          logger.w('Background refresh appears stuck');
        }
      }
      
      // Check success rate
      final totalRefreshes = _successfulRefreshes + _failedRefreshes;
      if (totalRefreshes > 10) {
        final successRate = _successfulRefreshes / totalRefreshes;
        if (successRate < 0.7) {
          isHealthy = false;
          logger.w('Low token refresh success rate: ${(successRate * 100).toStringAsFixed(1)}%');
        }
      }
      
      _recordServiceHealth(
        isHealthy,
        isHealthy ? 'Service healthy' : 'Service unhealthy',
        metrics: {
          'total_refreshes': totalRefreshes,
          'success_rate': totalRefreshes > 0 ? (_successfulRefreshes / totalRefreshes) : 0,
          'uptime_minutes': _lastSuccessfulRefresh != null 
              ? now.difference(_lastSuccessfulRefresh!).inMinutes 
              : null,
        },
      );
      
    } catch (e) {
      logger.e('Health check failed: $e');
      _recordServiceHealth(false, 'Health check failed', error: e.toString());
    }
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'is_initialized': _isInitialized,
      'is_monitoring': _isMonitoring,
      'is_refreshing': _isRefreshing,
      'retry_count': _retryCount,
      'successful_refreshes': _successfulRefreshes,
      'failed_refreshes': _failedRefreshes,
      'last_successful_refresh': _lastSuccessfulRefresh?.toIso8601String(),
      'last_failed_refresh': _lastFailedRefresh?.toIso8601String(),
      'success_rate': (_successfulRefreshes + _failedRefreshes) > 0 
          ? _successfulRefreshes / (_successfulRefreshes + _failedRefreshes)
          : 0,
      'performance_metrics': _performanceMonitor.getOperationStats('background_token_refresh'),
    };
  }

  /// Calculate exponential backoff delay
  int _calculateRetryDelay() {
    // Exponential backoff: 2^retryCount * 30 seconds (max 5 minutes)
    final delay = (1 << (_retryCount - 1)) * 30; // 30s, 60s, 120s, 240s
    return delay > 300 ? 300 : delay; // Cap at 5 minutes
  }

  /// Schedule retry with delay
  void _scheduleRetry(Duration delay) {
    _stopNetworkRetry();
    
    _networkRetryTimer = Timer(delay, () async {
      logger.d('Executing scheduled retry');
      await _performBackgroundRefresh();
    });
  }

  /// Force logout after max retries
  Future<void> _forceLogoutOnMaxRetries() async {
    try {
      logger.w('Forcing logout due to token refresh failures');
      await _authService.logout();
    } catch (e) {
      logger.e('Error during force logout: $e');
    }
  }

  /// Stop background monitoring
  void _stopBackgroundMonitoring() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    logger.d('Background token refresh monitoring stopped');
  }

  /// Stop network retry timer
  void _stopNetworkRetry() {
    _networkRetryTimer?.cancel();
    _networkRetryTimer = null;
  }

  /// Force immediate refresh
  Future<bool> forceRefresh() async {
    logger.i('Force background refresh requested');
    
    if (_isRefreshing) {
      logger.w('Refresh already in progress');
      return false;
    }
    
    await _performBackgroundRefresh();
    return !_isRefreshing; // Success if no longer refreshing
  }

  /// Check if background refresh is active
  bool get isRefreshing => _isRefreshing;
  
  /// Get current retry count
  int get retryCount => _retryCount;
  
  /// Check if background monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Resume monitoring (called by AppLifecycleService)
  void resume() {
    if (_isInitialized && !_isMonitoring) {
      _startBackgroundMonitoring();
      logger.i('Background token refresh monitoring resumed');
    }
  }

  /// Pause monitoring (called by AppLifecycleService)
  void pause() {
    _stopBackgroundMonitoring();
    _recordServiceHealth(false, 'Paused');
    logger.i('Background token refresh monitoring paused');
  }

  /// Dispose với cleanup
  Future<void> dispose() async {
    _stopBackgroundMonitoring();
    _stopNetworkRetry();
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    
    _performanceMonitor.recordServiceHealth(
      'background_token_refresh_service',
      isHealthy: false,
      status: 'Disposed',
    );
    
    _isInitialized = false;
    _isMonitoring = false;
    
    logger.i('BackgroundTokenRefreshService disposed');
  }

  /// Debug: Print current service state
  void debugCurrentState() {
    if (!kDebugMode) return;
    
    logger.d('=== BACKGROUND REFRESH SERVICE DEBUG ===');
    logger.d('Is Initialized: $_isInitialized');
    logger.d('Is Refreshing: $_isRefreshing');
    logger.d('Retry Count: $_retryCount');
    logger.d('Is Monitoring: $isMonitoring');
    logger.d('Background Timer: ${_backgroundTimer != null ? 'Active' : 'Inactive'}');
    logger.d('Retry Timer: ${_networkRetryTimer != null ? 'Active' : 'Inactive'}');
    logger.d('=======================================');
  }
} 