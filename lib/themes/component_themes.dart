import 'package:flutter/material.dart';
import 'colors.dart';

/// Component themes cho các UI elements trong KienlongBank App
/// Tuân thủ Material Design 3 guidelines
class KienlongBankComponentThemes {
  KienlongBankComponentThemes._();

  // ========== APP BAR THEME ==========
  static AppBarTheme get lightAppBarTheme => AppBarTheme(
    backgroundColor: KienlongBankColors.primary,
    foregroundColor: Colors.white,
    elevation: 2,
    shadowColor: KienlongBankColors.primary.withValues(alpha: 0.3),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
    actionsIconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
    centerTitle: true,
    toolbarHeight: 56,
  );

  static AppBarTheme get darkAppBarTheme => AppBarTheme(
    backgroundColor: KienlongBankColors.darkSurface,
    foregroundColor: KienlongBankColors.darkOnSurface,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: const TextStyle(
      color: KienlongBankColors.darkOnSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    iconTheme: const IconThemeData(
      color: KienlongBankColors.darkOnSurface,
      size: 24,
    ),
    actionsIconTheme: const IconThemeData(
      color: KienlongBankColors.darkOnSurface,
      size: 24,
    ),
    centerTitle: true,
    toolbarHeight: 56,
  );

  // ========== CARD THEME ==========
  static CardThemeData get lightCardTheme => CardThemeData(
    color: KienlongBankColors.lightSurface,
    elevation: 2,
    shadowColor: KienlongBankColors.lightShadow,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
  );

  static CardThemeData get darkCardTheme => CardThemeData(
    color: KienlongBankColors.darkSurface,
    elevation: 2,
    shadowColor: KienlongBankColors.darkShadow,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
  );

  // ========== BUTTON THEMES ==========
  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: KienlongBankColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade300,
      disabledForegroundColor: Colors.grey.shade600,
      elevation: 2,
      shadowColor: KienlongBankColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: const Size(88, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  static OutlinedButtonThemeData get outlinedButtonTheme => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: KienlongBankColors.primary,
      disabledForegroundColor: Colors.grey.shade600,
      side: const BorderSide(color: KienlongBankColors.primary, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: const Size(88, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  static TextButtonThemeData get textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: KienlongBankColors.secondary,
      disabledForegroundColor: Colors.grey.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minimumSize: const Size(48, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  // ========== INPUT DECORATION THEME ==========
  static InputDecorationTheme get lightInputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: KienlongBankColors.lightSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: const TextStyle(
      color: KienlongBankColors.lightOnSurfaceVariant,
      fontSize: 14,
    ),
    labelStyle: const TextStyle(
      color: KienlongBankColors.lightOnSurfaceVariant,
      fontSize: 14,
    ),
    floatingLabelStyle: const TextStyle(
      color: KienlongBankColors.primary,
      fontSize: 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.error, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );

  static InputDecorationTheme get darkInputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: KienlongBankColors.darkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: const TextStyle(
      color: KienlongBankColors.darkOnSurfaceVariant,
      fontSize: 14,
    ),
    labelStyle: const TextStyle(
      color: KienlongBankColors.darkOnSurfaceVariant,
      fontSize: 14,
    ),
    floatingLabelStyle: const TextStyle(
      color: KienlongBankColors.primary,
      fontSize: 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.darkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.darkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: KienlongBankColors.error, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade600),
    ),
  );

  // ========== BOTTOM NAVIGATION BAR THEME ==========
  static BottomNavigationBarThemeData get lightBottomNavigationBarTheme => 
    const BottomNavigationBarThemeData(
      backgroundColor: KienlongBankColors.lightSurface,
      selectedItemColor: KienlongBankColors.primary,
      unselectedItemColor: KienlongBankColors.lightOnSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );

  static BottomNavigationBarThemeData get darkBottomNavigationBarTheme => 
    const BottomNavigationBarThemeData(
      backgroundColor: KienlongBankColors.darkSurface,
      selectedItemColor: KienlongBankColors.primary,
      unselectedItemColor: KienlongBankColors.darkOnSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );

  // ========== FLOATING ACTION BUTTON THEME ==========
  static FloatingActionButtonThemeData get floatingActionButtonTheme => 
    const FloatingActionButtonThemeData(
      backgroundColor: KienlongBankColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: CircleBorder(),
    );

  // ========== BOTTOM SHEET THEME ==========
  static BottomSheetThemeData get lightBottomSheetTheme => const BottomSheetThemeData(
    backgroundColor: KienlongBankColors.lightSurface,
    elevation: 8,
    modalElevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxWidth: double.infinity),
  );

  static BottomSheetThemeData get darkBottomSheetTheme => const BottomSheetThemeData(
    backgroundColor: KienlongBankColors.darkSurface,
    elevation: 8,
    modalElevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxWidth: double.infinity),
  );

  // ========== DIALOG THEME ==========
  static DialogThemeData get lightDialogTheme => DialogThemeData(
    backgroundColor: KienlongBankColors.lightSurface,
    elevation: 24,
    shadowColor: KienlongBankColors.lightShadow,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: const TextStyle(
      color: KienlongBankColors.lightOnSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: const TextStyle(
      color: KienlongBankColors.lightOnSurface,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  );

  static DialogThemeData get darkDialogTheme => DialogThemeData(
    backgroundColor: KienlongBankColors.darkSurface,
    elevation: 24,
    shadowColor: KienlongBankColors.darkShadow,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: const TextStyle(
      color: KienlongBankColors.darkOnSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: const TextStyle(
      color: KienlongBankColors.darkOnSurface,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  );

  // ========== SNACK BAR THEME ==========
  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    backgroundColor: KienlongBankColors.tertiary,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
    actionTextColor: KienlongBankColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 6,
  );
} 