# 🚀 PersonaAI Splash Screen

Hướng dẫn tạo splash screen cho PersonaAI với Kienlongbank branding.

## 📋 Files cần tạo

| File | Mô tả | Kích thước | Format |
|------|-------|------------|---------|
| `splash_logo.png` | Logo chính cho splash | 300x300 px | PNG với nền trong suốt |
| `splash_background.png` | Background (optional) | 1080x1920 px | PNG |

## 🎨 Thiết kế Splash Logo

### Thông số kỹ thuật:
- **Kích thước**: 300x300 px (sẽ được resize tự động)
- **Format**: PNG với alpha channel
- **Nền**: Trong suốt (transparent)
- **Logo**: Kienlongbank logo màu trắng
- **Style**: Clean, minimal

### Nguồn gốc:
- Sử dụng `assets/images/logos/kienlongbank_logo.svg`
- Convert sang PNG với màu trắng
- Kích thước 300x300px với logo centered

## 🛠️ Cách tạo Splash Logo

### Với Figma:

1. **Tạo Frame**:
   ```
   - Kích thước: 300x300 px
   - Background: Transparent
   ```

2. **Import SVG**:
   ```
   - File → Place Image
   - Chọn: kienlongbank_logo.svg
   - Resize: ~240x240 px (80% của frame)
   - Position: Center
   ```

3. **Điều chỉnh**:
   ```
   - Đổi màu logo: #FFFFFF (White)
   - Đảm bảo nền trong suốt
   - Check contrast trên nền xanh #2E7BD6
   ```

4. **Export**:
   ```
   - Format: PNG
   - Background: Transparent
   - Scale: 1x
   - Filename: splash_logo.png
   ```

### Với GIMP:

1. **Tạo image**:
   ```
   File → New
   Width: 300px
   Height: 300px
   Fill: Transparency
   ```

2. **Import SVG**:
   ```
   File → Open as Layers
   Chọn: kienlongbank_logo.svg
   Resize về ~240px
   Center trong canvas
   ```

3. **Điều chỉnh màu**:
   ```
   Colors → Desaturate
   Colors → Color to Alpha (remove background)
   Colors → Fill with white
   ```

4. **Export**:
   ```
   File → Export As
   Format: PNG
   Compression: 9
   ```

## 🎯 Color Scheme

```css
/* Splash Screen Colors */
--splash-primary: #2E7BD6;    /* Background gradient start */
--splash-secondary: #1E5A96;  /* Background gradient end */
--splash-logo: #FFFFFF;       /* Logo color */
--splash-text: #FFFFFF;       /* Text color */
--splash-accent: #4A90E2;     /* Loading indicator */
```

## 📱 Platform Support

Splash screen được generate cho:

- **Android**: Native splash (API 12+) + Legacy
- **iOS**: LaunchScreen.storyboard
- **Web**: Custom splash overlay
- **Desktop**: Window splash

## 🚀 Generate Commands

Sau khi có `splash_logo.png`:

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate native splash screens
dart run flutter_native_splash:create

# 3. Clean and rebuild
flutter clean
flutter pub get
```

## 🔧 Configuration

File cấu hình trong `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#2E7BD6"
  image: "assets/images/splash/splash_logo.png"
  color_dark: "#2E7BD6"
  image_dark: "assets/images/splash/splash_logo.png"
  
  android_12:
    image: "assets/images/splash/splash_logo.png"
    color: "#2E7BD6"
    
  ios:
    image: "assets/images/splash/splash_logo.png"
    color: "#2E7BD6"
    
  web:
    image: "assets/images/splash/splash_logo.png"
    color: "#2E7BD6"
```

## ✨ Features

Splash screen bao gồm:

- **Animated logo**: Scale + elastic effect
- **Gradient background**: Kienlongbank blue gradient
- **Loading indicator**: White circular progress
- **App info**: PersonaAI name + tagline
- **Copyright**: Kienlongbank branding

## 🎬 Animation Sequence

1. **0-300ms**: Prepare animations
2. **300-1800ms**: Logo scale animation (elastic)
3. **800-1600ms**: Text slide + fade animation
4. **1600-4100ms**: Show loading + copyright
5. **4100ms**: Navigate to main app

## 📄 Files Structure

```
splash/
├── README.md              # File này
├── splash_logo.png        # Logo chính (cần tạo)
├── splash_background.png  # Background (optional)
└── .gitkeep              # Git tracking
```

## 🎯 Checklist

- [ ] Tạo `splash_logo.png` (300x300, transparent)
- [ ] Logo màu trắng, center
- [ ] Test trên nền xanh #2E7BD6
- [ ] Chạy `dart run flutter_native_splash:create`
- [ ] Test trên device/simulator
- [ ] Kiểm tra tất cả platforms

---

💡 **Tip**: Logo nên đơn giản và rõ ràng vì sẽ hiển thị trong thời gian ngắn! 