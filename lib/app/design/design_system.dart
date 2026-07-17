/// ReLog2 Design System
///
/// A cohesive design language inspired by iOS Human Interface Guidelines
/// and Material Design 3, with a warm "Cartographer's Journal" aesthetic.
///
/// Principles:
/// - Clarity: Visual hierarchy guides attention
/// - Deference: UI recedes; content shines
/// - Depth: Layered surfaces convey hierarchy
/// - Consistency: Familiar patterns reduce cognitive load

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════

/// Semantic color palette for light & dark modes.
/// Warm journal tones: leather brown primary, warm beige surfaces, muted teal secondary.
abstract class DSColors {
  // Light mode
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    // Primary - leather brown
    primary: Color(0xFF823B18),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8D0C2),
    onPrimaryContainer: Color(0xFF360F00),
    // Secondary - muted teal
    secondary: Color(0xFF446464),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFC6E9E9),
    onSecondaryContainer: Color(0xFF001F1F),
    // Tertiary - warm accent
    tertiary: Color(0xFFB87333),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBC0),
    onTertiaryContainer: Color(0xFF3D1E00),
    // Error
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    // Surface - warm beige journal paper
    surface: Color(0xFFFFF8F6),
    onSurface: Color(0xFF2C1E1A),
    surfaceContainerHighest: Color(0xFFEFDFD9),
    surfaceContainerHigh: Color(0xFFE7D7D1),
    surfaceContainer: Color(0xFFECE0DA),
    surfaceContainerLow: Color(0xFFF5E9E4),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF6B5D58),
    // Outline
    outline: Color(0xFFDAC1B8),
    outlineVariant: Color(0xFFE8D5CF),
    // Shadow
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E2220),
    onInverseSurface: Color(0xFFFEEDE8),
    inversePrimary: Color(0xFFFFB596),
  );

  // Dark mode
  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB596),
    onPrimary: Color(0xFF360F00),
    primaryContainer: Color(0xFF662B0E),
    onPrimaryContainer: Color(0xFFFFDBC0),
    secondary: Color(0xFFACD0D0),
    onSecondary: Color(0xFF001F1F),
    secondaryContainer: Color(0xFF2C4A4A),
    onSecondaryContainer: Color(0xFFC6E9E9),
    tertiary: Color(0xFFFFB596),
    onTertiary: Color(0xFF3D1E00),
    tertiaryContainer: Color(0xFF662B0E),
    onTertiaryContainer: Color(0xFFFFDBC0),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1E1512),
    onSurface: Color(0xFFFEEDE8),
    surfaceContainerHighest: Color(0xFF3A2E2B),
    surfaceContainerHigh: Color(0xFF302624),
    surfaceContainer: Color(0xFF2B2220),
    surfaceContainerLow: Color(0xFF261E1C),
    surfaceContainerLowest: Color(0xFF1A1210),
    onSurfaceVariant: Color(0xFFD6C3BE),
    outline: Color(0xFF8C7A76),
    outlineVariant: Color(0xFF4A3E3A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFEEDE8),
    onInverseSurface: Color(0xFF2E2220),
    inversePrimary: Color(0xFF823B18),
  );

  static ColorScheme get light => _lightScheme;
  static ColorScheme get dark => _darkScheme;
}

/// Spacing scale — 4px base unit, following iOS/Material conventions.
abstract class DSSpacing {
  static const double xs = 4;    // 1×
  static const double sm = 8;    // 2×
  static const double md = 12;   // 3×
  static const double lg = 16;   // 4×
  static const double xl = 24;   // 6×
  static const double xxl = 32;  // 8×
  static const double xxxl = 48; // 12×
}

/// Border radius scale — subtle rounding for journal feel.
abstract class DSRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

