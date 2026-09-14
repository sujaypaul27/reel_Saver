import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/core/theme/app_theme.dart';
import 'package:reel_saver/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppThemes ThemeData Verification', () {
    testWidgets('Midnight theme returns correct dark colorScheme and shape tokens', (tester) async {
      final theme = AppThemes.getThemeData(AppThemeMode.midnight);

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0F19));
      expect(theme.colorScheme.primary, const Color(0xFF6366F1));
      expect(theme.colorScheme.surface, const Color(0xFF0F172A));
      expect(theme.useMaterial3, isTrue);

      final cardTheme = theme.cardTheme;
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      final cardBorder = cardTheme.shape as RoundedRectangleBorder;
      expect(cardBorder.borderRadius, BorderRadius.circular(14));
    });

    testWidgets('Classic Light theme returns correct light colorScheme and shape tokens', (tester) async {
      final theme = AppThemes.getThemeData(AppThemeMode.classicLight);

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(theme.colorScheme.primary, const Color(0xFF2563EB));
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(theme.useMaterial3, isTrue);

      final cardTheme = theme.cardTheme;
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      final cardBorder = cardTheme.shape as RoundedRectangleBorder;
      expect(cardBorder.borderRadius, BorderRadius.circular(14));
    });

    testWidgets('Sunset theme returns correct warm dark colorScheme and shape tokens', (tester) async {
      final theme = AppThemes.getThemeData(AppThemeMode.sunset);

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF160E14));
      expect(theme.colorScheme.primary, const Color(0xFFF97316));
      expect(theme.colorScheme.surface, const Color(0xFF1F151C));
      expect(theme.useMaterial3, isTrue);

      final cardTheme = theme.cardTheme;
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      final cardBorder = cardTheme.shape as RoundedRectangleBorder;
      expect(cardBorder.borderRadius, BorderRadius.circular(14));
    });
  });

  group('ThemeNotifier & themeProvider Tests', () {
    test('defaults to midnight when no SharedPreferences value is stored', () async {
      final preferences = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(preferences);

      expect(notifier.state, AppThemeMode.midnight);
    });

    test('loads persisted theme mode from SharedPreferences on initialization', () async {
      SharedPreferences.setMockInitialValues({
        ThemeNotifier.preferencesKey: AppThemeMode.sunset.name,
      });
      final preferences = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(preferences);

      expect(notifier.state, AppThemeMode.sunset);
    });

    test('accepts injected SharedPreferences for classicLight initialization', () async {
      SharedPreferences.setMockInitialValues({
        ThemeNotifier.preferencesKey: AppThemeMode.classicLight.name,
      });
      final preferences = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(preferences);

      expect(notifier.state, AppThemeMode.classicLight);
    });

    test('setThemeMode updates provider state and persists to SharedPreferences', () async {
      final preferences = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(preferences);

      expect(notifier.state, AppThemeMode.midnight);

      await notifier.setThemeMode(AppThemeMode.classicLight);
      expect(notifier.state, AppThemeMode.classicLight);
      expect(
        preferences.getString(ThemeNotifier.preferencesKey),
        AppThemeMode.classicLight.name,
      );

      await notifier.setThemeMode(AppThemeMode.sunset);
      expect(notifier.state, AppThemeMode.sunset);
      expect(
        preferences.getString(ThemeNotifier.preferencesKey),
        AppThemeMode.sunset.name,
      );
    });

    test('activeThemeDataProvider derives correct ThemeData from themeProvider', () async {
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          themeProvider.overrideWith((ref) => ThemeNotifier(preferences)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(activeThemeDataProvider).brightness,
        Brightness.dark,
      );

      await container.read(themeProvider.notifier).setThemeMode(AppThemeMode.classicLight);

      expect(
        container.read(activeThemeDataProvider).brightness,
        Brightness.light,
      );
    });
  });
}
