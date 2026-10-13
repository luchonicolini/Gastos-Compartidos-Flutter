import 'package:shared_preferences/shared_preferences.dart';

abstract class AppSettingsStore {
  Future<bool> isReduceMotionEnabled();
  Future<void> setReduceMotionEnabled(bool enabled);
}

class LocalAppSettingsStore implements AppSettingsStore {
  LocalAppSettingsStore({this.preferences});

  static const _reduceMotionKey = 'app_settings_reduce_motion_v1';
  final SharedPreferencesAsync? preferences;

  SharedPreferencesAsync? _resolvePreferences() {
    if (preferences != null) return preferences;
    try {
      return SharedPreferencesAsync();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isReduceMotionEnabled() async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return false;
      return (await prefs.getBool(_reduceMotionKey)) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setReduceMotionEnabled(bool enabled) async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return;
      await prefs.setBool(_reduceMotionKey, enabled);
    } catch (_) {}
  }
}

class InMemoryAppSettingsStore implements AppSettingsStore {
  InMemoryAppSettingsStore({bool initialReduceMotion = false})
      : _reduceMotion = initialReduceMotion;

  bool _reduceMotion;

  @override
  Future<bool> isReduceMotionEnabled() async => _reduceMotion;

  @override
  Future<void> setReduceMotionEnabled(bool enabled) async {
    _reduceMotion = enabled;
  }
}
