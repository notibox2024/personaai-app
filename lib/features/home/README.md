# Home Feature

Trang chủ ứng dụng Nhân sự KienlongBank được thiết kế theo kiến trúc **Feature-First** với **Clean Architecture**.

## 📁 Cấu trúc thư mục

```
lib/features/home/
├── data/
│   └── models/              # Data models
│       ├── employee_info.dart
│       ├── attendance_info.dart
│       ├── monthly_stats.dart
│       ├── notification_item.dart
│       └── upcoming_event.dart
├── presentation/
│   ├── pages/               # Screens/Pages
│   │   └── home_page.dart
│   └── widgets/             # UI Widgets
│       ├── header_section.dart
│       ├── welcome_banner.dart
│       ├── quick_actions_grid.dart
│       ├── upcoming_events_card.dart
│       └── dashboard_cards/
│           ├── attendance_card.dart
│           ├── monthly_stats_card.dart
│           └── notifications_card.dart
├── home_exports.dart        # Export file
└── README.md
```

## 🎨 Design System

### Theme Compliance
- Tuân thủ **KienlongBankTheme** với màu sắc brand identity
- Hỗ trợ **Light/Dark mode** hoàn chỉnh
- Sử dụng **Material Design 3** guidelines
- Typography theo **KienlongBankTextTheme**

### Color Palette
- **Primary**: `#FF4100` (Cam KienlongBank)
- **Secondary**: `#40A6FF` (Xanh da trời)
- **Tertiary**: `#0A1938` (Xanh dương đậm)

## 🧩 Components

### 1. HeaderSection
- Custom AppBar với gradient background
- Avatar, tên nhân viên, chức vụ
- Notification badge với số lượng
- Menu button

### 2. WelcomeBanner
- Thông tin ngày giờ thực
- Thời tiết hiện tại
- Quote động viên

### 3. QuickActionsGrid
- Grid 4 actions: Chấm công, Đơn từ, Bảng lương, Chat
- Responsive layout
- Factory method cho default actions

### 4. Dashboard Cards

#### AttendanceCard
- Thông tin chấm công hôm nay
- Status chip với màu sắc semantic
- Giờ vào/ra, tổng giờ làm việc
- Location tracking

#### MonthlyStatsCard
- Thống kê tháng hiện tại
- Progress bar cho ngày làm việc
- Ngày nghỉ còn lại, giờ overtime
- Điểm đánh giá hiệu suất

#### NotificationsCard
- Top 3 thông báo quan trọng
- Phân loại theo type với emoji
- Unread/read state
- Time ago string

### 5. UpcomingEventsCard
- Top 4 sự kiện sắp tới
- Phân loại: Họp, Sinh nhật, Training, Nghỉ lễ
- Date highlighting cho hôm nay
- Optional event badge

## 🚀 Usage

```dart
import 'package:personaai/features/home/home_exports.dart';

// Sử dụng HomePage
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: KienlongBankTheme.lightTheme,
      darkTheme: KienlongBankTheme.darkTheme,
      home: HomePage(),
    );
  }
}

// Sử dụng individual components
AttendanceCard(
  attendanceInfo: attendanceInfo,
  onTap: () => navigateToDetail(),
)
```

## 📱 Responsive Design

- **Mobile**: < 600dp (1 cột)
- **Tablet**: 600dp - 1024dp (2 cột dashboard)
- **Desktop**: > 1024dp (3 cột với sidebar)

## ♿ Accessibility

- **Touch targets**: 48dp minimum
- **Color contrast**: 4.5:1 cho text
- **Screen reader**: Semantic labels
- **Font scaling**: Responsive typography

## 🔄 State Management

- Hiện tại sử dụng **StatefulWidget** với mock data
- Chuẩn bị cho integration với:
  - **Provider/Riverpod** cho state management
  - **Repository pattern** cho data layer
  - **Bloc/Cubit** cho complex business logic

## 🧪 Testing

### Unit Tests
- Data models JSON serialization
- Business logic methods
- Utility functions

### Widget Tests
- Individual component rendering
- User interaction handling
- Theme compliance

### Integration Tests
- Full page navigation flow
- API integration
- Cross-platform compatibility

## 🔮 Future Enhancements

### Tính năng
- [ ] Real-time data với WebSocket
- [ ] Offline mode với local storage
- [ ] Push notifications
- [ ] Deep linking
- [ ] Analytics tracking

### Performance
- [ ] Image caching cho avatars
- [ ] Lazy loading cho large lists
- [ ] Memory optimization
- [ ] Network request caching

### UX/UI
- [ ] Skeleton loading states
- [ ] Micro-animations
- [ ] Custom transitions
- [ ] Haptic feedback
- [ ] Voice commands

## 📚 Dependencies

### Core
- `flutter_tabler_icons` - Icon set thống nhất
- `flutter/material.dart` - Material Design components

### Theme
- `KienlongBankTheme` - Brand theme system
- `KienlongBankColors` - Color constants 