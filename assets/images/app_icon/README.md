# 🎨 PersonaAI App Icon

Hướng dẫn tạo app icon cho PersonaAI với Kienlongbank branding.

## 📋 Thông số kỹ thuật

| Thuộc tính | Giá trị |
|------------|---------|
| **Kích thước** | 1024x1024 px |
| **Format** | PNG (24-bit) |
| **Màu nền** | #2E7BD6 (Kienlongbank Blue) |
| **Icon** | `assets/images/logos/kienlongbank_icon.svg` |
| **Icon color** | #FFFFFF (White) |
| **Icon size** | 60-70% của canvas (~650px) |
| **Position** | Center |

## 🎨 Color Palette

```css
/* Kienlongbank Brand Colors */
--primary-blue: #2E7BD6;
--dark-blue: #1E5A96;
--light-blue: #4A90E2;
--white: #FFFFFF;
```

## 🛠️ Tools khuyến nghị

### 1. **Figma** (Miễn phí) ⭐
- Website: [figma.com](https://figma.com)
- Hỗ trợ SVG import tốt
- Export PNG chất lượng cao

### 2. **GIMP** (Miễn phí)
- Website: [gimp.org](https://gimp.org)
- Open source, đầy đủ tính năng
- Hỗ trợ mọi platform

### 3. **Canva** (Miễn phí)
- Website: [canva.com](https://canva.com)
- Dễ sử dụng cho người mới
- Templates có sẵn

### 4. **Adobe Illustrator** (Trả phí)
- Chuyên nghiệp, hỗ trợ SVG tốt nhất

## 📐 Hướng dẫn chi tiết

### Với Figma:

1. **Tạo project mới**
   ```
   File → New → Design file
   ```

2. **Tạo Frame**
   ```
   - Kích thước: 1024x1024 px
   - Tên: "App Icon"
   ```

3. **Thêm background**
   ```
   - Rectangle tool (R)
   - Size: 1024x1024 px
   - Fill: #2E7BD6
   ```

4. **Import SVG icon**
   ```
   - File → Place image
   - Chọn: assets/images/logos/kienlongbank_icon.svg
   - Resize: ~650x650 px
   - Position: Center (512, 512)
   ```

5. **Adjust icon**
   ```
   - Color: #FFFFFF (White)
   - Ensure sharp edges
   ```

6. **Export**
   ```
   - Select Frame
   - Export → PNG
   - 1x scale
   - Save as: app_icon.png
   ```

### Với GIMP:

1. **Tạo image mới**
   ```
   File → New
   Width: 1024px
   Height: 1024px
   Fill: #2E7BD6
   ```

2. **Import SVG**
   ```
   File → Open as Layers
   Chọn kienlongbank_icon.svg
   Resize về ~650px
   ```

3. **Điều chỉnh**
   ```
   - Center icon
   - Change color to white
   - Colors → Desaturate → Color to Alpha
   - Fill white
   ```

4. **Export**
   ```
   File → Export As
   Filename: app_icon.png
   ```

## 💾 File output

Lưu file với tên: **`app_icon.png`**  
Trong thư mục: `assets/images/app_icon/`

## 🚀 Generate app icons

Sau khi có file `app_icon.png`:

```bash
# 1. Cập nhật dependencies
flutter pub get

# 2. Generate app icons cho tất cả platforms
dart run flutter_launcher_icons

# 3. Clean build (optional)
flutter clean && flutter pub get
```

## 📱 Kết quả

Script sẽ tự động tạo:

- **Android**: Adaptive icons với background/foreground
- **iOS**: App icon với corner radius tự động
- **Web**: Favicon và PWA icons
- **Desktop**: Icons cho Windows/macOS/Linux

## 🔧 Troubleshooting

### Icon bị mờ/pixel
- Đảm bảo SVG chất lượng cao
- Không scale lên từ icon nhỏ
- Export với 1x scale (không anti-aliasing quá mức)

### Màu không đúng
- Kiểm tra color profile (sRGB)
- Đảm bảo background là #2E7BD6
- Icon phải màu trắng (#FFFFFF)

### Build lỗi
```bash
# Clean project
flutter clean
flutter pub get

# Check flutter_launcher_icons config
flutter pub deps
```

## 📄 Files trong thư mục

```
app_icon/
├── README.md              # File này
├── template.html          # Preview template
├── app_icon.png          # Icon chính (cần tạo)
└── .gitkeep              # Git tracking
```

## 🎯 Quick checklist

- [ ] File `app_icon.png` tồn tại
- [ ] Kích thước 1024x1024 px
- [ ] Màu nền #2E7BD6
- [ ] Icon màu trắng, center
- [ ] Format PNG 24-bit
- [ ] Chạy `dart run flutter_launcher_icons`
- [ ] Test trên device/simulator

---

💡 **Tip**: Mở `template.html` trong browser để xem preview design trước khi tạo! 