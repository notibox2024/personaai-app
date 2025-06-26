import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'text_theme.dart';
import 'component_themes.dart';

/// Main theme configuration cho KienlongBank App
/// Kế thừa từ Material Design 3 và customize theo brand identity
class KienlongBankTheme {
  KienlongBankTheme._();

  // ========== COLOR SCHEMES ==========
  static ColorScheme get lightColorScheme => ColorScheme.light(
    // Brand colors
    primary: KienlongBankColors.primary,
    onPrimary: Colors.white,
    primaryContainer: KienlongBankColors.primary.withValues(alpha: 0.1),
    onPrimaryContainer: KienlongBankColors.primary,
    
    secondary: KienlongBankColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: KienlongBankColors.secondary.withValues(alpha: 0.1),
    onSecondaryContainer: KienlongBankColors.secondary,
    
    tertiary: KienlongBankColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: KienlongBankColors.tertiary.withValues(alpha: 0.1),
    onTertiaryContainer: KienlongBankColors.tertiary,
    
    // Surface colors (background deprecated, sử dụng surface)
    surface: KienlongBankColors.lightSurface,                   // #FFFFFF - cards
    onSurface: KienlongBankColors.lightOnSurface,
    surfaceContainerLowest: KienlongBankColors.lightBackground, // #FAFAFA - main background
    surfaceContainer: KienlongBankColors.lightSurfaceContainer, // #F8F8F8 - trung gian
    surfaceContainerHighest: KienlongBankColors.lightSurfaceVariant, // #F5F5F5
    onSurfaceVariant: KienlongBankColors.lightOnSurfaceVariant,
    
    // Semantic colors
    error: KienlongBankColors.error,
    onError: KienlongBankColors.onError,
    errorContainer: KienlongBankColors.errorContainer,
    onErrorContainer: KienlongBankColors.onErrorContainer,
    
    // Outline colors
    outline: KienlongBankColors.lightOutline,
    outlineVariant: KienlongBankColors.lightOutlineVariant,
    
    // Shadow
    shadow: Colors.black,
    scrim: Colors.black54,
    
    // Inverse colors
    inverseSurface: KienlongBankColors.darkSurface,
    onInverseSurface: KienlongBankColors.darkOnSurface,
    inversePrimary: KienlongBankColors.primary.withValues(alpha: 0.8),
  );

  static ColorScheme get darkColorScheme => ColorScheme.dark(
    // Brand colors
    primary: KienlongBankColors.primary,
    onPrimary: Colors.white,
    primaryContainer: KienlongBankColors.primary.withValues(alpha: 0.2),
    onPrimaryContainer: KienlongBankColors.primary,
    
    secondary: KienlongBankColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: KienlongBankColors.secondary.withValues(alpha: 0.2),
    onSecondaryContainer: KienlongBankColors.secondary,
    
    tertiary: KienlongBankColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: KienlongBankColors.tertiary.withValues(alpha: 0.2),
    onTertiaryContainer: KienlongBankColors.tertiary,
    
    // Surface colors (background deprecated, sử dụng surface)
    surface: KienlongBankColors.darkSurface,                    // #1E1E1E - cards
    onSurface: KienlongBankColors.darkOnSurface,
    surfaceContainerLowest: KienlongBankColors.darkBackground,  // #121212 - main background
    surfaceContainer: KienlongBankColors.darkSurfaceContainer,  // #1A1A1A - trung gian
    surfaceContainerHighest: KienlongBankColors.darkSurfaceVariant, // #2A2A2A
    onSurfaceVariant: KienlongBankColors.darkOnSurfaceVariant,
    
    // Semantic colors
    error: KienlongBankColors.error,
    onError: KienlongBankColors.onError,
    errorContainer: KienlongBankColors.errorContainer,
    onErrorContainer: KienlongBankColors.onErrorContainer,
    
    // Outline colors
    outline: KienlongBankColors.darkOutline,
    outlineVariant: KienlongBankColors.darkOutlineVariant,
    
    // Shadow
    shadow: Colors.black,
    scrim: Colors.black87,
    
    // Inverse colors
    inverseSurface: KienlongBankColors.lightSurface,
    onInverseSurface: KienlongBankColors.lightOnSurface,
    inversePrimary: KienlongBankColors.primary,
  );

