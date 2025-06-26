import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography system cho KienlongBank App
/// Kế thừa từ Material Design 3 và tùy chỉnh cho brand
class KienlongBankTextTheme {
  KienlongBankTextTheme._();

  /// Font family mặc định
  static const String fontFamily = 'Roboto';

  /// Base TextTheme cho Light mode
  static TextTheme get lightTextTheme => const TextTheme(
    // Display styles - Cho tiêu đề lớn
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
      color: KienlongBankColors.lightOnBackground,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
      color: KienlongBankColors.lightOnBackground,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
      color: KienlongBankColors.lightOnBackground,
    ),

    // Headline styles - Cho tiêu đề section
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.25,
      color: KienlongBankColors.lightOnBackground,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.29,
      color: KienlongBankColors.lightOnBackground,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.33,
      color: KienlongBankColors.lightOnBackground,
    ),

    // Title styles - Cho tiêu đề card, dialog
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.27,
      color: KienlongBankColors.lightOnSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
      color: KienlongBankColors.lightOnSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      color: KienlongBankColors.lightOnSurface,
    ),

    // Label styles - Cho button, input label
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      color: KienlongBankColors.lightOnSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
      color: KienlongBankColors.lightOnSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
      color: KienlongBankColors.lightOnSurfaceVariant,
    ),

    // Body styles - Cho nội dung chính
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.50,
      color: KienlongBankColors.lightOnSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
      color: KienlongBankColors.lightOnSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
      color: KienlongBankColors.lightOnSurfaceVariant,
    ),
  );

  /// Base TextTheme cho Dark mode
  static TextTheme get darkTextTheme => lightTextTheme.copyWith(
    displayLarge: lightTextTheme.displayLarge?.copyWith(
      color: KienlongBankColors.darkOnBackground,
    ),
    displayMedium: lightTextTheme.displayMedium?.copyWith(
      color: KienlongBankColors.darkOnBackground,
    ),
    displaySmall: lightTextTheme.displaySmall?.copyWith(
      color: KienlongBankColors.darkOnBackground,
    ),
    headlineLarge: lightTextTheme.headlineLarge?.copyWith(
      color: KienlongBankColors.darkOnBackground,
    ),
    headlineMedium: lightTextTheme.headlineMedium?.copyWith(
      color: KienlongBankColors.darkOnBackground,
    ),
    headlineSmall: lightTextTheme.headlineSmall?.copyWith(
      color: KienlongBankColors.darkOnBackground,
    ),
    titleLarge: lightTextTheme.titleLarge?.copyWith(
      color: KienlongBankColors.darkOnSurface,
    ),
    titleMedium: lightTextTheme.titleMedium?.copyWith(
      color: KienlongBankColors.darkOnSurface,
    ),
    titleSmall: lightTextTheme.titleSmall?.copyWith(
      color: KienlongBankColors.darkOnSurface,
    ),
    labelLarge: lightTextTheme.labelLarge?.copyWith(
      color: KienlongBankColors.darkOnSurface,
    ),
    labelMedium: lightTextTheme.labelMedium?.copyWith(
      color: KienlongBankColors.darkOnSurfaceVariant,
    ),
    labelSmall: lightTextTheme.labelSmall?.copyWith(
      color: KienlongBankColors.darkOnSurfaceVariant,
    ),
    bodyLarge: lightTextTheme.bodyLarge?.copyWith(
      color: KienlongBankColors.darkOnSurface,
    ),
    bodyMedium: lightTextTheme.bodyMedium?.copyWith(
      color: KienlongBankColors.darkOnSurface,
    ),
    bodySmall: lightTextTheme.bodySmall?.copyWith(
      color: KienlongBankColors.darkOnSurfaceVariant,
    ),
  );
}

/// Custom text styles cho các use case đặc biệt
class KienlongBankCustomTextStyles {
  KienlongBankCustomTextStyles._();

  /// Style cho số tiền
  static const TextStyle currency = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: KienlongBankColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Style cho mã số (account number, transaction ID)
  static const TextStyle code = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    fontFamily: 'monospace',
    color: KienlongBankColors.tertiary,
  );

  /// Style cho caption với màu primary
  static const TextStyle captionPrimary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: KienlongBankColors.primary,
  );

  /// Style cho caption thành công
  static const TextStyle captionSuccess = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: KienlongBankColors.success,
  );

  /// Style cho caption cảnh báo
  static const TextStyle captionWarning = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: KienlongBankColors.warning,
  );

  /// Style cho caption lỗi
  static const TextStyle captionError = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: KienlongBankColors.error,
  );
} 