/// Elevation/shadow tokens — layered paper metaphor.
abstract class DSElevation {
  static const List<BoxShadow> level0 = [];
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> level4 = [
    BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // "Leather" shadow — warmer, directional (like a pressed button)
  static const List<BoxShadow> leather = [
    BoxShadow(color: Color(0xFF5A2D1A), offset: Offset(0, 4), blurRadius: 0),
  ];
}

/// Typography scale — SF Pro / system font with journal-appropriate weights.
abstract class DSTypography {
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57, fontWeight: FontWeight.w700, height: 1.12, letterSpacing: -0.25,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45, fontWeight: FontWeight.w700, height: 1.16, letterSpacing: 0,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36, fontWeight: FontWeight.w600, height: 1.22, letterSpacing: 0,
  );

  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: 0,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w600, height: 1.29, letterSpacing: 0,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, letterSpacing: 0,
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, height: 1.27, letterSpacing: 0,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, letterSpacing: 0.15,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, letterSpacing: 0.1,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: 0.25,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0.4,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, height: 1.33, letterSpacing: 0.5,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, height: 1.45, letterSpacing: 0.5,
  );

  // Journal/serif for agreements, quotes
  static const TextStyle journalBody = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, height: 1.6, letterSpacing: 0.2,
    fontFamily: 'serif',
  );
  static const TextStyle journalSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.3,
    fontFamily: 'serif',
  );
}

/// Animation durations — iOS-like feel.
abstract class DSAnimation {
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);

  // Curves
  static const Curve standard = Curves.easeInOutCubic;    // Material standard
  static const Curve decelerate = Curves.easeOutCubic;    // iOS default
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
}

/// Icon sizes
abstract class DSIconSize {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 28;
  static const double xl = 32;
  static const double xxl = 48;
}

// ═══════════════════════════════════════════════════════════════════════
// THEME DATA
// ═══════════════════════════════════════════════════════════════════════

/// Complete light/dark theme with design tokens applied.
class DSTheme {
  static ThemeData get light => _theme(DSColors.light);
  static ThemeData get dark => _theme(DSColors.dark);

  static ThemeData _theme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,

      // Scaffold
      scaffoldBackgroundColor: scheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: DSTypography.titleLarge.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: DSIconSize.md),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: DSIconSize.md),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shadowColor: scheme.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.lg)),
        margin: EdgeInsets.zero,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.lg, vertical: DSSpacing.md,
        ),
        hintStyle: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
        labelStyle: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5), width: 1),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl, vertical: DSSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          textStyle: DSTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl, vertical: DSSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          textStyle: DSTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl, vertical: DSSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          textStyle: DSTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
          textStyle: DSTypography.labelLarge,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.xs),
        labelStyle: DSTypography.labelMedium.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: DSTypography.labelMedium.copyWith(color: scheme.onPrimaryContainer),
        brightness: scheme.brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.full)),
        side: BorderSide(color: scheme.outlineVariant),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.xl)),
        elevation: 0,
        shadowColor: scheme.shadow,
        titleTextStyle: DSTypography.titleLarge.copyWith(color: scheme.onSurface),
        contentTextStyle: DSTypography.bodyMedium.copyWith(color: scheme.onSurface),
      ),

      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
        ),
        elevation: 0,
        shadowColor: scheme.shadow,
        modalBackgroundColor: scheme.surface,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DSTypography.labelSmall.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600);
          }
          return DSTypography.labelSmall.copyWith(color: scheme.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: DSIconSize.md);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: DSIconSize.md);
        }),
        height: 80,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: DSTypography.labelLarge,
        unselectedLabelStyle: DSTypography.labelLarge,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withValues(alpha: 0.1);
          return Colors.transparent;
        }),
      ),

      // List tiles
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.xs),
        titleTextStyle: DSTypography.bodyLarge.copyWith(color: scheme.onSurface),
        subtitleTextStyle: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
        tileColor: Colors.transparent,
        selectedTileColor: scheme.primaryContainer,
        iconColor: scheme.onSurfaceVariant,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: DSTypography.bodyMedium.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.full)),
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: scheme.primary, width: 2);
          }
          return BorderSide(color: scheme.outline, width: 1.5);
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.xs)),
        visualDensity: VisualDensity.compact,
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurfaceVariant;
        }),
        visualDensity: VisualDensity.compact,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primaryContainer;
          return scheme.surfaceContainerHighest;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: DSTypography.labelSmall.copyWith(color: scheme.onPrimary),
        trackHeight: 4,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ═══════════════════════════════════════════════════════════════════════

