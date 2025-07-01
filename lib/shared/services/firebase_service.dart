import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../../features/notifications/data/models/notification_item.dart';
import '../../features/notifications/data/repositories/local_notification_repository.dart';
import 'background_message_handler.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseMessaging _messaging;
  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  late FirebaseInAppMessaging _inAppMessaging;
  late FirebaseRemoteConfig _remoteConfig;
  late FlutterLocalNotificationsPlugin _localNotifications;
  late LocalNotificationRepository _notificationRepository;
  final logger = Logger();
  // StreamController for real-time notification updates
  final StreamController<NotificationItem> _messageController = StreamController<NotificationItem>.broadcast();
  
  /// Stream of received notifications
  Stream<NotificationItem> get onMessageReceived => _messageController.stream;
  
  /// Callback khi nhận được notification (app running)
  Function(NotificationItem)? onNotificationReceived;
  
  /// Callback khi user tap notification
  Function(NotificationItem)? onNotificationTapped;
  
  /// Callback khi FCM token update
  Function(String)? onTokenRefresh;

  // Initialize Firebase services
  Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _inAppMessaging = FirebaseInAppMessaging.instance;
    _remoteConfig = FirebaseRemoteConfig.instance;
    _notificationRepository = LocalNotificationRepository();
    
    await _initializeLocalNotifications();
    await _initializeMessaging();
    await _initializeAnalytics();
    await _initializeCrashlytics();
    await _initializeInAppMessaging();
    await _initializeRemoteConfig();
    
    // Initialize background message handling
    await BackgroundNotificationService.initialize();
  }
  
  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
    
    if (kDebugMode) {
      logger.i('Local notifications initialized');
    }
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeMessaging() async {
    // Request permission cho notifications (iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      logger.i('User granted permission: ${settings.authorizationStatus}');
    }

    // Lấy FCM token với error handling cho iOS
    try {
      String? token = await _messaging.getToken();
      print('FCM Token: $token');

    } catch (e) {
      if (kDebugMode) {
        logger.e('Error getting FCM token: $e');
        logger.e('This is normal on iOS simulator or when APNS is not properly configured');
      }
      // Continue initialization even if token retrieval fails
    }

    // Lắng nghe token refresh
    _messaging.onTokenRefresh.listen((String token) {
      if (kDebugMode) {
        logger.i('FCM Token refreshed: $token');
      }
      // Notify app about token update
      onTokenRefresh?.call(token);
    });

    // Xử lý message khi app đang foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        logger.i('Got a message whilst in the foreground!');
        logger.i('Message data: ${message.data}');

        if (message.notification != null) {
          logger.i('Message also contained a notification: ${message.notification}');
        }
      }
      
      // TODO: Hiển thị local notification hoặc update UI
      _handleForegroundMessage(message);
    });

    // Xử lý message khi user tap vào notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        logger.i('A new onMessageOpenedApp event was published!');
      }
      
      // TODO: Navigate to specific screen based on message data
      _handleMessageOpenedApp(message);
    });

    // Kiểm tra message khi app được mở từ terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        logger.i('App opened from terminated state with message: ${initialMessage.messageId}');
      }
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Initialize Firebase Analytics
  Future<void> _initializeAnalytics() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    
    if (kDebugMode) {
      logger.i('Firebase Analytics initialized');
    }
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) async {
    try {
      final payload = response.payload;
      if (payload == null) return;
      
      // Parse notification ID from payload
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final notificationId = data['notification_id'] as String?;
      
      if (notificationId != null) {
        // Get notification from database
        final notification = await _notificationRepository.getNotification(notificationId);
        if (notification != null) {
          // Mark as read
          await _notificationRepository.updateNotificationStatus(
            notificationId,
            NotificationStatus.read,
          );
          
          // Notify app
          onNotificationTapped?.call(notification);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error handling local notification tap: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        logger.i('Received foreground message: ${message.messageId}');
        logger.i('Data: ${message.data}');
      }
      
      // Convert to NotificationItem
      final notificationItem = _convertToNotificationItem(message);
      
      // Save to local database
      await _notificationRepository.insertNotification(notificationItem);
      
      // Show local notification
      await _showLocalNotification(message);
      
      // Notify app about new notification
      onNotificationReceived?.call(notificationItem);
      
      // Emit to stream for BLoC
      _messageController.add(notificationItem);
      
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error handling foreground message: $e');
      }
    }
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        logger.i('Message opened app: ${message.messageId}');
      }
      
      // Convert to NotificationItem
      final notificationItem = _convertToNotificationItem(message);
      
      // Save to local database (if not already saved)
      final existing = await _notificationRepository.getNotification(notificationItem.id);
      if (existing == null) {
        await _notificationRepository.insertNotification(notificationItem);
      }
      
      // Mark as read since user tapped it
      await _notificationRepository.updateNotificationStatus(
        notificationItem.id,
        NotificationStatus.read,
      );
      
      // Notify app about notification tap
      onNotificationTapped?.call(notificationItem);
      
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error handling message opened app: $e');
      }
    }
  }
  
  /// Convert RemoteMessage to NotificationItem
  NotificationItem _convertToNotificationItem(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    
    // Parse notification type
    final typeString = data['type'] ?? 'general';
    final type = _parseNotificationType(typeString);
    
    // Parse priority
    final priorityString = data['priority'] ?? 'normal';
    final priority = _parseNotificationPriority(priorityString);
    
    // Parse metadata
    Map<String, dynamic>? metadata;
    if (data.containsKey('metadata')) {
      try {
        metadata = jsonDecode(data['metadata']) as Map<String, dynamic>;
      } catch (e) {
        metadata = null;
      }
    }
    
    return NotificationItem(
      id: message.messageId ?? _generateNotificationId(),
      title: notification?.title ?? data['title'] ?? 'Thông báo',
      message: notification?.body ?? data['body'] ?? '',
      type: type,
      priority: priority,
      createdAt: DateTime.now(),
      actionUrl: data['action_url'],
      metadata: metadata,
      imageUrl: notification?.android?.imageUrl ?? data['image_url'],
      senderId: data['sender_id'],
      senderName: data['sender_name'],
      isActionable: data['is_actionable'] == 'true' || data['is_actionable'] == '1',
    );
  }
  
  /// Parse notification type from string
  NotificationType _parseNotificationType(String typeString) {
    try {
      return NotificationType.values.firstWhere(
        (type) => type.name == typeString,
      );
    } catch (e) {
      return NotificationType.general;
    }
  }
  
  /// Parse notification priority from string
  NotificationPriority _parseNotificationPriority(String priorityString) {
    try {
      return NotificationPriority.values.firstWhere(
        (priority) => priority.name == priorityString,
      );
    } catch (e) {
      return NotificationPriority.normal;
    }
  }
  
  /// Generate unique notification ID if not provided
  String _generateNotificationId() {
    return 'fcm_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;
      
      // Create payload with notification ID
      final payload = jsonEncode({
        'notification_id': message.messageId ?? _generateNotificationId(),
        'action_url': message.data['action_url'],
      });
      
      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'personaai_notifications',
        'PersonaAI Notifications',
        channelDescription: 'Thông báo từ PersonaAI',
        importance: Importance.high,
        priority: Priority.high,
        ticker: notification.title,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF4100), // Brand color
        showWhen: true,
        styleInformation: notification.body != null
            ? BigTextStyleInformation(notification.body!)
            : null,
      );
      
      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Show notification
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: payload,
      );
      
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error showing local notification: $e');
      }
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      logger.i('Subscribed to topic: $topic');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      logger.i('Unsubscribed from topic: $topic');
    }
  }

  // Log analytics event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // Set user properties
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Common analytics events
  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  Future<void> logLogout() async {
    await logEvent('logout');
  }

  Future<void> logAttendanceCheck(String type) async {
    await logEvent('attendance_check', parameters: {'type': type});
  }

  Future<void> logScreenVisit(String screenName) async {
    await logScreenView(screenName);
  }

  // Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    
    if (kDebugMode) {
      logger.i('Firebase Crashlytics initialized');
    }
  }

  // ============== CRASHLYTICS METHODS ==============

  // Set user identifier
  Future<void> setCrashlyticsUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  // Set custom key
  Future<void> setCrashlyticsCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  // Log non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  // Log message to crashlytics
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  // Check if crashlytics collection is enabled
  bool get isCrashlyticsCollectionEnabled =>
      _crashlytics.isCrashlyticsCollectionEnabled;

  // Send unhandled exception
  Future<void> recordFlutterError(FlutterErrorDetails errorDetails) async {
    await _crashlytics.recordFlutterError(errorDetails);
  }

  // Send handled exception
  Future<void> recordException(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  // Common crashlytics logging methods
  Future<void> logApiError(String endpoint, String error) async {
    await setCrashlyticsCustomKey('api_endpoint', endpoint);
    await log('API Error: $endpoint - $error');
  }

  Future<void> logAuthError(String authMethod, String error) async {
    await setCrashlyticsCustomKey('auth_method', authMethod);
    await log('Auth Error: $authMethod - $error');
  }

  Future<void> logAttendanceError(String action, String error) async {
    await setCrashlyticsCustomKey('attendance_action', action);
    await log('Attendance Error: $action - $error');
  }

  // Initialize Firebase In-App Messaging
  Future<void> _initializeInAppMessaging() async {
    // Enable automatic data collection
    await _inAppMessaging.setAutomaticDataCollectionEnabled(true);
    
    // Enable message display
    await _inAppMessaging.setMessagesSuppressed(false);
    
    if (kDebugMode) {
      logger.i('Firebase In-App Messaging initialized');
    }
  }

  // Initialize Firebase Remote Config
  Future<void> _initializeRemoteConfig() async {
    try {
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode 
            ? const Duration(seconds: 5)  // Short interval for development
            : const Duration(hours: 1),   // Production interval
      ));

      // Set default values
      await _remoteConfig.setDefaults(_getDefaultConfigValues());

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();

      if (kDebugMode) {
        logger.i('Firebase Remote Config initialized');
        logger.i('Config values: ${_remoteConfig.getAll()}');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error initializing Remote Config: $e');
      }
    }
  }

  /// Get default config values
  Map<String, dynamic> _getDefaultConfigValues() {
    return {
      // App configuration
      'app_version_required': '1.0.0',
      'maintenance_mode': false,
      'maintenance_message': 'Ứng dụng đang được bảo trì. Vui lòng thử lại sau.',
      
      // Feature flags
      'enable_biometric_login': true,
      'enable_offline_mode': false,
      'enable_dark_theme': true,
      'enable_push_notifications': true,
      'enable_location_tracking': true,
      
      // UI configuration
      'max_attendance_distance': 100, // meters
      'auto_check_out_hours': 8,
      'break_time_minutes': 60,
      
      // API configuration
      'api_timeout_seconds': 30,
      'max_retry_attempts': 3,
      'cache_duration_hours': 24,
      
      // API endpoints
      'backend_api_url': 'http:/192.168.2.62:8097',
      'data_api_url': 'http://192.168.2.62:3300',
      
      // Notification settings
      'notification_quiet_hours_start': 22,
      'notification_quiet_hours_end': 6,
      'max_daily_notifications': 10,
      
      // Training configuration
      'training_session_duration': 30, // minutes
      'enable_training_reminders': true,
      'training_progress_sync_interval': 300, // seconds
    };
  }

  // ============== IN-APP MESSAGING METHODS ==============

  // Trigger in-app message programmatically
  Future<void> triggerEvent(String eventName, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
    if (kDebugMode) {
      logger.i('Triggered in-app messaging event: $eventName');
    }
  }

  // Suppress in-app messages (useful for specific screens)
  Future<void> suppressInAppMessages(bool suppress) async {
    await _inAppMessaging.setMessagesSuppressed(suppress);
    if (kDebugMode) {
      logger.i('In-app messages ${suppress ? 'suppressed' : 'enabled'}');
    }
  }

  // Enable/disable automatic data collection for in-app messaging
  Future<void> setInAppMessagingDataCollection(bool enabled) async {
    await _inAppMessaging.setAutomaticDataCollectionEnabled(enabled);
    if (kDebugMode) {
      logger.i('In-app messaging data collection: ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // Common in-app messaging triggers
  Future<void> triggerWelcomeMessage() async {
    await triggerEvent('welcome_user');
  }

  Future<void> triggerFeaturePromotion(String feature) async {
    await triggerEvent('feature_promotion', parameters: {'feature': feature});
  }

  Future<void> triggerAttendanceReminder() async {
    await triggerEvent('attendance_reminder');
  }

  Future<void> triggerTrainingPrompt() async {
    await triggerEvent('training_prompt');
  }

  Future<void> triggerFeedbackRequest() async {
    await triggerEvent('feedback_request');
  }

  // Lifecycle-based triggers
  Future<void> onUserLogin() async {
    await triggerEvent('user_login');
  }

  Future<void> onScreenVisit(String screenName) async {
    await triggerEvent('screen_visit', parameters: {'screen': screenName});
  }

  Future<void> onActionCompleted(String action) async {
    await triggerEvent('action_completed', parameters: {'action': action});
  }

  // ============== REMOTE CONFIG METHODS ==============

  /// Fetch and activate remote config
  Future<bool> fetchAndActivateConfig() async {
    try {
      final result = await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        logger.i('Remote Config fetch and activate result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error fetching remote config: $e');
      }
      return false;
    }
  }

  /// Get string value from remote config
  String getConfigString(String key, {String? defaultValue}) {
    try {
      final value = _remoteConfig.getString(key);
      return value.isNotEmpty ? value : (defaultValue ?? '');
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error getting config string for key $key: $e');
      }
      return defaultValue ?? '';
    }
  }

  /// Get boolean value from remote config
  bool getConfigBool(String key, {bool? defaultValue}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error getting config bool for key $key: $e');
      }
      return defaultValue ?? false;
    }
  }

  /// Get integer value from remote config
  int getConfigInt(String key, {int? defaultValue}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error getting config int for key $key: $e');
      }
      return defaultValue ?? 0;
    }
  }

  /// Get double value from remote config
  double getConfigDouble(String key, {double? defaultValue}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      if (kDebugMode) {
        logger.e('Error getting config double for key $key: $e');
      }
      return defaultValue ?? 0.0;
    }
  }

  /// Get all config values
  Map<String, RemoteConfigValue> getAllConfigValues() {
    return _remoteConfig.getAll();
  }

  // ============== APP CONFIGURATION HELPERS ==============

  /// Check if app version is supported
  bool isAppVersionSupported(String currentVersion) {
    try {
      final requiredVersion = getConfigString('app_version_required');
      // Simple version comparison (you might want to use a proper version comparison library)
      return _compareVersions(currentVersion, requiredVersion) >= 0;
    } catch (e) {
      return true; // Default to supported if check fails
    }
  }

  /// Check if app is in maintenance mode
  bool isMaintenanceMode() {
    return getConfigBool('maintenance_mode');
  }

  /// Get maintenance message
  String getMaintenanceMessage() {
    return getConfigString('maintenance_message', 
        defaultValue: 'Ứng dụng đang được bảo trì. Vui lòng thử lại sau.');
  }

  // ============== FEATURE FLAGS ==============

  /// Check if biometric login is enabled
  bool isBiometricLoginEnabled() {
    return getConfigBool('enable_biometric_login', defaultValue: true);
  }

  /// Check if offline mode is enabled
  bool isOfflineModeEnabled() {
    return getConfigBool('enable_offline_mode', defaultValue: false);
  }

  /// Check if dark theme is enabled
  bool isDarkThemeEnabled() {
    return getConfigBool('enable_dark_theme', defaultValue: true);
  }

  /// Check if push notifications are enabled
  bool isPushNotificationsEnabled() {
    return getConfigBool('enable_push_notifications', defaultValue: true);
  }

  /// Check if location tracking is enabled
  bool isLocationTrackingEnabled() {
    return getConfigBool('enable_location_tracking', defaultValue: true);
  }

  // ============== UI CONFIGURATION ==============

  /// Get maximum attendance distance in meters
  int getMaxAttendanceDistance() {
    return getConfigInt('max_attendance_distance', defaultValue: 100);
  }

  /// Get auto check out hours
  int getAutoCheckOutHours() {
    return getConfigInt('auto_check_out_hours', defaultValue: 8);
  }

  /// Get break time in minutes
  int getBreakTimeMinutes() {
    return getConfigInt('break_time_minutes', defaultValue: 60);
  }

  // ============== API CONFIGURATION ==============

  /// Get API timeout in seconds
  int getApiTimeoutSeconds() {
    return getConfigInt('api_timeout_seconds', defaultValue: 30);
  }

  /// Get maximum retry attempts
  int getMaxRetryAttempts() {
    return getConfigInt('max_retry_attempts', defaultValue: 3);
  }

  /// Get cache duration in hours
  int getCacheDurationHours() {
    return getConfigInt('cache_duration_hours', defaultValue: 24);
  }

  /// Get backend API URL (Spring Boot backend)
  String getBackendApiUrl() {
    return getConfigString('backend_api_url', 
        defaultValue: 'https://your-backend.com/api');
  }

  /// Get data API URL (postgREST)
  String getDataApiUrl() {
    return getConfigString('data_api_url', 
        defaultValue: 'https://your-postgrest.com');
  }

  // ============== NOTIFICATION CONFIGURATION ==============

  /// Get notification quiet hours start
  int getNotificationQuietHoursStart() {
    return getConfigInt('notification_quiet_hours_start', defaultValue: 22);
  }

  /// Get notification quiet hours end
  int getNotificationQuietHoursEnd() {
    return getConfigInt('notification_quiet_hours_end', defaultValue: 6);
  }

  /// Get maximum daily notifications
  int getMaxDailyNotifications() {
    return getConfigInt('max_daily_notifications', defaultValue: 10);
  }

  // ============== TRAINING CONFIGURATION ==============

  /// Get training session duration in minutes
  int getTrainingSessionDuration() {
    return getConfigInt('training_session_duration', defaultValue: 30);
  }

  /// Check if training reminders are enabled
  bool isTrainingRemindersEnabled() {
    return getConfigBool('enable_training_reminders', defaultValue: true);
  }

  /// Get training progress sync interval in seconds
  int getTrainingProgressSyncInterval() {
    return getConfigInt('training_progress_sync_interval', defaultValue: 300);
  }

  // ============== UTILITY METHODS ==============

  /// Simple version comparison
  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
      
      for (int i = 0; i < maxLength; i++) {
        final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
        final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
        
        if (v1Part < v2Part) return -1;
        if (v1Part > v2Part) return 1;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
  }
} 