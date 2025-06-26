# Thiết Kế Trang Chủ Ứng Dụng Nhân Sự KienlongBank

## 1. Overview
Trang chủ được thiết kế theo Material Design 3 với brand identity của KienlongBank, tối ưu cho trải nghiệm nhân viên với các thông tin và chức năng cần thiết nhất.

## 2. Layout Structure

### 2.1 Header Section
```
┌─────────────────────────────────────────────────────┐
│  🟠 [Avatar] Xin chào, [Tên NV]     🔔[5]    ☰      │
│      [Chức vụ]                                       │
└─────────────────────────────────────────────────────┘
```

**Theme áp dụng:**
- Background: `KienlongBankColors.primary` (#FF4100)
- Text: `Colors.white`
- Typography: `headlineSmall` cho tên, `bodyMedium` cho chức vụ
- Height: 120dp với gradient nhẹ

### 2.2 Welcome Banner
```
┌─────────────────────────────────────────────────────┐
│  Hôm nay, [Thứ X, dd/MM/yyyy]                       │
│  [Thời gian thực] • [Thời tiết]                      │
│  "Chúc bạn một ngày làm việc hiệu quả! 💪"          │
└─────────────────────────────────────────────────────┘
```

**Theme áp dụng:**
- Background: `primaryGradient` với opacity 0.1
- Card: `CardTheme` với border radius 12dp
- Typography: `titleMedium` cho ngày, `bodyLarge` cho quote

### 2.3 Quick Actions Grid
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│    ⏰       │     📝      │     📊      │     💬      │
│  Chấm công  │  Đơn từ     │  Bảng lương │   Chat      │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

**Theme áp dụng:**
- Background: `surface` với `elevation: 1`
- Icon color: `primary`
- Text: `labelLarge`
- Ripple effect: `primary` với alpha 0.12

### 2.4 Dashboard Cards

#### Card 1: Thông tin chấm công hôm nay
```
┌─────────────────────────────────────────────────────┐
│  ⏰ Chấm Công Hôm Nay                               │
│  ──────────────────────────────────────────────────  │
│  Giờ vào: 08:15     Giờ ra: --:--                   │
│  Tổng giờ: 4h 30m   Trạng thái: 🟢 Đang làm        │
│  ──────────────────────────────────────────────────  │
│  📍 Văn phòng chính                                 │
└─────────────────────────────────────────────────────┘
```

#### Card 2: Thống kê tháng này
```
┌─────────────────────────────────────────────────────┐
│  📊 Thống Kê Tháng [MM/YYYY]                        │
│  ──────────────────────────────────────────────────  │
│  Ngày làm việc:  15/22      Ngày nghỉ còn lại: 7    │
│  Giờ overtime:   12h        Điểm đánh giá: 8.5/10   │
│  ──────────────────────────────────────────────────  │
│  🏆 Hiệu suất: Xuất sắc                             │
└─────────────────────────────────────────────────────┘
```

#### Card 3: Thông báo quan trọng
```
┌─────────────────────────────────────────────────────┐
│  🔔 Thông Báo Quan Trọng                            │
│  ──────────────────────────────────────────────────  │
│  • 🎉 Tăng lương Q4 - Xem chi tiết                  │
│  • 📅 Họp team vào 14:00 - Phòng 301                │
│  • ⚠️ Deadline báo cáo: 25/12/2024                   │
│  ──────────────────────────────────────────────────  │
│  📖 Xem tất cả (3)                                  │
└─────────────────────────────────────────────────────┘
```

**Theme cho Dashboard Cards:**
- CardTheme: `lightCardTheme` hoặc `darkCardTheme`
- Elevation: 2dp
- Border radius: 12dp
- Margin: `EdgeInsets.symmetric(vertical: 4, horizontal: 16)`
- Typography: `titleMedium` cho header, `bodyMedium` cho content
- Status colors: `success`, `warning`, `info` từ semantic colors

### 2.5 Upcoming Events
```
┌─────────────────────────────────────────────────────┐
│  📅 Sự Kiện Sắp Tới                                 │
│  ──────────────────────────────────────────────────  │
│  🗓️ 15/12 - Họp Ban Giám Đốc (09:00)               │
│  🎂 16/12 - Sinh nhật Nguyễn Văn A                   │
│  🎓 18/12 - Training Flutter nâng cao                │
│  🏖️ 25/12 - Nghỉ lễ Giáng sinh                       │
│  ──────────────────────────────────────────────────  │
│  📋 Xem lịch đầy đủ                                 │
└─────────────────────────────────────────────────────┘
```

## 3. Color Scheme & Theme

### 3.1 Màu Sắc Chính
- **Primary**: `#FF4100` (Cam KienlongBank) - Năng động, nhiệt huyết
- **Secondary**: `#40A6FF` (Xanh da trời) - Công nghệ, tin cậy
- **Tertiary**: `#0A1938` (Xanh dương đậm) - Chuyên nghiệp, uy tín

### 3.2 Surface Colors
- **Light Background**: `#FAFAFA`
- **Light Surface**: `#FFFFFF` 
- **Light Surface Variant**: `#F5F5F5`
- **Card Elevation**: 2dp với shadow color `black.withAlpha(0.08)`

### 3.3 Semantic Colors
- **Success**: `#4CAF50` (Xanh lá) - Trạng thái thành công
- **Warning**: `#FF9800` (Cam nhạt) - Cảnh báo, chú ý
- **Error**: `#F44336` (Đỏ) - Lỗi, nguy hiểm
- **Info**: `#2196F3` (Xanh dương) - Thông tin

## 4. Typography System

### 4.1 Hierarchy
- **Display Large** (57sp): Không sử dụng trên mobile
- **Headline Large** (32sp, w600): Tiêu đề trang
- **Headline Medium** (28sp, w600): Tiêu đề section chính
- **Headline Small** (24sp, w600): Tiêu đề card quan trọng
- **Title Large** (22sp, w500): Tiêu đề card thường
- **Title Medium** (16sp, w500): Tiêu đề con, label quan trọng
- **Body Large** (16sp, w400): Nội dung chính
- **Body Medium** (14sp, w400): Nội dung phụ
- **Label Large** (14sp, w500): Button, tab
- **Label Medium** (12sp, w500): Badge, chip

### 4.2 Custom Styles
- **Currency Style**: 24sp, w700, monospace, primary color
- **Code Style**: 14sp, w500, monospace, letter-spacing 1.0

## 5. Component Specifications

### 5.1 Cards
```dart
// Dashboard Card Template
Card(
  elevation: 2,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
  child: Padding(
    padding: EdgeInsets.all(16),
    // Card content
  ),
)
```

### 5.2 Quick Action Buttons
```dart
// Quick Action Button Template  
Material(
  elevation: 1,
  borderRadius: BorderRadius.circular(12),
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    splashColor: Theme.of(context).colorScheme.primary.withAlpha(30),
    child: Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    ),
  ),
)
```

### 5.3 Status Indicators
```dart
// Status Chip Template
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(
    color: statusColor.withAlpha(30),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(statusIcon, size: 16, color: statusColor),
      SizedBox(width: 4),
      Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
    ],
  ),
)
```

## 6. Interaction Design

### 6.1 Micro-animations
- **Card Tap**: Scale 0.98 → 1.0 (150ms, easeInOut)
- **Button Press**: Ripple effect với primary color
- **Loading**: Skeleton shimmer với surface colors
- **Pull-to-refresh**: Custom indicator với brand colors

### 6.2 Navigation Transitions
- **Page Transition**: Slide từ phải qua trái (300ms)
- **Modal Transition**: Slide từ dưới lên (250ms)
- **Drawer**: Slide với backdrop blur

### 6.3 Feedback States
- **Loading**: CircularProgressIndicator với primary color
- **Empty State**: Icon + text với onSurfaceVariant color
- **Error State**: Error color với retry button

## 7. Responsive Design

### 7.1 Breakpoints
- **Mobile**: < 600dp (1 cột)
- **Tablet**: 600dp - 1024dp (2 cột cho dashboard)
- **Desktop**: > 1024dp (3 cột với sidebar)

### 7.2 Layout Adaptation
```dart
// Responsive Grid
GridView.count(
  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
  childAspectRatio: 16/9,
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
)
```

## 8. Accessibility

### 8.1 Color Contrast
- Text trên background: 4.5:1 minimum
- Icons quan trọng: 3:1 minimum
- Interactive elements: 4.5:1 minimum

### 8.2 Touch Targets
- Minimum size: 48dp × 48dp
- Quick actions: 56dp × 56dp
- Spacing giữa targets: 8dp minimum

### 8.3 Screen Reader Support
```dart
Semantics(
  label: 'Chấm công hôm nay',
  hint: 'Nhấn để xem chi tiết thời gian làm việc',
  child: DashboardCard(),
)
```

## 9. Bottom Navigation

```
┌─────┬─────┬─────┬─────┬─────┐
│ 🏠  │ ⏰  │ 📋  │ 💬  │ 👤  │
│Trang│Chấm│Đơn │Chat │ Cá  │
│ chủ │công│ từ  │     │nhân │
└─────┴─────┴─────┴─────┴─────┘
```

**Theme áp dụng:**
- Background: `surface`
- Selected color: `primary`
- Unselected color: `onSurfaceVariant`
- Indicator: `primaryContainer`

## 10. Dark Mode Support

Tất cả components đều hỗ trợ dark mode thông qua theme system:
- Automatic color switching dựa vào `ColorScheme.brightness`
- Icons và illustrations có variant cho dark mode
- Gradients điều chỉnh opacity phù hợp

---

**Lưu ý Implementation:**
- Sử dụng `KienlongBankTheme.lightTheme` và `KienlongBankTheme.darkTheme`
- Component themes đã được định nghĩa sẵn trong `KienlongBankComponentThemes`
- Custom colors và text styles có sẵn trong theme system
- Tuân thủ Material Design 3 guidelines với brand customization