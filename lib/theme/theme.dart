import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for the Campus Events Management Application.
///
/// All colors, typography and shape tokens live here so the UI stays
/// consistent and easy to re-theme. The palette follows the project spec.
class AppColors {
  AppColors._();

  /// Global brightness flag (flipped by the Settings dark-mode toggle).
  /// The surface/text tokens below resolve against this so the whole app
  /// re-themes without rewriting every screen.
  static bool dark = false;

  /// Primary — main containers and major headers. (Brand, fixed.)
  static const Color primary = Color(0xFF4D7FB0);

  /// Secondary accent — app bars, text frames, main panels. (Brand, fixed.)
  static const Color secondary = Color(0xFF75A6D7);

  /// Always-white foreground for text/icons sitting on a colored surface
  /// (app bars, primary buttons) — must NOT flip in dark mode.
  static const Color onAccent = Color(0xFFFFFFFF);

  static const Color danger = Color(0xFFE2645F);
  static const Color success = Color(0xFF4CAF82);

  /// Surface tint — secondary card blocks and inactive icons.
  static Color get surfaceTint =>
      dark ? const Color(0xFF2A3C4F) : const Color(0xFFC0D9F2);

  /// Neutral base — screen backgrounds & input surfaces.
  static Color get neutralLight =>
      dark ? const Color(0xFF15212E) : const Color(0xFFFFFFFF);

  // Supporting text tones (subtle, on-brand) that adapt to brightness.
  static Color get textDark =>
      dark ? const Color(0xFFE8EEF5) : const Color(0xFF1F3247);
  static Color get textMuted =>
      dark ? const Color(0xFF9DB0C2) : const Color(0xFF6B7C90);
}

/// Shared shape tokens — everything is heavily rounded for the soft "bubble" look.
class AppRadii {
  AppRadii._();
  static const double card = 24;
  static const double field = 20;
  static const double pill = 32;
  static const double sheet = 36;
}

class AppTheme {
  AppTheme._();

  /// Light theme (kept for backward references).
  static ThemeData get light => theme;

  /// Active theme — resolves light or dark based on [AppColors.dark].
  static ThemeData get theme {
    final isDark = AppColors.dark;
    final base = ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light);

    // Soft, clean, minimalist typography via Google Fonts (Montserrat).
    final textTheme = GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.neutralLight,
      surfaceTint: AppColors.surfaceTint,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.neutralLight,
      textTheme: textTheme,
      primaryColor: AppColors.primary,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.onAccent,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      // Default white, thick-bordered, highly-rounded input surfaces.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.surfaceTint, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.danger, width: 2.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.neutralLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onAccent,
      ),

      iconTheme: const IconThemeData(color: AppColors.primary),
      dividerColor: AppColors.surfaceTint,
    );
  }
}
