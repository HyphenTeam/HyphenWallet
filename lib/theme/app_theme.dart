import 'package:flutter/material.dart';

class ThemePreset {
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color secondaryAccent;
  final Color surfaceTint;
  final Color surfaceVariantTint;
  final Color borderTint;

  const ThemePreset({
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.secondaryAccent,
    required this.surfaceTint,
    required this.surfaceVariantTint,
    required this.borderTint,
  });
}

const kThemePresets = <ThemePreset>[
  ThemePreset(
    name: 'Wise Green',
    primary: Color(0xFF163300),
    primaryLight: Color(0xFF2D5A0A),
    primaryDark: Color(0xFF0E2200),
    accent: Color(0xFF9FE870),
    secondaryAccent: Color(0xFF4A8F8E),
    surfaceTint: Color(0xFFF3F5ED),
    surfaceVariantTint: Color(0xFFE8EBE0),
    borderTint: Color(0xFFDADCD5),
  ),
  ThemePreset(
    name: 'Ocean Blue',
    primary: Color(0xFF0A2463),
    primaryLight: Color(0xFF1E3A7A),
    primaryDark: Color(0xFF061845),
    accent: Color(0xFF62B6CB),
    secondaryAccent: Color(0xFF3A86FF),
    surfaceTint: Color(0xFFEDF2FA),
    surfaceVariantTint: Color(0xFFDDE4F0),
    borderTint: Color(0xFFCED6E5),
  ),
  ThemePreset(
    name: 'Royal Purple',
    primary: Color(0xFF2D1B69),
    primaryLight: Color(0xFF4A328A),
    primaryDark: Color(0xFF1E1050),
    accent: Color(0xFFB39DDB),
    secondaryAccent: Color(0xFF7C4DFF),
    surfaceTint: Color(0xFFF3F0FA),
    surfaceVariantTint: Color(0xFFE6E0F0),
    borderTint: Color(0xFFD5CEE5),
  ),
  ThemePreset(
    name: 'Sunset Orange',
    primary: Color(0xFF4A1A00),
    primaryLight: Color(0xFF6D3A1A),
    primaryDark: Color(0xFF331200),
    accent: Color(0xFFFFB74D),
    secondaryAccent: Color(0xFFFF7043),
    surfaceTint: Color(0xFFFAF3ED),
    surfaceVariantTint: Color(0xFFF0E6D8),
    borderTint: Color(0xFFE5D9CC),
  ),
  ThemePreset(
    name: 'Rose Pink',
    primary: Color(0xFF4A0025),
    primaryLight: Color(0xFF6D1A42),
    primaryDark: Color(0xFF33001A),
    accent: Color(0xFFF48FB1),
    secondaryAccent: Color(0xFFE91E63),
    surfaceTint: Color(0xFFFAEDF2),
    surfaceVariantTint: Color(0xFFF0E0E8),
    borderTint: Color(0xFFE5D1DA),
  ),
  ThemePreset(
    name: 'Slate Gray',
    primary: Color(0xFF1E272E),
    primaryLight: Color(0xFF37474F),
    primaryDark: Color(0xFF111920),
    accent: Color(0xFF90A4AE),
    secondaryAccent: Color(0xFF546E7A),
    surfaceTint: Color(0xFFF0F2F4),
    surfaceVariantTint: Color(0xFFE0E3E8),
    borderTint: Color(0xFFD0D4D9),
  ),
];

abstract final class HyphenColors {
  static const Color brightGreen = Color(0xFF9FE870);
  static const Color forestGreen = Color(0xFF163300);
  static const Color primary = Color(0xFF163300);
  static const Color primaryLight = Color(0xFF2D5A0A);
  static const Color primaryDark = Color(0xFF0E2200);
  static const Color accent = Color(0xFF9FE870);
  static const Color accentCool = Color(0xFF4A8F8E);
  static const Color accentWarm = Color(0xFF836939);
  static const Color success = Color(0xFF2E7D32);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundTint = Color(0xFFF3F5ED);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF3F5ED);
  static const Color surfaceVariant = Color(0xFFE8EBE0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFE6A817);
  static const Color border = Color(0xFFDADCD5);
  static const Color textPrimary = Color(0xFF0E0F0C);
  static const Color textSecondary = Color(0xFF454745);
  static const Color textHint = Color(0xFF6A6C6A);
  static const Color divider = Color(0xFFE0E2DB);
  static const Color interactiveSecondary = Color(0xFF868685);
}

