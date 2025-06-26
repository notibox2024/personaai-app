# Firebase Configuration Guide

## Tổng quan
Dự án PersonaAI đã được tích hợp với Firebase để hỗ trợ các tính năng:
- ✅ Firebase Cloud Messaging (FCM) - Push Notifications
- ✅ Firebase Analytics - Theo dõi hành vi người dùng
- ✅ Firebase Crashlytics - Báo cáo crash và error tracking
- ✅ Firebase App Check - Bảo mật ứng dụng
- ✅ Firebase In-App Messaging - Tin nhắn trong ứng dụng

## Cấu hình đã hoàn thành

### 1. Firebase Project Setup
- Project ID: `personaai-8bba9`
- Bundle ID (iOS): `com.kienlongbank.personaai`
- Package Name (Android): `com.kienlongbank.personaai`

### 2. Dependencies đã thêm vào `pubspec.yaml`
```yaml
dependencies:
  # Firebase Core (required for all Firebase services)
  firebase_core: ^3.10.0
  
  # Firebase Cloud Messaging
  firebase_messaging: ^15.2.7
  
  # Firebase Analytics
  firebase_analytics: ^11.5.0
  
  # Firebase Crashlytics
  firebase_crashlytics: ^4.1.7
  
  # Firebase App Check (Security)
  firebase_app_check: ^0.3.2+7
  
  # Firebase In-App Messaging
  firebase_in_app_messaging: ^0.8.1+7
```

### 3. Configuration Files
- ✅ `android/app/google-services.json` - Android configuration
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS configuration
- ✅ `firebase.json` - Firebase project configuration
- ✅ `lib/firebase_options.dart` - Flutter Firebase options

### 4. Code Implementation

#### Main App Initialization (`lib/main.dart`)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Firebase service
  await FirebaseService().initialize();
  
  runApp(const MyApp());
}
```

#### Firebase Service (`lib/shared/services/firebase_service.dart`)
- Quản lý FCM tokens
- Xử lý notifications (foreground, background, opened app)
- Analytics tracking
- Topic subscription/unsubscription

#### Firebase Notification Model (`lib/features/notifications/data/models/firebase_notification.dart`)
- Model để xử lý dữ liệu notification từ Firebase
- Conversion từ/về RemoteMessage

## Sử dụng Firebase Services

### 1. Firebase Cloud Messaging (FCM)

#### Lấy FCM Token
```dart
String? token = await FirebaseService().getToken();
print('FCM Token: $token');
```

#### Subscribe/Unsubscribe Topics
```dart
// Subscribe to topic
await FirebaseService().subscribeToTopic('all_users');

// Unsubscribe from topic
await FirebaseService().unsubscribeFromTopic('all_users');
```

### 2. Firebase Analytics

#### Log Events
```dart
// Login event
await FirebaseService().logLogin('email');

// Custom event
await FirebaseService().logEvent('button_pressed', parameters: {
  'button_name': 'check_in',
  'screen': 'attendance'
});

// Screen view
await FirebaseService().logScreenView('home_page');
```

#### Set User Properties
```dart
await FirebaseService().setUserId('user123');
await FirebaseService().setUserProperty('employee_id', 'EMP001');
```

## Testing Firebase Integration

### 1. Kiểm tra FCM Token
- Chạy app và kiểm tra console log để xem FCM token
- Token sẽ được in ra khi app khởi động

### 2. Test Push Notifications
- Sử dụng Firebase Console > Cloud Messaging
- Gửi test notification đến specific token hoặc topic

### 3. Test Analytics
- Sử dụng Firebase Console > Analytics > DebugView
- Bật debug mode trên device để xem real-time events

## Notifications Handling

### Foreground Notifications
- App đang mở: `FirebaseMessaging.onMessage`
- Hiển thị custom UI hoặc local notification

### Background Notifications
- App ở background: `FirebaseMessaging.onBackgroundMessage`
- Được xử lý bởi `_firebaseMessagingBackgroundHandler`

### Notification Opened App
- User tap vào notification: `FirebaseMessaging.onMessageOpenedApp`
- Navigation logic dựa trên message data

## Security Best Practices

### Firebase App Check
- Đã được cấu hình để bảo vệ Firebase APIs
- Chỉ requests từ verified apps mới được accept

### Token Security
- FCM tokens được refresh tự động
- Gửi tokens mới lên server khi có thay đổi

## Platform-specific Configuration

### Android
- `android/app/google-services.json` chứa config
- Minimum SDK: 21 (Android 5.0+)

### iOS
- `ios/Runner/GoogleService-Info.plist` chứa config
- iOS 11.0+ required for Firebase

## Troubleshooting

### Common Issues
1. **Firebase not initialized**: Đảm bảo `Firebase.initializeApp()` được gọi trước `runApp()`
2. **No FCM token**: Kiểm tra permissions và network connection
3. **Analytics not working**: Đảm bảo Analytics được enabled trong Firebase Console

### Debug Commands
```bash
# Check dependencies
flutter pub deps

# Run with Firebase debug
flutter run --debug

