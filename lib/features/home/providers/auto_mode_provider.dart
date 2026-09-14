import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StateNotifier responsible for managing and persisting the automatic clipboard detection setting.
class AutoModeNotifier extends StateNotifier<bool> {
  static const String preferencesKey = 'is_automatic_detection_enabled';
  final SharedPreferences? _injectedPreferences;

  AutoModeNotifier([this._injectedPreferences])
      : super(_injectedPreferences?.getBool(preferencesKey) ?? true) {
    if (_injectedPreferences == null) {
      _loadSavedPreference();
    }
  }

  /// Loads the persisted boolean value from [SharedPreferences].
  Future<void> _loadSavedPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getBool(preferencesKey);
    if (savedValue != null) {
      state = savedValue;
    }
  }

  /// Updates the auto mode setting and persists it.
  Future<void> setAutoMode(bool isEnabled) async {
    state = isEnabled;
    final preferences = _injectedPreferences ?? await SharedPreferences.getInstance();
    await preferences.setBool(preferencesKey, isEnabled);
  }

  /// Toggles the current auto mode value and persists it.
  Future<void> toggleAutoMode() async {
    await setAutoMode(!state);
  }
}

/// Shared Riverpod provider for the automatic clipboard detection setting.
final autoModeProvider = StateNotifierProvider<AutoModeNotifier, bool>((ref) {
  return AutoModeNotifier();
});
