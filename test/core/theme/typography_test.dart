import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/core/theme/app_theme.dart';
import 'package:reel_saver/core/theme/typography.dart';
import 'package:reel_saver/l10n/app_localizations.dart';

void main() {
  group('AppTypography System Tests', () {
    testWidgets('defines required font families', (tester) async {
      expect(AppTypography.notoSansFamily, isNotEmpty);
      expect(AppTypography.devanagariFamily, isNotEmpty);
      expect(AppTypography.tamilFamily, isNotEmpty);
    });

    testWidgets('configures fallback font families covering all supported scripts', (tester) async {
      // English / Latin
      final enFallbacks = AppTypography.getFontFallbacks(const Locale('en'));
      expect(enFallbacks, contains(AppTypography.devanagariFamily));
      expect(enFallbacks, contains(AppTypography.tamilFamily));

      // Hindi / Devanagari
      final hiFallbacks = AppTypography.getFontFallbacks(const Locale('hi'));
      expect(hiFallbacks, contains(AppTypography.notoSansFamily));
      expect(hiFallbacks, contains(AppTypography.tamilFamily));

      // Tamil
      final taFallbacks = AppTypography.getFontFallbacks(const Locale('ta'));
      expect(taFallbacks, contains(AppTypography.notoSansFamily));
      expect(taFallbacks, contains(AppTypography.devanagariFamily));

      // Spanish & French
      final esFallbacks = AppTypography.getFontFallbacks(const Locale('es'));
      expect(esFallbacks, contains(AppTypography.devanagariFamily));
      expect(esFallbacks, contains(AppTypography.tamilFamily));

      final frFallbacks = AppTypography.getFontFallbacks(const Locale('fr'));
      expect(frFallbacks, contains(AppTypography.devanagariFamily));
      expect(frFallbacks, contains(AppTypography.tamilFamily));
    });

    testWidgets('adheres strictly to 5-level type scale specification', (tester) async {
      final textTheme = AppTypography.buildTextTheme();

      // 1. displayLarge (titles)
      expect(textTheme.displayLarge?.fontSize, equals(24.0));
      expect(textTheme.displayLarge?.fontWeight, equals(FontWeight.w700));
      expect(textTheme.displayLarge?.height, greaterThanOrEqualTo(1.3));

      // 2. headlineMedium (section headers)
      expect(textTheme.headlineMedium?.fontSize, equals(18.0));
      expect(textTheme.headlineMedium?.fontWeight, equals(FontWeight.w600));
      expect(textTheme.headlineMedium?.height, greaterThanOrEqualTo(1.35));

      // 3. bodyLarge (main content / button text)
      expect(textTheme.bodyLarge?.fontSize, equals(15.0));
      expect(textTheme.bodyLarge?.fontWeight, equals(FontWeight.w500));
      expect(textTheme.bodyLarge?.height, greaterThanOrEqualTo(1.4));

      // 4. bodyMedium (secondary text / subtitles)
      expect(textTheme.bodyMedium?.fontSize, equals(13.5));
      expect(textTheme.bodyMedium?.fontWeight, equals(FontWeight.w400));
      expect(textTheme.bodyMedium?.height, greaterThanOrEqualTo(1.4));

      // 5. labelSmall (captions / metadata)
      expect(textTheme.labelSmall?.fontSize, equals(11.5));
      expect(textTheme.labelSmall?.fontWeight, equals(FontWeight.w500));
      expect(textTheme.labelSmall?.height, greaterThanOrEqualTo(1.35));
    });

    testWidgets('build localized TextTheme with safe line heights for Hindi and Tamil', (tester) async {
      final hiTheme = AppTypography.buildTextTheme(locale: const Locale('hi'));
      final taTheme = AppTypography.buildTextTheme(locale: const Locale('ta'));

      for (final theme in [hiTheme, taTheme]) {
        expect(theme.displayLarge?.height, greaterThanOrEqualTo(1.3));
        expect(theme.headlineMedium?.height, greaterThanOrEqualTo(1.35));
        expect(theme.bodyLarge?.height, greaterThanOrEqualTo(1.4));
        expect(theme.bodyMedium?.height, greaterThanOrEqualTo(1.4));
        expect(theme.labelSmall?.height, greaterThanOrEqualTo(1.35));
      }
    });

    testWidgets('AppThemes integrates typography into ThemeData for all themes and locales', (tester) async {
      for (final mode in AppThemeMode.values) {
        final themeEn = AppThemes.getThemeData(mode, locale: const Locale('en'));
        expect(themeEn.textTheme.displayLarge?.fontSize, equals(24.0));
        expect(themeEn.appBarTheme.titleTextStyle?.fontSize, equals(20.0));

        final themeHi = AppThemes.getThemeData(mode, locale: const Locale('hi'));
        expect(themeHi.textTheme.displayLarge?.fontFamilyFallback,
            contains(AppTypography.notoSansFamily));

        final themeTa = AppThemes.getThemeData(mode, locale: const Locale('ta'));
        expect(themeTa.textTheme.displayLarge?.fontFamilyFallback,
            contains(AppTypography.notoSansFamily));
      }
    });
  });

  group('Typography Widget Multi-Script Rendering Tests', () {
    testWidgets('renders Hindi, Tamil, and Latin glyphs without clipping or overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppThemes.getThemeData(AppThemeMode.midnight, locale: const Locale('hi')),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Hindi title with conjuncts & matras
                  Builder(
                    builder: (context) => Text(
                      'डाउनलोड इतिहास और सेटिंग्स',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                  // Tamil section header with complex conjuncts
                  Builder(
                    builder: (context) => Text(
                      'பதிவிறக்க வரலாறு மற்றும் அமைப்புகள்',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  // Latin text with French accents & Spanish inverted punctuation
                  Builder(
                    builder: (context) => Text(
                      '¿Configuración de descarga y vidéos téléchargées?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  // Button with labelSmall metadata
                  Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        '1080p • 42.5 MB • முடிந்தது',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('डाउनलोड इतिहास और सेटिंग्स'), findsOneWidget);
      expect(find.text('பதிவிறக்க வரலாறு மற்றும் அமைப்புகள்'), findsOneWidget);
      expect(find.text('¿Configuración de descarga y vidéos téléchargées?'), findsOneWidget);
      expect(find.text('1080p • 42.5 MB • முடிந்தது'), findsOneWidget);
    });
  });
}
