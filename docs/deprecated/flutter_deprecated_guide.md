# Flutter Deprecated APIs - Hướng Dẫn Tránh và Sửa Lỗi

> **Tài liệu này ghi chú các điểm chính về việc sinh mã tránh deprecated trong Flutter**  
> Dự án: KienlongBank HR App  
> Cập nhật: Tháng 12/2024  
> Flutter Version: 3.18+

## 📋 Tổng quan

Deprecated APIs là những API đã lỗi thời và sẽ bị loại bỏ trong các phiên bản Flutter tương lai. Việc sử dụng các API này sẽ tạo ra warnings và có thể gây lỗi khi Flutter cập nhật.

## 🚨 Các Deprecated APIs Phổ Biến và Cách Sửa

### 1. MaterialStateProperty → WidgetStateProperty

**❌ Deprecated (trước Flutter 3.18):**
```dart
MaterialStateProperty.resolveWith((states) {
  if (states.contains(MaterialState.selected)) {
    return Colors.blue;
  }
  return Colors.grey;
})
```

**✅ Cách sửa (Flutter 3.18+):**
```dart
WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.selected)) {
    return Colors.blue;
  }
  return Colors.grey;
})
```

**📍 Áp dụng cho:**
- `SwitchThemeData.thumbColor`
- `SwitchThemeData.trackColor`
- `CheckboxThemeData.fillColor`
- `RadioThemeData.fillColor`
- Tất cả button states

### 2. MaterialState → WidgetState

**❌ Deprecated:**
```dart
MaterialState.selected
MaterialState.pressed
MaterialState.focused
MaterialState.hovered
MaterialState.disabled
```

**✅ Cách sửa:**
```dart
WidgetState.selected
WidgetState.pressed
WidgetState.focused
WidgetState.hovered
WidgetState.disabled
```

### 3. withOpacity() → withValues()

**❌ Deprecated (precision loss warning):**
```dart
Colors.black.withOpacity(0.5)
colorScheme.primary.withOpacity(0.12)
```

**✅ Cách sửa (tránh precision loss):**
```dart
Colors.black.withValues(alpha: 0.5)
colorScheme.primary.withValues(alpha: 0.12)
```

**📍 Lý do:** `withValues()` cung cấp độ chính xác cao hơn cho alpha channel.

### 4. surfaceVariant → surfaceContainerHighest

**❌ Deprecated (Material Design 3):**
```dart
ColorScheme.light(
  surfaceVariant: Colors.grey.shade100,
)

// Sử dụng
colorScheme.surfaceVariant
```

**✅ Cách sửa (Material Design 3):**
```dart
ColorScheme.light(
  surfaceContainerHighest: Colors.grey.shade100,
)

// Sử dụng
colorScheme.surfaceContainerHighest
```

**📍 Áp dụng cho:**
- Chip background colors
- Progress indicator track colors
- Switch track colors
- Card background variants

### 5. background → surface (ColorScheme)

**❌ Deprecated:**
```dart
ColorScheme.light(
  background: Colors.white,
  onBackground: Colors.black,
)

// Sử dụng
colorScheme.background
colorScheme.onBackground
```

**✅ Cách sửa:**
```dart
ColorScheme.light(
  surface: Colors.white,
  onSurface: Colors.black,
)

// Hoặc sử dụng scaffoldBackgroundColor trực tiếp
ThemeData(
  scaffoldBackgroundColor: Colors.white,
)
```

### 6. Dangling Library Doc Comments

**❌ Warning:**
```dart
/// Documentation cho library
/// Mô tả về file này

import 'package:flutter/material.dart';
```

**✅ Cách sửa:**
```dart
/// Documentation cho library
/// Mô tả về file này
library;

import 'package:flutter/material.dart';
```

## 🛠️ Quy Trình Kiểm Tra và Sửa Deprecated

### Bước 1: Phát hiện
```bash
# Chạy phân tích code
flutter analyze

# Kiểm tra warnings
flutter analyze | grep deprecated
```

