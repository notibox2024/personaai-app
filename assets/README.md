# Assets Management - PersonaAI

Hướng dẫn quản lý và sử dụng assets (ảnh, icon, fonts) trong dự án PersonaAI.

## 📁 Cấu trúc thư mục

```
assets/
├── fonts/                     # Custom fonts
├── images/
│   ├── icons/                 # Custom icons
│   │   ├── 2x/               # High-DPI icons (2x)
│   │   └── 3x/               # Extra high-DPI icons (3x)
│   ├── illustrations/         # Illustration images
│   ├── avatars/              # Default avatar images
│   ├── backgrounds/          # Background images
│   ├── logos/                # Company/app logos
│   └── onboarding/           # Onboarding screen images
```

## 🎯 Quy tắc đặt tên

### Icons
- **Format**: `icon_name.png`, `icon_name@2x.png`, `icon_name@3x.png`
- **Ví dụ**: `home.png`, `home@2x.png`, `home@3x.png`
- **Kích thước**: 24x24 (1x), 48x48 (2x), 72x72 (3x)

### Illustrations
- **Format**: `illustration_name.png`
- **Ví dụ**: `welcome_banner.png`, `empty_state.png`
- **Kích thước**: Responsive, thường 300-400px width

### Avatars
- **Format**: `avatar_type.png`
- **Ví dụ**: `default_male.png`, `placeholder.png`
- **Kích thước**: 100x100, 200x200

### Backgrounds
- **Format**: `bg_name.png`
- **Ví dụ**: `splash_bg.png`, `pattern.png`

### Logos
- **Format**: `logo_variant.png`
- **Ví dụ**: `app_logo.png`, `logo_light.png`, `logo_dark.png`

## 💻 Sử dụng trong code

### Import constants
```dart
import 'package:personaai/shared/shared_exports.dart';
```

### Sử dụng assets constants

#### Icons
```dart
// Sử dụng icon với resolution tự động
String iconPath = Assets.getIcon('home', pixelRatio: MediaQuery.of(context).devicePixelRatio);

// Hoặc sử dụng trực tiếp
Image.asset(AssetsIcons.logo);

// Extension helper
Image.asset('home.png'.asIcon);
```

#### Illustrations
```dart
// Sử dụng illustration
Image.asset(AssetsIllustrations.welcome);

// Extension helper
Image.asset('welcome.png'.asIllustration);
```

#### Avatars
```dart
// Avatar mặc định
CircleAvatar(
  backgroundImage: AssetImage(AssetsAvatars.defaultMale),
);

// Extension helper
Image.asset('placeholder.png'.asAvatar);
```

#### Dynamic asset building
```dart
// Build path dynamically
final assetPath = AssetPathBuilder(
  type: AssetType.icon,
  fileName: 'home.png',
).path;

Image.asset(assetPath);
```

## 🎨 Thêm assets mới

### 1. Thêm file vào thư mục tương ứng
```bash
# Ví dụ: thêm icon mới
assets/images/icons/settings.png
assets/images/icons/2x/settings@2x.png
assets/images/icons/3x/settings@3x.png
```

### 2. Cập nhật constants
```dart
// Trong lib/shared/constants/assets.dart
class AssetsIcons {
  // ...existing code...
  static const String settings = '$_path/settings.png';
}
```

### 3. Sử dụng trong code
```dart
Icon(
  ImageIcon(AssetImage(AssetsIcons.settings)),
)
```

## 📱 Responsive Icons

### Sử dụng Assets.getIcon() cho responsive
```dart
Widget buildIcon(BuildContext context, String iconName) {
  final pixelRatio = MediaQuery.of(context).devicePixelRatio;
  return Image.asset(
    Assets.getIcon(iconName, pixelRatio: pixelRatio),
    width: 24,
    height: 24,
  );
}
```

### Manual resolution selection
```dart
// Low DPI
Image.asset(AssetsIcons.home);

// High DPI (2x)
Image.asset(AssetsIcons2x.home);

// Extra High DPI (3x)  
Image.asset(AssetsIcons3x.home);
```

## 🔤 Custom Fonts

### Thêm font mới
1. **Copy font files** vào `assets/fonts/`
2. **Cập nhật pubspec.yaml**:
```yaml
flutter:
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.ttf
        - asset: assets/fonts/CustomFont-Bold.ttf
          weight: 700
```

3. **Cập nhật constants**:
```dart
class AssetsFonts {
  static const String customFont = 'CustomFont';
}
```

4. **Sử dụng trong theme**:
```dart
TextTheme(
  bodyLarge: TextStyle(
    fontFamily: AssetsFonts.customFont,
  ),
)
```

## ✅ Best Practices

### 1. **Optimize images**
- Sử dụng PNG cho icons với transparency
- Sử dụng WebP cho illustrations (nếu Flutter hỗ trợ)
- Compress images trước khi add vào project

### 2. **Consistent naming**
- Sử dụng snake_case cho tên file
- Thêm suffix rõ ràng (@2x, @3x)
- Nhóm theo tính năng (user_*, setting_*, etc.)

### 3. **Size guidelines**
- **Icons**: 24x24, 48x48, 72x72 (1x, 2x, 3x)
- **Avatars**: 100x100, 200x200
- **Illustrations**: Max 400px width
- **Backgrounds**: Responsive, optimize cho mobile

### 4. **Performance**
- Sử dụng `Assets.getIcon()` cho auto-resolution
- Cache frequently used images
- Lazy load large illustrations

## 🚀 Ví dụ hoàn chỉnh

```dart
class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Responsive icon
        Image.asset(
          Assets.getIcon('home', pixelRatio: MediaQuery.of(context).devicePixelRatio),
          width: 24,
          height: 24,
        ),
        
        // Illustration
        Image.asset(AssetsIllustrations.welcome),
        
        // Avatar with fallback
        CircleAvatar(
          backgroundImage: AssetImage(AssetsAvatars.placeholder),
          radius: 30,
        ),
        
        // Background with extension
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('pattern.png'.asBackground),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Dynamic asset
        Image.asset(
          AssetPathBuilder(
            type: AssetType.logo,
            fileName: 'app_logo.png',
          ).path,
        ),
      ],
    );
  }
}
```

## 📝 Notes

- **Git tracking**: Tất cả thư mục có `.gitkeep` để track empty folders
- **pubspec.yaml**: Đã config để include tất cả asset paths
- **Constants**: Tất cả paths được manage trong `lib/shared/constants/assets.dart`
- **Extensions**: Có helper extensions cho quick access

## 🔧 Maintenance

### Kiểm tra assets không sử dụng
```bash
# TODO: Script để tìm unused assets
flutter packages pub run flutter_launcher_icons:main
```

### Update asset paths khi refactor
1. Update constants trong `assets.dart`
2. Run `flutter clean && flutter pub get`
3. Test trên nhiều devices với DPI khác nhau 