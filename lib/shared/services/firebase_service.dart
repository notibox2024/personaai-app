import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseMessaging _messaging;
  late FirebaseAnalytics _analytics;

  // Initialize Firebase services
  Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;
    _analytics = FirebaseAnalytics.instance;
    
    await _initializeMessaging();
    await _initializeAnalytics();
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
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Lấy FCM token
    String? token = await _messaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $token');
    }

    // Lắng nghe token refresh
    _messaging.onTokenRefresh.listen((String token) {
      if (kDebugMode) {
        print('FCM Token refreshed: $token');
      }
      // TODO: Gửi token mới lên server
    });

    // Xử lý message khi app đang foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
      
      // TODO: Hiển thị local notification hoặc update UI
      _handleForegroundMessage(message);
    });

    // Xử lý message khi user tap vào notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      
      // TODO: Navigate to specific screen based on message data
      _handleMessageOpenedApp(message);
    });

    // Kiểm tra message khi app được mở từ terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from terminated state with message: ${initialMessage.messageId}');
      }
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Initialize Firebase Analytics
  Future<void> _initializeAnalytics() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    
    if (kDebugMode) {
      print('Firebase Analytics initialized');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // TODO: Implement custom notification display
    // Có thể sử dụng local notifications hoặc custom UI
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    // TODO: Implement navigation logic based on message data
    // Ví dụ: navigate to specific screen, open deep link
  }

  // Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Subscribed to topic: $topic');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Unsubscribed from topic: $topic');
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
} 