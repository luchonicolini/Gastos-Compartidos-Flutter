import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingStatusStore {
  Future<bool> isComplete();

  Future<void> markComplete();

  Future<void> reset();
}

class LocalOnboardingStatusStore implements OnboardingStatusStore {
  LocalOnboardingStatusStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'onboarding_complete_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isComplete() async => await _preferences.getBool(key) ?? false;

  @override
  Future<void> markComplete() => _preferences.setBool(key, true);

  @override
  Future<void> reset() => _preferences.remove(key);
}