### Bước 2: Phân loại
- **Critical**: APIs sẽ bị remove sớm
- **Warning**: APIs có replacement tốt hơn
- **Info**: APIs deprecated nhưng vẫn hoạt động

### Bước 3: Ưu tiên sửa
1. **MaterialStateProperty/MaterialState** - High priority
2. **withOpacity()** - Medium priority  
3. **surfaceVariant** - Medium priority
4. **background ColorScheme** - Low priority
5. **Library doc comments** - Low priority

### Bước 4: Testing
```bash
# Test sau khi sửa
flutter analyze
flutter test
flutter run --hot
```

## 📚 Best Practices

### 1. Proactive Approach
- Theo dõi Flutter release notes
- Cập nhật dependencies thường xuyên
- Sử dụng latest stable APIs

### 2. Code Review Checklist
- [ ] Không có deprecated warnings
- [ ] Sử dụng WidgetStateProperty thay vì MaterialStateProperty
- [ ] Sử dụng withValues() thay vì withOpacity()
- [ ] Sử dụng surfaceContainerHighest thay vì surfaceVariant
- [ ] Có library directive cho doc comments

### 3. Migration Strategy
```dart
// Ví dụ helper function cho migration
extension ColorExtension on Color {
  Color withAlpha(double alpha) {
    return withValues(alpha: alpha);
  }
}

// Sử dụng
color.withAlpha(0.5) // thay vì color.withOpacity(0.5)
```

### 4. Documentation Pattern
```dart
/// Component theme cho KienlongBank App
/// 
/// Sử dụng Material Design 3 và Flutter 3.18+ APIs
/// Tránh tất cả deprecated warnings
library kienlongbank_themes;

import 'package:flutter/material.dart';
```

## 🔍 Công Cụ Hỗ Trợ

### 1. IDE Extensions
- **Flutter Inspector**: Phát hiện deprecated usage
- **Dart Code**: Auto-fix cho một số deprecated APIs
- **Flutter Intl**: I18n deprecated handling

### 2. CLI Tools
```bash
# Phân tích chi tiết
flutter analyze --verbose

# Format code
dart format .

# Fix imports
dart fix --apply
```

### 3. GitHub Actions
```yaml
name: Check Deprecated APIs
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter analyze
      - run: |
          if flutter analyze | grep -q "deprecated"; then
            echo "❌ Deprecated APIs found!"
            exit 1
          fi
```

## 📊 Kết Quả Thực Tế - KienlongBank Project

### Trước khi sửa:
```
39 issues found. (ran in 1.3s)
- 21x withOpacity deprecated warnings
- 8x surfaceVariant deprecated warnings  
- 6x MaterialStateProperty deprecated warnings
- 3x MaterialState deprecated warnings
- 1x dangling library doc comment
```

### Sau khi sửa:
```
No issues found! (ran in 1.2s)
- 0 deprecated warnings
- 0 errors
- Clean codebase
```

### Files được update:
- `lib/themes/app_theme.dart` - 24 fixes
- `lib/themes/colors.dart` - 2 fixes
- `lib/themes/component_themes.dart` - 3 fixes
- `lib/themes/themes.dart` - 1 fix
- `lib/main.dart` - 3 fixes

## 🎯 Tổng Kết

1. **Luôn chạy `flutter analyze`** trước khi commit
2. **Ưu tiên sửa deprecated APIs** ngay khi phát hiện
3. **Sử dụng latest APIs** theo Flutter release notes
4. **Document migration path** cho team
5. **Setup CI/CD** để catch deprecated usage

---

**📝 Ghi chú:** Tài liệu này sẽ được cập nhật theo Flutter releases. Kiểm tra Flutter changelog để biết deprecated APIs mới.

**🔗 Tham khảo:**
- [Flutter Breaking Changes](https://docs.flutter.dev/release/breaking-changes)
- [Material Design 3](https://m3.material.io/)
- [Flutter API Docs](https://api.flutter.dev/) 