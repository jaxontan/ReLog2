import 'package:flutter/material.dart';

class AppTheme {
  // ponytail: hand-picked palette — no auto-generated derivatives.
  static const _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF823B18),        // leather brown
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8D0C2),
    secondary: Color(0xFF446464),      // muted teal
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFC6E9E9),
    surface: Color(0xFFFFF8F6),        // warm beige
    onSurface: Color(0xFF2C1E1A),      // journal ink
    surfaceContainerHighest: Color(0xFFEFDFD9),
    surfaceDim: Color(0xFFE7D7D1),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _scheme,
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _scheme.copyWith(
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1512),
          onSurface: const Color(0xFFFEEDE8),
          primary: const Color(0xFFFFB596),
          onPrimary: const Color(0xFF360F00),
          surfaceContainerHighest: const Color(0xFF3A2E2B),
          surfaceDim: const Color(0xFF2E2220),
        ),
        brightness: Brightness.dark,
      );
}
