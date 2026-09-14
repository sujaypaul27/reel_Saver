import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/settings/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLanguage Enum & Helpers', () {
    test('resolves language codes correctly', () {
      expect(AppLanguage.fromLanguageCode('en'), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode('hi'), AppLanguage.hindi);
      expect(AppLanguage.fromLanguageCode('ta'), AppLanguage.tamil);
      expect(AppLanguage.fromLanguageCode('es'), AppLanguage.spanish);
      expect(AppLanguage.fromLanguageCode('fr'), AppLanguage.french);
      expect(AppLanguage.fromLanguageCode('unknown'), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode(null), AppLanguage.english);
    });

    test('resolves from Locale objects correctly', () {
      expect(AppLanguage.fromLocale(const Locale('en')), AppLanguage.english);
      expect(AppLanguage.fromLocale(const Locale('hi')), AppLanguage.hindi);
      expect(AppLanguage.fromLocale(const Locale('ta')), AppLanguage.tamil);
      expect(AppLanguage.fromLocale(const Locale('es')), AppLanguage.spanish);
      expect(AppLanguage.fromLocale(const Locale('fr')), AppLanguage.french);
    });

    test('supportedLocales contains all 5 required languages', () {
      expect(
        AppLanguage.supportedLocales,
        containsAll([
          const Locale('en'),
          const Locale('hi'),
          const Locale('ta'),
          const Locale('es'),
          const Locale('fr'),
        ]),
      );
    });
  });

  group('LocaleNotifier Unit Tests', () {
    test('initializes with English by default', () async {
      final preferences = await SharedPreferences.getInstance();
      final notifier = LocaleNotifier(preferences);

      expect(notifier.state, const Locale('en'));
    });

    test('initializes with persisted language when present in SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        LocaleNotifier.preferencesKey: 'hi',
      });
      final preferences = await SharedPreferences.getInstance();
      final notifier = LocaleNotifier(preferences);

      expect(notifier.state, const Locale('hi'));
    });

    test('setLocale updates state and persists language code', () async {
      final preferences = await SharedPreferences.getInstance();
      final notifier = LocaleNotifier(preferences);

      await notifier.setLocale(const Locale('ta'));
      expect(notifier.state, const Locale('ta'));
      expect(preferences.getString(LocaleNotifier.preferencesKey), 'ta');

      await notifier.setLocale(const Locale('es'));
      expect(notifier.state, const Locale('es'));
      expect(preferences.getString(LocaleNotifier.preferencesKey), 'es');

      await notifier.setLocale(const Locale('fr'));
      expect(notifier.state, const Locale('fr'));
      expect(preferences.getString(LocaleNotifier.preferencesKey), 'fr');
    });
  });
}
