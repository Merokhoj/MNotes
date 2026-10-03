import 'package:flutter/material.dart';

/// MindSparQ Notes Neo-Glass & Frosted Prism Color System
/// Designed for macOS, Windows, iOS, and Android
class AppColors {
  AppColors._();

  // ── Brand Primary / Accent ──────────────────────────────────
  static const Color primaryLight = Color(0xFF6857F5);
  static const Color primaryDark = Color(0xFFA398FF);

  static const Color accent = Color(0xFF6857F5);
  static const Color accentSecondary = Color(0xFFA398FF);
  static const Color accentPillLight = Color(0xFFD9D3FF);
  static const Color accentPillDark = Color(0xFF393451);

  // ── Semantic Feedback ───────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Theme Palettes (Neo-Glass + Frosted Prism) ───────────────
  static const AppColorScheme light = AppColorScheme(
    background: Color(0xFFF5F6FA),         // Canvas
    surface: Color(0xFFFFFFFF),            // Solid Surface
    surface2: Color(0xFFF0F1F7),           // Surface 2
    surface3: Color(0xFFE6E8F2),           // Surface 3
    glass: Color(0xD9FFFFFF),              // Neo-Glass (85% white)
    glassHeavy: Color(0xF2FFFFFF),         // Heavy Glass (95% white for writing)
    glassBorder: Color(0xFFE4E5EF),        // Subtle 1px neutral tint
    glassBorderHighlight: Color(0x66FFFFFF),
    border: Color(0xFFE4E5EF),
    borderStrong: Color(0xFFD0D2E2),
    textPrimary: Color(0xFF1C1C28),        // Text
    textSecondary: Color(0xFF77788A),      // Muted
    textTertiary: Color(0xFFA0A1B2),
    noteCardSelected: Color(0xFFF0EEFF),
    sidebarBackground: Color(0xFFF8F9FD),
    primary: primaryLight,
    accentPill: accentPillLight,
    prismTint: Color(0x146857F5),
  );

  static const AppColorScheme dark = AppColorScheme(
    background: Color(0xFF101117),         // Dark Canvas
    surface: Color(0xFF191B25),            // Dark Surface
    surface2: Color(0xFF222533),           // Dark Surface 2
    surface3: Color(0xFF2C3042),           // Dark Surface 3
    glass: Color(0xC9272936),              // Neo-Glass Dark (78% slate/indigo)
    glassHeavy: Color(0xE6191B25),         // Heavy Dark Glass (90%)
    glassBorder: Color(0x1FFFFFFF),        // 12% white subtle border
    glassBorderHighlight: Color(0x33A398FF),
    border: Color(0x1FFFFFFF),
    borderStrong: Color(0x33FFFFFF),
    textPrimary: Color(0xFFF3F2FA),        // Text
    textSecondary: Color(0xFFA4A5B6),      // Muted
    textTertiary: Color(0xFF6E7082),
    noteCardSelected: Color(0xFF2B2942),
    sidebarBackground: Color(0xFF14151E),
    primary: primaryDark,
    accentPill: accentPillDark,
    prismTint: Color(0x28A398FF),
  );
}

/// Color tokens for a specific brightness
class AppColorScheme {
  final Color background;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color glass;
  final Color glassHeavy;
  final Color glassBorder;
  final Color glassBorderHighlight;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color noteCardSelected;
  final Color sidebarBackground;
  final Color primary;
  final Color accentPill;
  final Color prismTint;

  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.glass,
    required this.glassHeavy,
    required this.glassBorder,
    required this.glassBorderHighlight,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.noteCardSelected,
    required this.sidebarBackground,
    required this.primary,
    required this.accentPill,
    required this.prismTint,
  });

  /// Prism refraction linear gradient for hover, selection, and highlights
  LinearGradient get prismGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withOpacity(0.14),
          const Color(0xFF38BDF8).withOpacity(0.08),
          const Color(0xFFA78BFA).withOpacity(0.12),
          glass,
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      );

  /// Subtle prism border gradient for active states
  LinearGradient get prismBorderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withOpacity(0.5),
          const Color(0xFF38BDF8).withOpacity(0.35),
          const Color(0xFFA78BFA).withOpacity(0.4),
        ],
      );
}

/// Extension to easily access theme colors from context
extension AppColorsExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppColorScheme get appColors => isDark ? AppColors.dark : AppColors.light;
  Color get backgroundColor => appColors.background;
  Color get surfaceColor => appColors.surface;
  Color get surface2Color => appColors.surface2;
  Color get glassColor => appColors.glass;
  Color get borderColor => appColors.border;
  Color get textPrimaryColor => appColors.textPrimary;
  Color get textSecondaryColor => appColors.textSecondary;
  Color get textTertiaryColor => appColors.textTertiary;
  Color get sidebarColor => appColors.sidebarBackground;
  Color get accentColor => appColors.primary;
}
