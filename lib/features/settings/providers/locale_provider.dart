import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported application languages.
enum AppLanguage {
  english(Locale('en'), 'English'),
  hindi(Locale('hi'), 'Hindi'),
  tamil(Locale('ta'), 'Tamil'),
  spanish(Locale('es'), 'Spanish'),
  french(Locale('fr'), 'French');

  final Locale locale;
  final String displayName;

  const AppLanguage(this.locale, this.displayName);

  /// List of all supported locales for MaterialApp.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Resolves an [AppLanguage] from a language code (e.g. 'en', 'hi').
  static AppLanguage fromLanguageCode(String? code) {
    switch (code) {
      case 'hi':
        return AppLanguage.hindi;
      case 'ta':
        return AppLanguage.tamil;
      case 'es':
        return AppLanguage.spanish;
      case 'fr':
        return AppLanguage.french;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }

  /// Resolves an [AppLanguage] from a [Locale].
  static AppLanguage fromLocale(Locale locale) {
    return fromLanguageCode(locale.languageCode);
  }
}

/// StateNotifier responsible for managing and persisting the application locale.
class LocaleNotifier extends StateNotifier<Locale> {
  static const String preferencesKey = 'app_selected_language_code';
  final SharedPreferences? _injectedPreferences;

  LocaleNotifier([this._injectedPreferences])
      : super(_resolveInitialLocale(_injectedPreferences)) {
    if (_injectedPreferences == null) {
      _loadSavedPreference();
    }
  }

  static Locale _resolveInitialLocale(SharedPreferences? preferences) {
    final savedCode = preferences?.getString(preferencesKey);
    return AppLanguage.fromLanguageCode(savedCode).locale;
  }

  Future<void> _loadSavedPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(preferencesKey);
    if (savedCode != null) {
      state = AppLanguage.fromLanguageCode(savedCode).locale;
    }
  }

  /// Updates the application locale and persists the chosen language code.
  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    final preferences =
        _injectedPreferences ?? await SharedPreferences.getInstance();
    await preferences.setString(preferencesKey, newLocale.languageCode);
  }
}

/// Shared Riverpod provider for the active application locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
