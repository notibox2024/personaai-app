# Firebase Configuration Guide

## Tổng quan
Dự án PersonaAI đã được tích hợp với Firebase để hỗ trợ các tính năng:
- ✅ Firebase Cloud Messaging (FCM) - Push Notifications
- ✅ Firebase Analytics - Theo dõi hành vi người dùng
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
   - Firebase Crashlytics cho crash reporting
   - Firebase Remote Config cho feature flags
   - Firebase Performance Monitoring

3. **Backend Integration**:
   - Setup server để gửi targeted notifications
   - Implement user segmentation cho analytics
   - Setup automated messaging workflows

## Links
- [Firebase Console](https://console.firebase.google.com/project/personaai-8bba9)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/) 