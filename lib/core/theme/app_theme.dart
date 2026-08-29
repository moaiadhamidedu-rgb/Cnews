import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppColorTheme { original, sapphire, royalPlum }

class AppThemePalette {
  const AppThemePalette({
    required this.primary,
    required this.secondary,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.lightSurface,
    required this.darkSurface,
  });

  final Color primary;
  final Color secondary;
  final Color darkPrimary;
  final Color darkSecondary;
  final Color lightSurface;
  final Color darkSurface;
}

class AppThemes {
  AppThemes._();

  static const Map<AppColorTheme, AppThemePalette> palettes = {
    AppColorTheme.original: AppThemePalette(
      primary: Color(0xFF466365),
      secondary: Color(0xFFB49A67),
      darkPrimary: Color(0xFFB49A67),
      darkSecondary: Color(0xFF466365),
      lightSurface: Color(0xFFFDFCFB),
      darkSurface: Color(0xFF0F1111),
    ),
    AppColorTheme.sapphire: AppThemePalette(
      primary: Color(0xFF0F4C81),
      secondary: Color(0xFF18A6A6),
      darkPrimary: Color(0xFF68BFFF),
      darkSecondary: Color(0xFF4BD8CA),
      lightSurface: Color(0xFFF6F9FC),
      darkSurface: Color(0xFF081521),
    ),
    AppColorTheme.royalPlum: AppThemePalette(
      primary: Color(0xFF5B3F8C),
      secondary: Color(0xFFD08A73),
      darkPrimary: Color(0xFFC4A7FF),
      darkSecondary: Color(0xFFFFAD94),
      lightSurface: Color(0xFFFBF8FC),
      darkSurface: Color(0xFF17111D),
    ),
  };

  static AppThemePalette paletteOf(AppColorTheme theme) => palettes[theme]!;

  static ThemeData build(AppColorTheme selectedTheme, Brightness brightness) {
    final palette = paletteOf(selectedTheme);
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? palette.darkPrimary : palette.primary;
    final secondary = isDark ? palette.darkSecondary : palette.secondary;
    final surface = isDark ? palette.darkSurface : palette.lightSurface;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: primary.withValues(alpha: isDark ? 0.28 : 0.10),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerLow
            : Colors.white,
        indicatorColor: primary.withValues(alpha: 0.14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.35)
              : null,
        ),
      ),
    );
  }
}
