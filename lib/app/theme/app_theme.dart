import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D1A1A),  // ponytail: maroon / dark red (expedition vibe)
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D1A1A),  // ponytail: maroon / dark red (expedition vibe)
        brightness: Brightness.dark,
      );
}
