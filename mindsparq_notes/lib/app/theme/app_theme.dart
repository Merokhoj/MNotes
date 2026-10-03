import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// MindSparQ Notes Neo-Glass Design System Theme
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final textTheme = _buildTextTheme(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: colors.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: Colors.white,
        primaryContainer: colors.primary.withOpacity(0.15),
        onPrimaryContainer: colors.primary,
        secondary: AppColors.accentSecondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentSecondary.withOpacity(0.15),
        onSecondaryContainer: AppColors.accentSecondary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surface2,
        onSurfaceVariant: colors.textSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: colors.border,
        outlineVariant: colors.border.withOpacity(0.5),
        shadow: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
        surfaceContainerLowest: colors.background,
      ),
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colors.textSecondary, size: 18),
      dividerColor: colors.border,
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),

      // Cards
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.border),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),

      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.border),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(2),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? colors.surface2 : Colors.grey[900],
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final color = isDark ? AppColors.dark.textPrimary : AppColors.light.textPrimary;
    final secondaryColor = isDark ? AppColors.dark.textSecondary : AppColors.light.textSecondary;

    TextStyle base(double size, FontWeight weight, [Color? c, double height = 1.55]) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: c ?? color,
          height: height,
        );

    return TextTheme(
      // Display / Title
      displayLarge: base(38, FontWeight.w800, null, 1.2),
      displayMedium: base(32, FontWeight.w700, null, 1.25),
      displaySmall: base(26, FontWeight.w700, null, 1.3),
      // Headlines
      headlineLarge: base(24, FontWeight.w700, null, 1.3),
      headlineMedium: base(20, FontWeight.w600, null, 1.35),
      headlineSmall: base(18, FontWeight.w600, null, 1.4),
      // Titles
      titleLarge: base(16, FontWeight.w600, null, 1.4),
      titleMedium: base(14.5, FontWeight.w600, null, 1.4),
      titleSmall: base(13, FontWeight.w500, null, 1.45),
      // Body
      bodyLarge: base(16.5, FontWeight.w400, null, 1.65), // Readable body column
      bodyMedium: base(14.5, FontWeight.w400, null, 1.6),
      bodySmall: base(12.5, FontWeight.w400, secondaryColor, 1.5),
      // Labels
      labelLarge: base(13.5, FontWeight.w600, null, 1.3),
      labelMedium: base(12, FontWeight.w500, null, 1.3),
      labelSmall: base(11, FontWeight.w400, secondaryColor, 1.3),
    );
  }
}

/// Responsive Spacing & Sizing Constants
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Border radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 999.0;

  // Desktop layout sizing standards
  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsedWidth = 64.0;
  static const double notesListWidth = 310.0;
  static const double editorContentMaxWidth = 860.0; // Optimal 720-900px writing line length
  static const double researchPanelWidth = 340.0;
}
