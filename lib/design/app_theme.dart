import 'package:flutter/material.dart';
import 'app_skin.dart';
export 'app_skin.dart';

ThemeData buildAppTheme([AppSkin skin = AppSkin.forest]) {
  final colors = skin.palette;
  final scheme = ColorScheme.fromSeed(seedColor: colors.forest).copyWith(
    primary: colors.forest,
    onPrimary: Colors.white,
    secondary: colors.forest,
    surface: colors.paper,
    onSurface: colors.ink,
    outlineVariant: colors.line,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Paperlogy',
    colorScheme: scheme,
  );
  final text = base.textTheme.apply(
    bodyColor: colors.ink,
    displayColor: colors.ink,
  );
  return base.copyWith(
    extensions: [colors],
    scaffoldBackgroundColor: colors.paper,
    textTheme: text.copyWith(
      headlineLarge: TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 32,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.3,
        color: colors.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 27,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: colors.ink,
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
    appBarTheme: AppBarTheme(
      backgroundColor: colors.paper,
      foregroundColor: colors.ink,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.line, width: .8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.forest, width: 1.5),
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
      backgroundColor: colors.soft,
      selectedColor: colors.lime,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.paper,
      indicatorColor: colors.lime,
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.forest,
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
  );
}
