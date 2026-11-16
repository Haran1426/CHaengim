import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFF6F4EF);
  static const ink = Color(0xFF263C35);
  static const forest = Color(0xFF244C3F);
  static const lime = Color(0xFFE0EEAC);
  static const muted = Color(0xFF72796F);
  static const line = Color(0xFFE5E5DB);
  static const rust = Color(0xFFAF4E2E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.forest).copyWith(
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.forest,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
    outlineVariant: AppColors.line,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Paperlogy',
    colorScheme: scheme,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: text.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 32,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.3,
        color: AppColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 27,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: AppColors.ink,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -.6,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -.3,
      ),
      bodyMedium: text.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.6,
        letterSpacing: -.2,
      ),
      bodyLarge: text.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        letterSpacing: -.3,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line, width: .8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Paperlogy',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide.none,
      backgroundColor: const Color(0xFFECEDE5),
      selectedColor: AppColors.lime,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.paper,
      indicatorColor: AppColors.lime,
      elevation: 0,
      height: 76,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Paperlogy',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.forest,
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
  );
}
