import 'package:shared_preferences/shared_preferences.dart';

abstract class AppSettingsStore {
  Future<bool> isReduceMotionEnabled();
  Future<void> setReduceMotionEnabled(bool enabled);
}

class LocalAppSettingsStore implements AppSettingsStore {
  LocalAppSettingsStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _reduceMotionKey = 'app_settings_reduce_motion_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isReduceMotionEnabled() async {
    return (await _preferences.getBool(_reduceMotionKey)) ?? false;
  }

  @override
  Future<void> setReduceMotionEnabled(bool enabled) async {
    await _preferences.setBool(_reduceMotionKey, enabled);
  }
}
