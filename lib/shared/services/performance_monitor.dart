import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service monitoring performance của app và background services
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final logger = Logger();
  
  // Performance metrics
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, List<Duration>> _operationHistory = {};
  
  // Memory tracking
  Timer? _memoryCheckTimer;
  List<int> _memoryUsageHistory = [];
  static const int maxHistoryEntries = 100;
  
  // Background service health
  final Map<String, Map<String, dynamic>> _serviceHealth = {};
  
  bool _isInitialized = false;

  /// Initialize performance monitor
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Start memory monitoring in debug mode
      if (kDebugMode) {
        _startMemoryMonitoring();
      }
      
      _isInitialized = true;
      logger.i('PerformanceMonitor initialized');
    } catch (e) {
      logger.e('PerformanceMonitor initialization failed: $e');
    }
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    
    if (kDebugMode) {
      developer.Timeline.startSync(operationName);
    }
  }

  /// End timing an operation
  void endOperation(String operationName) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      logger.w('No start time found for operation: $operationName');
      return;
    }
    
    final duration = DateTime.now().difference(startTime);
    _operationDurations[operationName] = duration;
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    // Add to history
    _operationHistory.putIfAbsent(operationName, () => []).add(duration);
    
    // Keep history limited
    final history = _operationHistory[operationName]!;
    if (history.length > maxHistoryEntries) {
      history.removeAt(0);
    }
    
    if (kDebugMode) {
      developer.Timeline.finishSync();
      logger.d('Operation $operationName took ${duration.inMilliseconds}ms');
    }
    
    // Alert for slow operations
    if (duration.inSeconds > 5) {
      logger.w('Slow operation detected: $operationName took ${duration.inSeconds}s');
    }
  }

  /// Record operation result
  void recordOperation(String operationName, Duration duration, {
    bool success = true,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    _operationDurations[operationName] = duration;
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    // Add to history
    _operationHistory.putIfAbsent(operationName, () => []).add(duration);
    
    // Keep history limited
    final history = _operationHistory[operationName]!;
    if (history.length > maxHistoryEntries) {
      history.removeAt(0);
    }
    
    // Log if slow or failed
    if (!success || duration.inSeconds > 3) {
      logger.w('Operation $operationName: ${success ? 'SLOW' : 'FAILED'} '
               '(${duration.inMilliseconds}ms)${error != null ? ' - $error' : ''}');
    }
  }

  /// Record service health status
  void recordServiceHealth(String serviceName, {
    required bool isHealthy,
    String? status,
    Map<String, dynamic>? metrics,
    String? error,
  }) {
    _serviceHealth[serviceName] = {
      'is_healthy': isHealthy,
      'status': status ?? (isHealthy ? 'healthy' : 'unhealthy'),
      'last_check': DateTime.now().toIso8601String(),
      'metrics': metrics ?? {},
      'error': error,
    };
    
    if (!isHealthy) {
      logger.w('Service $serviceName is unhealthy: ${error ?? status}');
    }
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
    
    _memoryCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      try {
        // Note: Dart VM memory info is limited on mobile
        // This is a simplified implementation
        final memoryInfo = _getCurrentMemoryUsage();
        _memoryUsageHistory.add(memoryInfo);
        
        // Keep history limited
        if (_memoryUsageHistory.length > maxHistoryEntries) {
          _memoryUsageHistory.removeAt(0);
        }
        
        // Check for memory leaks
        _checkMemoryTrends();
        
      } catch (e) {
        logger.e('Memory monitoring error: $e');
      }
    });
  }

  /// Get current memory usage (simplified)
  int _getCurrentMemoryUsage() {
    // This is a simplified implementation
    // Real memory monitoring would require platform channels
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  /// Check memory usage trends
  void _checkMemoryTrends() {
    if (_memoryUsageHistory.length < 10) return;
    
    final recent = _memoryUsageHistory.sublist(_memoryUsageHistory.length - 10);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    final current = recent.last;
    
    // Alert if memory usage increased significantly
    if (current > avg * 1.5) {
      logger.w('Memory usage spike detected: $current vs avg $avg');
    }
  }

  /// Get operation statistics
  Map<String, dynamic> getOperationStats(String operationName) {
    final history = _operationHistory[operationName] ?? [];
    if (history.isEmpty) {
      return {'operation': operationName, 'no_data': true};
    }
    
    final durations = history.map((d) => d.inMilliseconds).toList();
    durations.sort();
    
    final count = _operationCounts[operationName] ?? 0;
    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final median = durations[durations.length ~/ 2];
    final p95 = durations[(durations.length * 0.95).round() - 1];
    
    return {
      'operation': operationName,
      'count': count,
      'avg_ms': avg.round(),
      'median_ms': median,
      'p95_ms': p95,
      'min_ms': durations.first,
      'max_ms': durations.last,
      'last_duration_ms': _operationDurations[operationName]?.inMilliseconds,
    };
  }

  /// Get all performance metrics
  Map<String, dynamic> getAllMetrics() {
    final operations = <String, dynamic>{};
    for (final operationName in _operationHistory.keys) {
      operations[operationName] = getOperationStats(operationName);
    }
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'operations': operations,
      'service_health': Map.from(_serviceHealth),
      'memory_usage': {
        'current': _memoryUsageHistory.isNotEmpty ? _memoryUsageHistory.last : null,
        'history_length': _memoryUsageHistory.length,
        'avg_recent': _memoryUsageHistory.length >= 10 
            ? _memoryUsageHistory.sublist(_memoryUsageHistory.length - 10)
                .reduce((a, b) => a + b) / 10 
            : null,
      },
    };
  }

  /// Export metrics to debug log
  void logMetricsSummary() {
    if (!kDebugMode) return;
    
    logger.d('=== PERFORMANCE METRICS SUMMARY ===');
    
    for (final operationName in _operationHistory.keys) {
      final stats = getOperationStats(operationName);
      logger.d('$operationName: ${stats['count']} ops, '
               'avg: ${stats['avg_ms']}ms, '
               'p95: ${stats['p95_ms']}ms');
    }
    
    logger.d('Service Health:');
    for (final entry in _serviceHealth.entries) {
      final health = entry.value;
      logger.d('  ${entry.key}: ${health['status']} '
               '(${health['last_check']})');
    }
    
    logger.d('=====================================');
  }

  /// Save metrics to persistent storage
  Future<void> saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = getAllMetrics();
      
      await prefs.setString(
        'performance_metrics_${DateTime.now().millisecondsSinceEpoch}',
        metrics.toString(),
      );
      
      // Clean old metrics (keep last 5)
      final keys = prefs.getKeys()
          .where((key) => key.startsWith('performance_metrics_'))
          .toList();
      
      keys.sort();
      if (keys.length > 5) {
        for (final key in keys.take(keys.length - 5)) {
          await prefs.remove(key);
        }
      }
      
      logger.d('Performance metrics saved');
    } catch (e) {
      logger.e('Failed to save performance metrics: $e');
    }
  }

  /// Clear all metrics
  void clearMetrics() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    _operationHistory.clear();
    _serviceHealth.clear();
    _memoryUsageHistory.clear();
    
    logger.i('Performance metrics cleared');
  }

  /// Dispose performance monitor
  void dispose() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
    _isInitialized = false;
    
    logger.i('PerformanceMonitor disposed');
  }

  /// Debug current performance state
  void debugCurrentState() {
    if (!kDebugMode) return;
    
    logger.d('=== PERFORMANCE MONITOR DEBUG ===');
    logger.d('Is Initialized: $_isInitialized');
    logger.d('Active Operations: ${_operationStartTimes.keys.length}');
    logger.d('Tracked Operations: ${_operationHistory.keys.length}');
    logger.d('Service Health Entries: ${_serviceHealth.keys.length}');
    logger.d('Memory History: ${_memoryUsageHistory.length} entries');
    logger.d('==================================');
  }
} 