ThemeData buildHyphenTheme({int presetIndex = 0}) {
  final preset = kThemePresets[presetIndex.clamp(0, kThemePresets.length - 1)];

  final seedScheme = ColorScheme.light(
    primary: preset.primary,
    onPrimary: Colors.white,
    primaryContainer: preset.accent,
    onPrimaryContainer: preset.primary,
    secondary: preset.secondaryAccent,
    onSecondary: Colors.white,
    secondaryContainer: preset.accent.withAlpha(60),
    onSecondaryContainer: preset.primaryDark,
    tertiary: HyphenColors.accentWarm,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFF5E0C0),
    onTertiaryContainer: const Color(0xFF2C1B00),
    error: HyphenColors.error,
    onError: Colors.white,
    surface: HyphenColors.background,
    onSurface: HyphenColors.textPrimary,
    surfaceContainerHighest: preset.surfaceVariantTint,
    outline: preset.borderTint,
    outlineVariant: HyphenColors.divider,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: seedScheme,
    scaffoldBackgroundColor: HyphenColors.background,
    fontFamily: 'Inter',
    cardTheme: CardThemeData(
      color: HyphenColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: HyphenColors.border.withAlpha(80)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HyphenColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: HyphenColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: HyphenColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HyphenColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: HyphenColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: HyphenColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: preset.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HyphenColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: HyphenColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: preset.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: preset.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: preset.primary,
        side: BorderSide(color: preset.primary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: preset.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return preset.primary;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return HyphenColors.textSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: HyphenColors.border),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: HyphenColors.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: preset.accent.withAlpha(60),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: preset.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: HyphenColors.textHint,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: preset.primary, size: 24);
        }
        return const IconThemeData(color: HyphenColors.textHint, size: 24);
      }),
      elevation: 0,
      height: 64,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: HyphenColors.surfaceLight,
      selectedColor: preset.accent.withAlpha(50),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: HyphenColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: HyphenColors.border.withAlpha(120)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: preset.primary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: HyphenColors.divider,
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HyphenColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: HyphenColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

/// Builds a dark theme using the same preset system.
ThemeData buildHyphenDarkTheme({
  int presetIndex = 0,
  ColorScheme? dynamicDark,
}) {
  final preset = kThemePresets[presetIndex.clamp(0, kThemePresets.length - 1)];

  final darkScheme =
      dynamicDark ??
      ColorScheme.dark(
        primary: preset.accent,
        onPrimary: preset.primaryDark,
        primaryContainer: preset.primary,
        onPrimaryContainer: preset.accent,
        secondary: preset.secondaryAccent,
        onSecondary: Colors.white,
        secondaryContainer: preset.secondaryAccent.withAlpha(50),
        onSecondaryContainer: Colors.white,
        tertiary: HyphenColors.accentWarm,
        onTertiary: Colors.white,
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFE4E4E4),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
        outline: const Color(0xFF4A4A4A),
        outlineVariant: const Color(0xFF333333),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: darkScheme,
    scaffoldBackgroundColor: darkScheme.surface,
    fontFamily: 'Inter',
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkScheme.outline.withAlpha(60)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: darkScheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkScheme.error, width: 1.5),
      ),
      hintStyle: TextStyle(color: darkScheme.onSurface.withAlpha(120)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkScheme.primary,
        foregroundColor: darkScheme.onPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkScheme.primary,
        foregroundColor: darkScheme.onPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkScheme.primary,
        side: BorderSide(color: darkScheme.primary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkScheme.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkScheme.primary;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkScheme.onPrimary;
          }
          return darkScheme.onSurface.withAlpha(180);
        }),
        side: WidgetStateProperty.all(BorderSide(color: darkScheme.outline)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: darkScheme.primary.withAlpha(50),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkScheme.primary,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkScheme.onSurface.withAlpha(140),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: darkScheme.primary, size: 24);
        }
        return IconThemeData(
          color: darkScheme.onSurface.withAlpha(140),
          size: 24,
        );
      }),
      elevation: 0,
      height: 64,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedColor: darkScheme.primary.withAlpha(40),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: darkScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: darkScheme.outline.withAlpha(100)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkScheme.primary,
      contentTextStyle: TextStyle(color: darkScheme.onPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(
      color: darkScheme.outlineVariant,
      thickness: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: darkScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

/// Builds a light theme that integrates a dynamic [ColorScheme] when available.
ThemeData buildHyphenThemeWithDynamic({
  int presetIndex = 0,
  ColorScheme? dynamicLight,
}) {
  if (dynamicLight != null) {
    // Use the existing builder but override the color scheme with the
    // platform dynamic one, keeping all component-level Material 3 styling.
    final base = buildHyphenTheme(presetIndex: presetIndex);
    return base.copyWith(colorScheme: dynamicLight);
  }
  return buildHyphenTheme(presetIndex: presetIndex);
}
