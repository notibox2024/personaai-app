# iOS Push Notification Setup Guide

## Lỗi đã sửa

### ✅ **Code Level Fixes (Đã hoàn thành)**

1. **Firebase Service Error Handling**:
   - Thêm try-catch cho FCM token retrieval
   - App sẽ không crash nếu APNS chưa sẵn sàng

2. **iOS Entitlements**:
   - Tạo `ios/Runner/Runner.entitlements` cho production
   - Thiết lập `aps-environment: production`

3. **Info.plist Configuration**:
   - Thêm Firebase configuration keys
   - Enable FirebaseAppDelegateProxyEnabled

## ⚠️ **Apple Developer Account Setup Required**

### 1. Apple Push Notification Certificate

Bạn cần tạo APNS certificate trong Apple Developer Account:

1. **Đăng nhập vào [Apple Developer Portal](https://developer.apple.com/account/)**

2. **Tạo Push Notification Certificate**:
   ```
   Certificates, Identifiers & Profiles > Certificates > (+)
   → Apple Push Notification service SSL (Production)
   → Chọn App ID: com.kienlongbank.personaai
   → Upload Certificate Signing Request (CSR)
   → Download certificate (.cer file)
   ```

3. **Upload Certificate lên Firebase**:
   ```
   Firebase Console > Project Settings > Cloud Messaging
   → Apple app configuration
   → Upload APNs authentication key hoặc APNs certificates
   ```

### 2. Provisioning Profile

1. **Tạo Production Provisioning Profile**:
   ```
   Profiles > (+) → App Store Distribution
   → App ID: com.kienlongbank.personaai
   → Select Distribution Certificate
   → Download .mobileprovision file
   ```

2. **Install Provisioning Profile**:
   - Double-click .mobileprovision file để install vào Xcode
   - Hoặc drag & drop vào Xcode Organizer

### 3. Xcode Project Configuration

1. **Mở ios/Runner.xcworkspace trong Xcode**

2. **Target Settings**:
   ```
   Signing & Capabilities tab:
   - Team: Select your Apple Developer Team
   - Provisioning Profile: Select production profile
   - Bundle Identifier: com.kienlongbank.personaai
   ```

3. **Capabilities**:
   ```
   + Capability → Push Notifications
   + Capability → Background Modes
     ✓ Remote notifications
   ```

4. **Entitlements Files**:
   ```
   Debug Configuration: RunnerDebug.entitlements (aps-environment: development)
   Release Configuration: Runner.entitlements (aps-environment: production)
   ```

## 🧪 **Testing Setup**

### Development Testing
```bash
# Debug build với development APNS
flutter run --debug
```

### Production Testing
```bash
# Release build với production APNS
flutter build ios --release
# Deploy thông qua Xcode Archive
```

### Firebase Test Message
```
Firebase Console > Cloud Messaging > Send your first message
- Target: Single device (sử dụng FCM token)
- hoặc Target: Topic (nếu đã subscribe)
```

## 🔧 **Troubleshooting**

### Lỗi: "APNS token has not been set yet"
**Giải pháp**: 
- Code đã được fix để handle error này
- App sẽ tiếp tục hoạt động bình thường
- Push notifications sẽ hoạt động khi APNS certificate được setup đúng

### Lỗi: "aps-environment not found"
**Giải pháp**:
- ✅ Đã tạo Runner.entitlements với aps-environment: production
- Đảm bảo Provisioning Profile include Push Notifications capability

### Lỗi UIKit Lifecycle
**Giải pháp**:
- Cảnh báo không ảnh hưởng tới functionality
- iOS sẽ migrate sang UIScene trong future iOS versions

## 📋 **Next Steps**

1. **Complete Apple Developer Setup**:
   - Tạo APNS certificate
   - Upload lên Firebase Console
   - Test với production build

2. **Backend Integration**:
   - Implement FCM token sync với server
   - Setup targeted notifications
   - Handle notification deep links

3. **Production Monitoring**:
   - Monitor FCM delivery rates
   - Track notification engagement
   - Setup Crashlytics alerts

## 🔗 **Useful Links**

- [Apple Push Notification Guide](https://developer.apple.com/documentation/usernotifications)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [FCM iOS Integration](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Xcode Code Signing](https://developer.apple.com/support/code-signing/)

## ⚡ **Quick Fix Summary**

Lỗi hiện tại đã được fix ở code level. App sẽ chạy được nhưng push notifications sẽ chỉ hoạt động đầy đủ khi:

1. ✅ **Code fixes** - Đã hoàn thành
2. ⏳ **APNS Certificate** - Cần setup trong Apple Developer Account  
3. ⏳ **Firebase Configuration** - Upload certificate lên Firebase Console
4. ⏳ **Provisioning Profile** - Update với Push Notifications capability 