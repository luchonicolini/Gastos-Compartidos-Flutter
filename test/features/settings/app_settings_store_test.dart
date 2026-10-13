import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/features/settings/data/app_settings_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAppSettingsStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('isReduceMotionEnabled está desactivado por defecto (false)', () async {
      final store = LocalAppSettingsStore();
      final enabled = await store.isReduceMotionEnabled();
      expect(enabled, isFalse);
    });

    test('setReduceMotionEnabled permite activar y persistir reducir animaciones', () async {
      final store = LocalAppSettingsStore();
      await store.setReduceMotionEnabled(true);
      expect(await store.isReduceMotionEnabled(), isTrue);

      await store.setReduceMotionEnabled(false);
      expect(await store.isReduceMotionEnabled(), isFalse);
    });
  });
}