# Check Firebase project
firebase projects:list
```

## Next Steps

1. **Production Setup**:
   - Setup Firebase App Check với production tokens
   - Configure release signing keys
   - Setup proper Analytics audiences

2. **Advanced Features**:
   - Firebase Crashlytics cho crash reporting ✅
   - Firebase Remote Config cho feature flags
   - Firebase Performance Monitoring

3. **Backend Integration**:
   - Setup server để gửi targeted notifications
   - Implement user segmentation cho analytics
   - Setup automated messaging workflows

## Firebase Crashlytics Usage

### 1. Automatic Crash Reporting
- **Flutter Framework Errors**: Tự động được báo cáo qua `FlutterError.onError`
- **Platform Errors**: Được handle bởi `PlatformDispatcher.onError`
- **Async Errors**: Được catch bởi `runZonedGuarded`

### 2. Manual Error Logging
```dart
// Log non-fatal exception
try {
  // Some risky operation
} catch (error, stackTrace) {
  await FirebaseService().recordException(error, stackTrace, reason: 'API call failed');
}

// Log custom error
await FirebaseService().recordError(
  'Custom error message', 
  StackTrace.current,
  reason: 'User action failed'
);
```

### 3. Context và Custom Keys
```dart
// Set user context
await FirebaseService().setCrashlyticsUserId('user123');

// Add custom keys for better debugging
await FirebaseService().setCrashlyticsCustomKey('feature_enabled', true);
await FirebaseService().setCrashlyticsCustomKey('user_type', 'premium');

// Log contextual message
await FirebaseService().log('User attempted to check in');
```

### 4. Domain-specific Logging
```dart
// API errors
await FirebaseService().logApiError('/api/attendance', 'Network timeout');

// Authentication errors  
await FirebaseService().logAuthError('email_login', 'Invalid credentials');

// Attendance errors
await FirebaseService().logAttendanceError('check_in', 'Location permission denied');
```

### 5. Testing Crashlytics
```dart
// Force a test crash (only for testing!)
throw Exception('Test crash for Crashlytics');

// Send test exception
await FirebaseService().recordError(
  'Test exception', 
  StackTrace.current,
  reason: 'Testing Crashlytics integration'
);
```

### 6. Crashlytics Dashboard
- Truy cập [Firebase Console > Crashlytics](https://console.firebase.google.com/project/personaai-8bba9/crashlytics)
- Xem crash reports, trends, và user impact
- Setup alerts cho critical crashes
- Analyze stack traces và user sessions

## Firebase In-App Messaging Usage

### 1. Automatic Initialization
- **Data Collection**: Tự động enabled khi app khởi động
- **Message Display**: Enabled by default cho tất cả screens
- **Event-based Triggers**: Sử dụng Analytics events để trigger messages

### 2. Campaign Management
```dart
// Tạo campaigns trong Firebase Console > In-App Messaging
// Campaigns có thể dựa trên:
// - User properties (user_type, subscription_status)
// - Events (login, screen_visit, feature_usage)
// - Audience segments từ Analytics
```

### 3. Programmatic Triggers
```dart
// Trigger welcome message cho new users
await FirebaseService().triggerWelcomeMessage();

// Promote specific features
await FirebaseService().triggerFeaturePromotion('attendance_tracking');

// Trigger reminders
await FirebaseService().triggerAttendanceReminder();
await FirebaseService().triggerTrainingPrompt();

// Request feedback
await FirebaseService().triggerFeedbackRequest();
```

### 4. Lifecycle Integration
```dart
// Khi user login
await FirebaseService().onUserLogin();

// Khi user visit screen cụ thể
await FirebaseService().onScreenVisit('home_page');

// Khi user complete một action
await FirebaseService().onActionCompleted('check_in');
```

### 5. Message Control
```dart
// Suppress messages cho specific screens (ví dụ: login, splash)
await FirebaseService().suppressInAppMessages(true);

// Re-enable messages
await FirebaseService().suppressInAppMessages(false);

// Control data collection
await FirebaseService().setInAppMessagingDataCollection(true);
```

### 6. Message Types
- **Modal**: Fullscreen overlay với call-to-action
- **Image**: Image-only message với optional action
- **Top Banner**: Non-intrusive banner ở top
- **Card**: Card-style message với text và button

### 7. Testing In-App Messages
```dart
// Test campaigns in Firebase Console
// 1. Create test campaign
// 2. Set audience as "Test devices"
// 3. Trigger events trong app để test
// 4. Verify messages appear correctly

// Force trigger events for testing
await FirebaseService().triggerEvent('test_event', parameters: {
  'test_mode': true,
  'user_id': 'test_user'
});
```

### 8. Best Practices
- **Targeting**: Sử dụng user properties để target đúng audience
- **Frequency**: Set frequency caps để tránh spam users
- **A/B Testing**: Test different message variants
- **Analytics**: Track conversion rates và user engagement

### 9. In-App Messaging Dashboard
- Truy cập [Firebase Console > In-App Messaging](https://console.firebase.google.com/project/personaai-8bba9/inappmessaging)
- Tạo và quản lý campaigns
- Xem delivery metrics và conversion rates
- Setup A/B testing cho message optimization

## Links
- [Firebase Console](https://console.firebase.google.com/project/personaai-8bba9)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/) 