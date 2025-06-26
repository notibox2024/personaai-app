# PersonaAI

Ứng dụng quản lý nhân sự thông minh cho KienlongBank được phát triển bằng Flutter. Ứng dụng được thiết kế với kiến trúc Feature-First và Clean Architecture, hỗ trợ đa nền tảng (iOS, Android, Web).

## 🚀 Tính năng chính

### 📱 Core Features
- **Chấm công thông minh**: Check-in/out với định vị GPS, theo dõi giờ làm việc
- **Dashboard tương tác**: Thống kê thời gian thực, hiệu suất làm việc
- **Quản lý thông báo**: Hệ thống thông báo đẩy với Firebase
- **Hồ sơ cá nhân**: Quản lý thông tin nhân viên, thành tích
- **Đào tạo trực tuyến**: Khóa học, tiến độ học tập

### 🎨 UI/UX Features
- **Material Design 3**: Giao diện hiện đại, thân thiện
- **Dark/Light Theme**: Hỗ trợ chế độ sáng/tối tự động
- **Responsive Design**: Tối ưu cho mọi kích thước màn hình
- **Brand Identity**: Tuân thủ màu sắc thương hiệu KienlongBank

### 🔧 Technical Features
- **Offline Support**: Hoạt động không cần mạng với Local Storage
- **Real-time Updates**: Cập nhật dữ liệu tức thời
- **Security**: Bảo mật với Flutter Secure Storage
- **Performance**: Tối ưu hiệu suất và bộ nhớ

## 📁 Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── app_layout.dart          # Main app layout với bottom navigation
├── features/                # Features theo Feature-First Architecture
│   ├── auth/               # Xác thực người dùng
│   │   ├── data/
│   │   ├── presentation/
│   │   └── auth_exports.dart
│   ├── home/               # Trang chủ & Dashboard
│   │   ├── data/
│   │   ├── presentation/
│   │   └── home_exports.dart
│   ├── attendance/         # Chấm công
│   │   ├── data/
│   │   ├── presentation/
│   │   └── attendance_exports.dart
│   ├── training/           # Đào tạo
│   ├── notifications/      # Thông báo
│   ├── profile/           # Hồ sơ cá nhân
│   └── splash/            # Màn hình chào
├── shared/                # Shared resources
│   ├── constants/         # Constants
│   ├── models/           # Common models
│   ├── services/         # API, Location services
│   ├── utils/            # Utilities
│   └── widgets/          # Reusable widgets
└── themes/               # Theme system
    ├── app_theme.dart
    ├── colors.dart
    ├── text_theme.dart
    └── component_themes.dart
```

## 🛠 Công nghệ sử dụng

### Core Framework
- **Flutter SDK**: ^3.8.1
- **Dart**: Latest stable

### UI & Icons
- **Material Design 3**: UI framework chính
- **flutter_tabler_icons**: Bộ icon thống nhất
- **flutter_svg**: Hỗ trợ SVG

### Networking & API
- **dio**: HTTP client cho API calls
- **connectivity_plus**: Kiểm tra trạng thái mạng
- **network_info_plus**: Thông tin mạng

### Location & Permissions
- **location**: Dịch vụ định vị
- **geolocator**: Xử lý GPS
- **permission_handler**: Quản lý quyền

### Storage & Security
- **flutter_secure_storage**: Lưu trữ bảo mật
- **device_info_plus**: Thông tin thiết bị

### Firebase Integration
- **firebase_core**: Firebase core
- **firebase_messaging**: Push notifications
- **firebase_analytics**: Analytics

### Development Tools
- **flutter_lints**: Code quality
- **flutter_launcher_icons**: Tạo app icons
- **flutter_native_splash**: Màn hình splash

## 🚀 Hướng dẫn cài đặt

### Yêu cầu hệ thống
- Flutter SDK 3.8.1 hoặc mới hơn
- Dart SDK 3.0.0 hoặc mới hơn
- Android Studio / VS Code
- iOS: Xcode 14.0+ (cho phát triển iOS)
- Android: API level 21+ (Android 5.0+)

### Cài đặt dự án

1. **Clone repository**
```bash
git clone <repository-url>
cd personaai
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Cấu hình Firebase** (Optional)
```bash
# Thêm google-services.json cho Android
# Thêm GoogleService-Info.plist cho iOS
```

4. **Tạo app icons**
```bash
flutter pub run flutter_launcher_icons
```

5. **Tạo splash screen**
```bash
flutter pub run flutter_native_splash:create
```

6. **Chạy ứng dụng**
```bash
# Chạy trên debug mode
flutter run

# Chạy trên release mode
flutter run --release

# Chạy trên platform cụ thể
flutter run -d chrome        # Web
flutter run -d ios          # iOS
flutter run -d android      # Android
```

## 📱 Hướng dẫn sử dụng

### Đăng nhập
1. Mở ứng dụng
2. Nhập thông tin đăng nhập (email/mật khẩu)
3. Hoặc sử dụng tính năng demo để trải nghiệm

### Chấm công
1. Vào tab "Chấm công"
2. Cho phép truy cập vị trí
3. Nhấn "Check In" khi đến công ty
4. Nhấn "Check Out" khi tan làm

### Xem thống kê
1. Trang chủ hiển thị tổng quan
2. Xem thống kê tháng hiện tại
3. Theo dõi tiến độ công việc

### Thông báo
1. Tab "Thông báo" hiển thị tin mới
2. Badge số hiển thị tin chưa đọc
3. Lọc theo loại thông báo

## 🎨 Theme System

### Brand Colors
- **Primary**: `#FF4100` (Cam KienlongBank)
- **Secondary**: `#40A6FF` (Xanh da trời)
- **Tertiary**: `#0A1938` (Xanh dương đậm)

### Theme Modes
- **Light Mode**: Giao diện sáng cho ban ngày
- **Dark Mode**: Giao diện tối cho ban đêm
- **System**: Tự động theo hệ thống

### Responsive Design
- **Mobile**: < 600dp (1 cột)
- **Tablet**: 600dp - 1024dp (2 cột)
- **Desktop**: > 1024dp (3 cột với sidebar)

## 🧪 Testing

### Chạy tests
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/
```

### Coverage
```bash
# Tạo coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🚀 Deployment

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS
```bash
# Build iOS
flutter build ios --release
```

### Web
```bash
# Build Web
flutter build web --release
```

## 🤝 Đóng góp

1. Fork dự án
2. Tạo feature branch: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add some AmazingFeature'`
4. Push to branch: `git push origin feature/AmazingFeature`
5. Mở Pull Request

### Code Style
- Tuân thủ [Flutter Style Guide](https://dart.dev/guides/language/effective-dart)
- Sử dụng `flutter_lints` để kiểm tra code quality
- Viết comments và documentation đầy đủ

## 📄 License

Dự án này thuộc sở hữu của KienlongBank. Mọi quyền được bảo lưu.

## 📞 Liên hệ

- **Team**: PersonaAI Development Team
- **Email**: dev@kienlongbank.com
- **Website**: [kienlongbank.com](https://kienlongbank.com)

## 🔄 Changelog

### Version 1.0.0+1
- ✅ Tính năng chấm công cơ bản
- ✅ Dashboard và thống kê
- ✅ Hệ thống thông báo
- ✅ Quản lý hồ sơ cá nhân
- ✅ Dark/Light theme
- ✅ Responsive design

### Upcoming Features
- 🔄 Real-time synchronization
- 🔄 Offline mode hoàn chỉnh
- 🔄 Advanced analytics
- 🔄 Multi-language support
- 🔄 Voice commands

---

Made with ❤️ by PersonaAI Team