/// Primary action button — leather brown, directional shadow.
class DSPrimaryButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const DSPrimaryButton({
    super.key,
    required this.label,
    this.subtitle,
    this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(DSRadius.md),
          boxShadow: onPressed != null && !loading ? DSElevation.leather : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DSRadius.md),
            onTap: loading || onPressed == null ? null : onPressed,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: DSSpacing.sm)],
                            Text(label, style: DSTypography.labelLarge.copyWith(color: scheme.onPrimary)),
                            if (trailingIcon != null) ...[const SizedBox(width: DSSpacing.sm), trailingIcon!],
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: DSTypography.labelSmall.copyWith(color: scheme.onPrimary.withValues(alpha: 0.7))),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button — outlined.
class DSSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? leadingIcon;
  final double? width;
  final Color? color;

  const DSSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurface;

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
          textStyle: DSTypography.labelLarge,
        ),
        onPressed: loading || onPressed == null ? null : onPressed,
        child: loading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: c),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: DSSpacing.sm)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Tertiary action button — text with icon.
class DSTertiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final Color? color;

  const DSTertiaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: c,
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
        textStyle: DSTypography.labelLarge,
      ),
      icon: leadingIcon ?? const SizedBox.shrink(),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// Text field with consistent styling.
class DSTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  const DSTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      style: DSTypography.bodyLarge.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: DSIconSize.md) : null,
        suffixIcon: suffixIcon,
        counterText: '',
        errorText: errorText,
        helperText: helperText,
      ),
    );
  }
}

/// Card with consistent elevation and styling.
class DSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;

  const DSCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.shadows,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Container(
      padding: padding ?? const EdgeInsets.all(DSSpacing.lg),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(DSRadius.lg),
        boxShadow: shadows ?? DSElevation.level1,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius ?? BorderRadius.circular(DSRadius.lg),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Section header with title and optional action.
class DSSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showDivider;

  const DSSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: DSSpacing.md),
            Divider(color: scheme.outlineVariant, height: 1),
          ],
        ],
      ),
    );
  }
}

/// Empty state illustration.
class DSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: DSIconSize.xxl, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: DSSpacing.lg),
            Text(title, style: DSTypography.titleLarge.copyWith(color: scheme.onSurface), textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: DSSpacing.sm),
              Text(message!, style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: DSSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay.
class DSLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const DSLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: scheme.surface.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: scheme.primary, strokeWidth: 3),
                    if (message != null) ...[
                      const SizedBox(height: DSSpacing.lg),
                      Text(message!, style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Consistent page scaffold with safe area and background.
class DSPage extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const DSPage({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? scheme.surface,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: child,
      ),
    );
  }
}

/// Auth screen scaffold — centered, with logo area.
class DSAuthScaffold extends StatelessWidget {
  final Widget logo;
  final String title;
  final String? subtitle;
  final Widget form;
  final Widget? footer;
  final EdgeInsetsGeometry? horizontalPadding;

  const DSAuthScaffold({
    super.key,
    required this.logo,
    required this.title,
    this.subtitle,
    required this.form,
    this.footer,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 32),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: DSSpacing.xl),
                      logo,
                      const SizedBox(height: DSSpacing.lg),
                      Padding(
                        padding: horizontalPadding!,
                        child: Column(
                          children: [
                            Text(title,
                                style: DSTypography.headlineMedium.copyWith(
                                  color: scheme.onSurface, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center),
                            if (subtitle != null) ...[
                              const SizedBox(height: DSSpacing.sm),
                              Text(subtitle!,
                                  style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                                  textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: DSSpacing.xxl),
                      Expanded(child: form),
                      if (footer != null) ...[
                        const SizedBox(height: DSSpacing.xl),
                        Padding(padding: horizontalPadding!, child: footer!),
                      ],
                      const SizedBox(height: DSSpacing.xxl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════

extension DSColorSchemeExt on ColorScheme {
  /// Surface with subtle warmth for cards
  Color get surfaceWarm => brightness == Brightness.light
      ? const Color(0xFFFFF8F6)
      : const Color(0xFF1E1512);

  /// Primary with 10% opacity for hover/pressed states
  Color get primarySubtle => primary.withValues(alpha: 0.1);

  /// On-surface with 60% opacity for secondary text
  Color get onSurfaceSubtle => onSurface.withValues(alpha: 0.6);

  /// On-surface with 38% opacity for disabled text
  Color get onSurfaceDisabled => onSurface.withValues(alpha: 0.38);
}

extension DSContextExt on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to design tokens
  double get xs => DSSpacing.xs;
  double get sm => DSSpacing.sm;
  double get md => DSSpacing.md;
  double get lg => DSSpacing.lg;
  double get xl => DSSpacing.xl;
  double get xxl => DSSpacing.xxl;
}

extension DSTextStyleExt on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}