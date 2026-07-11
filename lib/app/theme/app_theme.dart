import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFD97706),  // ponytail: warm amber (treasure-hunt vibe)
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFD97706),  // ponytail: warm amber (treasure-hunt vibe)
        brightness: Brightness.dark,
      );
}
