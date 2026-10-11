import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const lightCanvas = Color(0xFFF4F6F8);
  static const lightInk = Color(0xFF11232D);
  static const lightMuted = Color(0xFF586974);
  static const lightTeal = Color(0xFF0D7E88);
  static const lightIllustration = Color(0xFFDDF1EF);
  static const lightTrack = Color(0xFFD4DBDF);

  static const darkCanvas = Color(0xFF101B22);
  static const darkInk = Color(0xFFF3F7F8);
  static const darkMuted = Color(0xFFB6C5CC);
  static const darkTeal = Color(0xFF49B8BE);
  static const darkIllustration = Color(0xFF1B373B);
  static const darkSurface = Color(0xFF263B42);
  static const darkTrack = Color(0xFF52676E);

  static const avatarColors = <Color>[
    Color(0xFF0D7E88),
    Color(0xFFC6500A),
    Color(0xFF6C49C8),
    Color(0xFF3264C9),
    Color(0xFF2F8557),
    Color(0xFFC53678),
  ];

  static Color memberColor(int index) =>
      avatarColors[index % avatarColors.length];
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? AppPalette.darkTeal : AppPalette.lightTeal;
    final surface = dark ? AppPalette.darkCanvas : AppPalette.lightCanvas;
    final ink = dark ? AppPalette.darkInk : AppPalette.lightInk;
    final muted = dark ? AppPalette.darkMuted : AppPalette.lightMuted;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(primary: primary, onSurface: ink, onSurfaceVariant: muted);
    final baseTextTheme = Typography.material2021().black.apply(
      fontFamily: 'Figtree',
      bodyColor: ink,
      displayColor: ink,
    );
    final textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Figtree',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: dark ? AppPalette.darkCanvas : Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Figtree',
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
