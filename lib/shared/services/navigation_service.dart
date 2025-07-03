import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Service quản lý navigation cho toàn app
/// Đặc biệt handle navigation khi cần authentication
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final logger = Logger();
  
  // Global navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Navigation state management để tránh conflicts
  bool _isNavigating = false;
  bool _isShowingAuthDialog = false;
  String? _lastNavigationTarget;
  String? _currentRoute; // Track current route manually
  
  /// Get current context
  BuildContext? get currentContext => navigatorKey.currentContext;
  
  /// Get current navigator state
  NavigatorState? get navigator => navigatorKey.currentState;

  /// Get current route name (safer method with manual tracking)
  String? getCurrentRouteName() {
    try {
      // Try to get from manual tracking first
      if (_currentRoute != null) {
        logger.d('Current route from tracking: $_currentRoute');
        return _currentRoute;
      }
      
      // Fallback to ModalRoute
      final context = navigatorKey.currentContext;
      if (context != null) {
        final route = ModalRoute.of(context)?.settings.name;
        logger.d('Current route from ModalRoute: $route');
        return route;
      }
      
      logger.w('Could not determine current route');
      return null;
    } catch (e) {
      logger.w('Could not get current route name: $e');
      return null;
    }
  }

  /// Navigate to login page khi cần authentication
  Future<void> navigateToLogin({
    bool clearStack = true,
    Map<String, dynamic>? arguments,
    bool force = false,
  }) async {
    // Prevent duplicate navigation calls, but allow force override
    if (_isNavigating && !force) {
      logger.w('Navigation to login already in progress, skipping (use force=true to override)');
      return;
    }

    // For logout scenarios, always allow navigation even if recent target was login
    if (_lastNavigationTarget == '/login' && !force && !clearStack) {
      logger.w('Already navigated to login recently, skipping (use force=true to override)');
      return;
    }

    try {
      _isNavigating = true;
      _lastNavigationTarget = '/login';
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        logger.e('Navigator state is null - cannot navigate to login');
        return;
      }

      logger.i('🚀 Navigating to login page (clearStack: $clearStack, force: $force, context: ${navigatorKey.currentContext != null})');
      
      if (clearStack) {
        // Clear navigation stack và navigate to login
        await navigator.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: arguments,
        );
        logger.i('✅ Login navigation with clearStack completed');
      } else {
        // Just push login page
        await navigator.pushNamed('/login', arguments: arguments);
        logger.i('✅ Login navigation (push) completed');
      }
      
      // Update current route tracking
      _currentRoute = '/login';
      
      // Reset auth dialog flag nếu có
      _isShowingAuthDialog = false;
      
    } catch (e) {
      logger.e('❌ Error navigating to login: $e');
      // Try fallback navigation
      try {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          logger.i('✅ Fallback login navigation completed');
        }
      } catch (fallbackError) {
        logger.e('❌ Fallback navigation also failed: $fallbackError');
      }
    } finally {
      _isNavigating = false;
      // Reset target after delay để cho phép navigation khác
      Future.delayed(const Duration(seconds: 1), () {
        _lastNavigationTarget = null;
      });
    }
  }

  /// Navigate to home page sau khi login thành công
  Future<void> navigateToHome({
    bool clearStack = true,
    bool force = false,
  }) async {
    // Prevent duplicate navigation calls
    if (_isNavigating && !force) {
      logger.w('Navigation to home already in progress, skipping');
      return;
    }

    if (_lastNavigationTarget == '/main' && !force) {
      logger.w('Already navigated to home recently, skipping');
      return;
    }

    try {
      _isNavigating = true;
      _lastNavigationTarget = '/main';
      
      if (navigator == null) {
        logger.e('Navigator not available - cannot navigate to home');
        return;
      }

      logger.i('Navigating to home page (clearStack: $clearStack, force: $force)');
      
      if (clearStack) {
        // Clear navigation stack và navigate to home
        await navigator!.pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
        );
      } else {
        // Just push home page
        await navigator!.pushNamed('/main');
      }
      
      // Update current route tracking
      _currentRoute = '/main';
    } catch (e) {
      logger.e('Error navigating to home: $e');
    } finally {
      _isNavigating = false;
      // Reset target after delay
      Future.delayed(const Duration(seconds: 2), () {
        _lastNavigationTarget = null;
      });
    }
  }

  /// Pop current route
  void pop([dynamic result]) {
    try {
      if (navigator?.canPop() == true) {
        navigator!.pop(result);
      }
    } catch (e) {
      logger.e('Error popping route: $e');
    }
  }

  /// Show dialog với authentication required message - IMPROVED
  Future<void> showAuthRequiredDialog({
    String title = 'Phiên đăng nhập hết hạn',
    String message = 'Vui lòng đăng nhập lại để tiếp tục sử dụng ứng dụng.',
    String confirmText = 'Đăng nhập',
    String? cancelText,
    bool force = false,
  }) async {
    // Prevent multiple auth dialogs
    if (_isShowingAuthDialog && !force) {
      logger.w('Auth dialog already showing, skipping');
      return;
    }

    final context = currentContext;
    if (context == null) {
      logger.e('Context not available - cannot show auth required dialog');
      await navigateToLogin(force: force);
      return;
    }

    try {
      _isShowingAuthDialog = true;
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: cancelText != null,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              if (cancelText != null)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelText),
                ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText),
              ),
            ],
          );
        },
      );

      // Navigate to login if user confirmed
      if (result == true) {
        await navigateToLogin(force: true); // Force navigation after dialog
      }
    } catch (e) {
      logger.e('Error showing auth required dialog: $e');
      // Fallback - direct navigate to login
      await navigateToLogin(force: force);
    } finally {
      _isShowingAuthDialog = false;
    }
  }

  /// Generic navigation method
  Future<dynamic> pushNamed(
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (navigator == null) {
        logger.e('Navigator not available');
        return null;
      }
      
      return await navigator!.pushNamed(routeName, arguments: arguments);
    } catch (e) {
      logger.e('Error navigating to $routeName: $e');
      return null;
    }
  }

  /// Generic navigation with route replacement
  Future<dynamic> pushReplacementNamed(
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (navigator == null) {
        logger.e('Navigator not available');
        return null;
      }
      
      return await navigator!.pushReplacementNamed(routeName, arguments: arguments);
    } catch (e) {
      logger.e('Error replacing route to $routeName: $e');
      return null;
    }
  }

  /// Navigation with clear stack
  Future<dynamic> pushNamedAndRemoveUntil(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) async {
    try {
      if (navigator == null) {
        logger.e('Navigator not available');
        return null;
      }
      
      return await navigator!.pushNamedAndRemoveUntil(
        routeName, 
        predicate, 
        arguments: arguments,
      );
    } catch (e) {
      logger.e('Error navigating and clearing stack to $routeName: $e');
      return null;
    }
  }

  /// Reset navigation flags (for testing hoặc manual reset)
  void resetNavigationFlags() {
    _isNavigating = false;
    _isShowingAuthDialog = false;
    _lastNavigationTarget = null;
    _currentRoute = null;
    logger.d('Navigation flags reset');
  }

  /// Manually set current route (for special cases)
  void setCurrentRoute(String route) {
    _currentRoute = route;
    logger.d('Current route manually set to: $route');
  }

  /// Debug navigation state
  void debugNavigationState() {
    logger.d('=== NAVIGATION SERVICE DEBUG ===');
    logger.d('Is Navigating: $_isNavigating');
    logger.d('Is Showing Auth Dialog: $_isShowingAuthDialog');
    logger.d('Last Navigation Target: $_lastNavigationTarget');
    logger.d('Current Route: ${getCurrentRouteName()}');
    logger.d('=================================');
  }
} 