import 'package:flutter/material.dart';

/// Available selectable themes in Reel Saver.
enum AppThemeMode {
  midnight('Midnight', 'Deep navy with electric violet'),
  classicLight('Classic Light', 'Clean white with royal sapphire'),
  sunset('Sunset', 'Warm charcoal with sunset coral');

  final String displayName;
  final String description;

  const AppThemeMode(this.displayName, this.description);

  /// Resolves an [AppThemeMode] from a storage key string.
  static AppThemeMode fromString(String? key) {
    switch (key) {
      case 'classicLight':
        return AppThemeMode.classicLight;
      case 'sunset':
        return AppThemeMode.sunset;
      case 'midnight':
      default:
        return AppThemeMode.midnight;
    }
  }
}

/// Comprehensive theme definitions for Reel Saver.
class AppThemes {
  const AppThemes._();

  /// 1. Midnight Theme: Dark deep navy/black with electric violet accents.
  static ThemeData get midnightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // Electric violet
      brightness: Brightness.dark,
      primary: const Color(0xFF6366F1),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF312E81),
      onPrimaryContainer: const Color(0xFFE0E7FF),
      secondary: const Color(0xFF38BDF8), // Electric cyan
      onSecondary: const Color(0xFF0F172A),
      surface: const Color(0xFF0F172A), // Deep navy
      onSurface: const Color(0xFFF8FAFC),
      surfaceContainerHighest: const Color(0xFF1E293B),
      outline: const Color(0xFF334155),
      outlineVariant: const Color(0xFF1E293B),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      cardColor: const Color(0xFF131C2E),
    );
  }

  /// 2. Classic Light Theme: Clean white/soft grey with royal sapphire blue accents.
  static ThemeData get classicLightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB), // Royal sapphire
      brightness: Brightness.light,
      primary: const Color(0xFF2563EB),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBEAFE),
      onPrimaryContainer: const Color(0xFF1E3A8A),
      secondary: const Color(0xFF0D9488), // Teal accent
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
    );
  }

  /// 3. Sunset Theme: Warm dark tones (deep plum charcoal) with sunset coral-orange accents.
  static ThemeData get sunsetTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF97316), // Sunset coral-orange
      brightness: Brightness.dark,
      primary: const Color(0xFFF97316),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF7C2D12),
      onPrimaryContainer: const Color(0xFFFFEDD5),
      secondary: const Color(0xFFFB7185), // Sunset rose-pink
      onSecondary: Colors.white,
      surface: const Color(0xFF1F151C), // Dark plum charcoal
      onSurface: const Color(0xFFFFF1F2),
      surfaceContainerHighest: const Color(0xFF2E1C29),
      outline: const Color(0xFF4A2F42),
      outlineVariant: const Color(0xFF382132),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF160E14),
      cardColor: const Color(0xFF261923),
    );
  }

  /// Resolves the full [ThemeData] for a given [AppThemeMode].
  static ThemeData getThemeData(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.classicLight:
        return classicLightTheme;
      case AppThemeMode.sunset:
        return sunsetTheme;
      case AppThemeMode.midnight:
        return midnightTheme;
    }
  }

  /// Builds a cohesive [ThemeData] using our design system tokens.
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.primary),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
