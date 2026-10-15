import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/currency.dart';

abstract class AppSettingsStore {
  Future<bool> isReduceMotionEnabled();
  Future<void> setReduceMotionEnabled(bool enabled);
  Future<Currency> getDefaultCurrency();
  Future<void> setDefaultCurrency(Currency currency);
}

class LocalAppSettingsStore implements AppSettingsStore {
  LocalAppSettingsStore({this.preferences});

  static const _reduceMotionKey = 'app_settings_reduce_motion_v1';
  static const _defaultCurrencyKey = 'app_settings_default_currency_v1';
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

  @override
  Future<Currency> getDefaultCurrency() async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return Currency.ars;
      final code = await prefs.getString(_defaultCurrencyKey);
      if (code == null || code.isEmpty) return Currency.ars;
      return Currency.fromCode(code);
    } catch (_) {
      return Currency.ars;
    }
  }

  @override
  Future<void> setDefaultCurrency(Currency currency) async {
    try {
      final prefs = _resolvePreferences();
      if (prefs == null) return;
      await prefs.setString(_defaultCurrencyKey, currency.code);
    } catch (_) {}
  }
}

class InMemoryAppSettingsStore implements AppSettingsStore {
  InMemoryAppSettingsStore({
    bool initialReduceMotion = false,
    Currency initialDefaultCurrency = Currency.ars,
  })  : _reduceMotion = initialReduceMotion,
        _defaultCurrency = initialDefaultCurrency;

  bool _reduceMotion;
  Currency _defaultCurrency;

  @override
  Future<bool> isReduceMotionEnabled() async => _reduceMotion;

  @override
  Future<void> setReduceMotionEnabled(bool enabled) async {
    _reduceMotion = enabled;
  }

  @override
  Future<Currency> getDefaultCurrency() async => _defaultCurrency;

  @override
  Future<void> setDefaultCurrency(Currency currency) async {
    _defaultCurrency = currency;
  }
}
