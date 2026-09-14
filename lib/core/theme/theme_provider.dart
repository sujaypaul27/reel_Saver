import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// StateNotifier that manages and persists the selected [AppThemeMode].
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String preferencesKey = 'app_selected_theme_mode';
  final SharedPreferences? _injectedPreferences;

  ThemeNotifier([this._injectedPreferences])
      : super(_resolveInitialTheme(_injectedPreferences)) {
    if (_injectedPreferences == null) {
      _loadSavedPreference();
    }
  }

  static AppThemeMode _resolveInitialTheme(SharedPreferences? preferences) {
    final savedKey = preferences?.getString(preferencesKey);
    return AppThemeMode.fromString(savedKey);
  }

  Future<void> _loadSavedPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final savedKey = preferences.getString(preferencesKey);
    if (mounted && savedKey != null) {
      state = AppThemeMode.fromString(savedKey);
    }
  }

  /// Updates the active theme mode and persists the choice.
  Future<void> setThemeMode(AppThemeMode newThemeMode) async {
    state = newThemeMode;
    final preferences =
        _injectedPreferences ?? await SharedPreferences.getInstance();
    await preferences.setString(preferencesKey, newThemeMode.name);
  }
}

/// Provider for the active [AppThemeMode].
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// Convenience provider that resolves the full [ThemeData] for the current theme.
final activeThemeDataProvider = Provider<ThemeData>((ref) {
  final currentMode = ref.watch(themeProvider);
  return AppThemes.getThemeData(currentMode);
});
