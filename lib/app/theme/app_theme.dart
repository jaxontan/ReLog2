import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),  // ponytail: forest green (shared album vibe)
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),  // ponytail: forest green (shared album vibe)
        brightness: Brightness.dark,
      );
}
