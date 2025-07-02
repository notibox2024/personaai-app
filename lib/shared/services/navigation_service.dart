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
  
  /// Get current context
  BuildContext? get currentContext => navigatorKey.currentContext;
  
  /// Get current navigator state
  NavigatorState? get navigator => navigatorKey.currentState;

  /// Navigate to login page khi cần authentication
  Future<void> navigateToLogin({
    bool clearStack = true,
    Map<String, dynamic>? arguments,
  }) async {
    try {
      if (navigator == null) {
        logger.e('Navigator not available - cannot navigate to login');
        return;
      }

      logger.i('Navigating to login page (clearStack: $clearStack)');
      
      if (clearStack) {
        // Clear navigation stack và navigate to login
        await navigator!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: arguments,
        );
      } else {
        // Just push login page
        await navigator!.pushNamed('/login', arguments: arguments);
      }
    } catch (e) {
      logger.e('Error navigating to login: $e');
    }
  }

  /// Navigate to home page sau khi login thành công
  Future<void> navigateToHome({
    bool clearStack = true,
  }) async {
    try {
      if (navigator == null) {
        logger.e('Navigator not available - cannot navigate to home');
        return;
      }

      logger.i('Navigating to home page (clearStack: $clearStack)');
      
      if (clearStack) {
        // Clear navigation stack và navigate to home
        await navigator!.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      } else {
        // Just push home page
        await navigator!.pushNamed('/');
      }
    } catch (e) {
      logger.e('Error navigating to home: $e');
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

  /// Show dialog với authentication required message
  Future<void> showAuthRequiredDialog({
    String title = 'Phiên đăng nhập hết hạn',
    String message = 'Vui lòng đăng nhập lại để tiếp tục sử dụng ứng dụng.',
    String confirmText = 'Đăng nhập',
    String? cancelText,
  }) async {
    final context = currentContext;
    if (context == null) {
      logger.e('Context not available - cannot show auth required dialog');
      await navigateToLogin();
      return;
    }

    try {
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
        await navigateToLogin();
      }
    } catch (e) {
      logger.e('Error showing auth required dialog: $e');
      // Fallback - direct navigate to login
      await navigateToLogin();
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

  /// Check if can navigate back
  bool canPop() {
    return navigator?.canPop() ?? false;
  }

  /// Get current route name (if available)
  String? getCurrentRouteName() {
    try {
      final route = ModalRoute.of(currentContext!);
      return route?.settings.name;
    } catch (e) {
      logger.d('Could not get current route name: $e');
      return null;
    }
  }

  /// Debug current navigation state
  void debugNavigationState() {
    logger.d('=== NAVIGATION DEBUG ===');
    logger.d('Has Navigator: ${navigator != null}');
    logger.d('Has Context: ${currentContext != null}');
    logger.d('Can Pop: ${canPop()}');
    logger.d('Current Route: ${getCurrentRouteName() ?? 'Unknown'}');
    logger.d('========================');
  }
} 