  // ========== LIGHT THEME ==========
  static ThemeData get lightTheme {
    final colorScheme = lightColorScheme;
    
    return ThemeData(
      // Theme basics
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      
      // Typography
      textTheme: KienlongBankTextTheme.lightTextTheme,
      primaryTextTheme: KienlongBankTextTheme.lightTextTheme,
      
      // Component themes
      appBarTheme: KienlongBankComponentThemes.lightAppBarTheme,
      cardTheme: KienlongBankComponentThemes.lightCardTheme,
      elevatedButtonTheme: KienlongBankComponentThemes.elevatedButtonTheme,
      outlinedButtonTheme: KienlongBankComponentThemes.outlinedButtonTheme,
      textButtonTheme: KienlongBankComponentThemes.textButtonTheme,
      inputDecorationTheme: KienlongBankComponentThemes.lightInputDecorationTheme,
      bottomNavigationBarTheme: KienlongBankComponentThemes.lightBottomNavigationBarTheme,
      floatingActionButtonTheme: KienlongBankComponentThemes.floatingActionButtonTheme,
      bottomSheetTheme: KienlongBankComponentThemes.lightBottomSheetTheme,
      dialogTheme: KienlongBankComponentThemes.lightDialogTheme,
      snackBarTheme: KienlongBankComponentThemes.snackBarTheme,
      
      // Additional customizations - không set scaffoldBackgroundColor để cho phép custom
      canvasColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.12),
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: 24,
      ),
      
      // Switch, checkbox, radio themes - Updated với WidgetStateProperty
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        brightness: Brightness.light,
      ),
      
      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      
      // Expansion tile theme
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
      ),
    );
  }

  // ========== DARK THEME ==========
  static ThemeData get darkTheme {
    final colorScheme = darkColorScheme;
    
    return ThemeData(
      // Theme basics
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // Typography
      textTheme: KienlongBankTextTheme.darkTextTheme,
      primaryTextTheme: KienlongBankTextTheme.darkTextTheme,
      
      // Component themes
      appBarTheme: KienlongBankComponentThemes.darkAppBarTheme,
      cardTheme: KienlongBankComponentThemes.darkCardTheme,
      elevatedButtonTheme: KienlongBankComponentThemes.elevatedButtonTheme,
      outlinedButtonTheme: KienlongBankComponentThemes.outlinedButtonTheme,
      textButtonTheme: KienlongBankComponentThemes.textButtonTheme,
      inputDecorationTheme: KienlongBankComponentThemes.darkInputDecorationTheme,
      bottomNavigationBarTheme: KienlongBankComponentThemes.darkBottomNavigationBarTheme,
      floatingActionButtonTheme: KienlongBankComponentThemes.floatingActionButtonTheme,
      bottomSheetTheme: KienlongBankComponentThemes.darkBottomSheetTheme,
      dialogTheme: KienlongBankComponentThemes.darkDialogTheme,
      snackBarTheme: KienlongBankComponentThemes.snackBarTheme,
      
      // Additional customizations - không set scaffoldBackgroundColor để cho phép custom
      canvasColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.12),
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: 24,
      ),
      
      // Switch, checkbox, radio themes - Updated với WidgetStateProperty
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        brightness: Brightness.dark,
      ),
      
      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      
      // Expansion tile theme
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
      ),
    );
  }

  // ========== SYSTEM UI OVERLAY STYLES ==========
  /// System UI overlay style cho light theme
  static SystemUiOverlayStyle get lightSystemUiOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: KienlongBankColors.lightSurface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: KienlongBankColors.lightOutline,
  );

  /// System UI overlay style cho dark theme  
  static SystemUiOverlayStyle get darkSystemUiOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: KienlongBankColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: KienlongBankColors.darkOutline,
  );
} 