import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingStatusStore {
  Future<bool> isComplete();

  Future<void> markComplete();

  Future<void> reset();
}

class LocalOnboardingStatusStore implements OnboardingStatusStore {
  LocalOnboardingStatusStore({this.preferences});

  static const key = 'onboarding_complete_v1';
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
  Future<bool> isComplete() async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return false;
      return await prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markComplete() async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return;
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  @override
  Future<void> reset() async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return;
      await prefs.remove(key);
    } catch (_) {}
  }
}
