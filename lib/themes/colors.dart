import 'package:flutter/material.dart';

/// Định nghĩa màu sắc nhận diện thương hiệu KienlongBank
/// Dựa trên hướng dẫn brand guidelines của KienlongBank
class KienlongBankColors {
  KienlongBankColors._(); // Private constructor để ngăn tạo instance

  // ========== BRAND COLORS ==========
  /// Màu cam chính - CMYK 00 85 100 00
  /// Thể hiện tính năng động, hiện đại, trẻ trung nhiệt huyết
  static const Color primary = Color(0xFFFF4100);
  
  /// Màu xanh da trời - CMYK 75 35 00 00  
  /// Thể hiện công nghệ, tin cậy, thời thượng
  static const Color secondary = Color(0xFF40A6FF);
  
  /// Màu xanh dương đậm - CMYK 95 85 45 60
  /// Màu bổ trợ, làm nền để nổi bật logo
  static const Color tertiary = Color(0xFF0A1938);

  // ========== LIGHT THEME COLORS ==========
  static const Color lightBackground = Color(0xFFF5F5F5);      // surfaceContainerLowest - đậm hơn
  static const Color lightSurface = Color(0xFFFFFFFF);         // surface - cho cards
  static const Color lightSurfaceContainer = Color(0xFFF8F8F8); // surfaceContainer - trung gian
  static const Color lightSurfaceVariant = Color(0xFFF2F2F2);   // surfaceContainerHighest
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF2E2E2E);
  static const Color lightOnSurfaceVariant = Color(0xFF666666);
  static const Color lightOutline = Color(0xFFE0E0E0);
  static const Color lightOutlineVariant = Color(0xFFF0F0F0);

  // ========== DARK THEME COLORS ==========
  static const Color darkBackground = Color(0xFF0F0F0F);        // surfaceContainerLowest - đậm hơn
  static const Color darkSurface = Color(0xFF1E1E1E);           // surface - cho cards
  static const Color darkSurfaceContainer = Color(0xFF1A1A1A);  // surfaceContainer - trung gian
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);    // surfaceContainerHighest
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOnSurfaceVariant = Color(0xFFB0B0B0);
  static const Color darkOutline = Color(0xFF404040);
  static const Color darkOutlineVariant = Color(0xFF333333);

  // ========== SEMANTIC COLORS ==========
  /// Màu thành công
  static const Color success = Color(0xFF4CAF50);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  /// Màu cảnh báo
  static const Color warning = Color(0xFFFF9800);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarningContainer = Color(0xFFE65100);

  /// Màu lỗi
  static const Color error = Color(0xFFF44336);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onErrorContainer = Color(0xFFC62828);

  /// Màu thông tin
  static const Color info = Color(0xFF2196F3);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color onInfoContainer = Color(0xFF0D47A1);

  // ========== GRADIENT COLORS ==========
  /// Gradient chính cho header/banner - Light theme
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFFF6B00)],
  );

  /// Gradient chính cho header/banner - Dark theme
  static const LinearGradient primaryGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF663300)], // Much darker gradient for dark theme
  );

  /// Gradient phụ cho background
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondary, Color(0xFF1976D2)],
  );

  // ========== SHADOW COLORS ==========
  static Color get lightShadow => Colors.black.withValues(alpha: 0.08);
  static Color get darkShadow => Colors.black.withValues(alpha: 0.25);
}

/// Extension để dễ dàng truy cập màu theo theme
extension KienlongBankColorsExtension on ColorScheme {
  /// Màu success theo theme hiện tại
  Color get success => brightness == Brightness.light
      ? KienlongBankColors.success
      : KienlongBankColors.success;
      
  Color get onSuccess => KienlongBankColors.onSuccess;
  
  /// Màu warning theo theme hiện tại  
  Color get warning => KienlongBankColors.warning;
  Color get onWarning => KienlongBankColors.onWarning;
  
  /// Màu info theo theme hiện tại
  Color get info => KienlongBankColors.info;
  Color get onInfo => KienlongBankColors.onInfo;

  /// Gradient primary theo theme hiện tại
  LinearGradient get primaryGradient => brightness == Brightness.light
      ? KienlongBankColors.primaryGradient
      : KienlongBankColors.primaryGradientDark;

  /// Màu header theo theme hiện tại
  Color get headerColor => brightness == Brightness.light
      ? primary
      : surfaceContainer;
} 