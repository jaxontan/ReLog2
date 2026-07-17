import 'package:flutter/material.dart';
import '../design/design_system.dart';

/// ReLog2 App Theme
/// Uses the design system tokens for consistent light/dark themes.
class AppTheme {
  static ThemeData get light => DSTheme.light;
  static ThemeData get dark => DSTheme.dark;
}