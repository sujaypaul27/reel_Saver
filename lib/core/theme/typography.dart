import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Typography Design System for Reel Saver.
///
/// Provides consistent multi-script font coverage across all 5 supported
/// languages (English, Hindi, Tamil, Spanish, French).
///
/// Features:
/// - Base Latin font family: 'Noto Sans' (covers English, Spanish, French).
/// - Dedicated Indian script fonts: 'Noto Sans Devanagari' (Hindi) & 'Noto Sans Tamil' (Tamil).
/// - Fallback font family chains to ensure zero missing glyphs or clipping.
/// - Clear 5-level type scale:
///     1. displayLarge: Titles & main app headers
///     2. headlineMedium: Section headers & dialog titles
///     3. bodyLarge: Main content, descriptions, and primary button labels
///     4. bodyMedium: Secondary text, subtitles, and list metadata
///     5. labelSmall: Captions, timestamps, duration, and file sizes
class AppTypography {
  const AppTypography._();

  /// Primary font family name for Latin scripts.
  static String get notoSansFamily =>
      GoogleFonts.notoSans().fontFamily ?? 'Noto Sans';

  /// Script font family name for Devanagari (Hindi).
  static String get devanagariFamily =>
      GoogleFonts.notoSansDevanagari().fontFamily ?? 'Noto Sans Devanagari';

  /// Script font family name for Tamil.
  static String get tamilFamily =>
      GoogleFonts.notoSansTamil().fontFamily ?? 'Noto Sans Tamil';

  /// Generates the cross-script fallback fonts chain for a given locale.
  static List<String> getFontFallbacks(Locale? locale) {
    final languageCode = locale?.languageCode.toLowerCase();
    switch (languageCode) {
      case 'hi':
        return [
          notoSansFamily,
          tamilFamily,
          'Roboto',
          'sans-serif',
        ];
      case 'ta':
        return [
          notoSansFamily,
          devanagariFamily,
          'Roboto',
          'sans-serif',
        ];
      case 'en':
      case 'es':
      case 'fr':
      default:
        return [
          devanagariFamily,
          tamilFamily,
          'Roboto',
          'sans-serif',
        ];
    }
  }

  /// Builds a [TextStyle] tailored for the target locale script and role.
  static TextStyle createTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
    Locale? locale,
    Color? color,
  }) {
    final fallbacks = getFontFallbacks(locale);
    final languageCode = locale?.languageCode.toLowerCase();

    // Select primary font based on locale
    final TextStyle baseStyle;
    switch (languageCode) {
      case 'hi':
        baseStyle = GoogleFonts.notoSansDevanagari(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
        );
        break;
      case 'ta':
        baseStyle = GoogleFonts.notoSansTamil(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
        );
        break;
      case 'en':
      case 'es':
      case 'fr':
      default:
        baseStyle = GoogleFonts.notoSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
        );
        break;
    }

    return baseStyle.copyWith(
      fontFamilyFallback: fallbacks,
    );
  }

  /// Builds the complete [TextTheme] for the application.
  ///
  /// Adheres strictly to the 5-level type scale with safe glyph heights
  /// to eliminate vertical clipping of Hindi and Tamil matras/conjuncts.
  static TextTheme buildTextTheme({
    Locale? locale,
    Color? displayColor,
    Color? bodyColor,
  }) {
    // 1. displayLarge: Titles & main app headers (24px, bold)
    final displayLarge = createTextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.2,
      locale: locale,
      color: displayColor,
    );

    // 2. headlineMedium: Section headers & modal/dialog headers (18px, semi-bold)
    final headlineMedium = createTextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: -0.1,
      locale: locale,
      color: displayColor,
    );

    // 3. bodyLarge: Main content, descriptions, and primary button labels (15px, medium)
    final bodyLarge = createTextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
      locale: locale,
      color: bodyColor,
    );

    // 4. bodyMedium: Secondary text, subtitles, and list item details (13.5px, regular)
    final bodyMedium = createTextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.4,
      locale: locale,
      color: bodyColor,
    );

    // 5. labelSmall: Captions, timestamps, duration, file size, badges (11.5px, medium)
    final labelSmall = createTextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0.2,
      locale: locale,
      color: bodyColor,
    );

    // Supporting Material 3 styles aligned to the design tokens
    final titleLarge = createTextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.2,
      locale: locale,
      color: displayColor,
    );

    final titleMedium = createTextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      locale: locale,
      color: displayColor,
    );

    final titleSmall = createTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
      locale: locale,
      color: displayColor,
    );

    final labelLarge = createTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.1,
      locale: locale,
      color: bodyColor,
    );

    final labelMedium = createTextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      height: 1.35,
      locale: locale,
      color: bodyColor,
    );

    final bodySmall = createTextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      locale: locale,
      color: bodyColor,
    );

    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayLarge.copyWith(fontSize: 22),
      displaySmall: displayLarge.copyWith(fontSize: 20),
      headlineLarge: displayLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineMedium.copyWith(fontSize: 16),
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
