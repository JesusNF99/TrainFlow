import 'package:flutter/material.dart';

/// Central design-system tokens derived from DESIGN.md.
/// All screens import this file — never hardcode colours or shadows.
abstract final class AppColors {
  static const background = Color(0xFF131313); // #131313
  static const surface = Color(0xFF1E1E1E); // #1E1E1E
  static const surfaceContainerLowest = Color(0xFF0E0E0E); // Input wells
  static const surfaceContainerLow = Color(0xFF1C1B1B); // Secondary decks
  static const surfaceContainer = Color(0xFF201F1F); // Floating cards
  static const surfaceContainerHigh = Color(0xFF2A2A2A); // Overlays/sheets
  static const surfaceVariant = Color(0xFF252525);
  static const cyan = Color(0xFF00F5FF); // Electric Cyan
  static const lime = Color(0xFFCCFF00); // Neon Lime
  static const onBackground = Color(0xDEFFFFFF); // White 87%
  static const onSurface = Color(0xFFA0A0A0); // Muted Gray
  static const muted = Color(0xFF666666);
  static const danger = Color(0xFFFF3B5C);
}

abstract final class AppShadows {
  static const cyanGlow = [
    BoxShadow(
      color: Color(
        0x2600F5FF,
      ), // 15% cyan for 10-15% blur glow specified in DESIGN.md
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  static const cyanGlowStrong = [
    BoxShadow(
      color: Color(0x2600F5FF), // Max 15% opacity blur
      blurRadius: 48,
      spreadRadius: 0,
    ),
  ];
}

abstract final class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.onBackground,
    letterSpacing: 0.5,
  );

  static final displayLarge = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
  );

  static final titleLarge = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  static final titleMedium = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static final bodyMedium = _base.copyWith(
    fontSize: 14,
    color: AppColors.onSurface,
  );

  static final labelSmall = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: AppColors.muted,
  );
}

abstract final class AppTheme {
  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.cyan,
        onPrimary: AppColors.background,
        secondary: AppColors.lime,
        onSecondary: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.background,
        elevation: 8,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        hintStyle: TextStyle(color: AppColors.muted),
        labelStyle: TextStyle(color: AppColors.muted),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        border: UnderlineInputBorder(borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        titleTextStyle: AppTextStyles.titleMedium,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A), space: 1),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyan,
          backgroundColor: Colors.transparent,
          side: const BorderSide(
            color: Color(0x4D00F5FF),
            width: 1,
          ), // 30% alpha
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.onBackground,
          backgroundColor: AppColors.surfaceContainer,
          side: const BorderSide(
            color: Color(0x14FFFFFF),
            width: 1,
          ), // 8% alpha ghost border
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }
}
