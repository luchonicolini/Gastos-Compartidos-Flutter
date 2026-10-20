import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/data/preferences/self_member_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SelfMemberStore.clearCache();
  });

  tearDown(SelfMemberStore.clearCache);

  test('activeSelfMemberId devuelve el miembro guardado si sigue activo', () {
    final ana = Person(name: 'Ana');
    final marco = Person(name: 'Marco');
    final group = Group(
      name: 'Viaje',
      referenceCurrency: Currency.ars,
      members: [ana, marco],
    );

    SelfMemberStore.setCache(group.id, marco.id);

    expect(SelfMemberStore.activeSelfMemberId(group), marco.id);
  });

  test('activeSelfMemberId ignora un miembro archivado', () {
    final ana = Person(name: 'Ana');
    final archived = Person(name: 'Marco', isArchived: true);
    final group = Group(
      name: 'Viaje',
      referenceCurrency: Currency.ars,
      members: [ana, archived],
    );

    SelfMemberStore.setCache(group.id, archived.id);

    expect(SelfMemberStore.activeSelfMemberId(group), isNull);
  });

  test('persiste el miembro propio y permite limpiarlo', () async {
    final group = Group(name: 'Viaje', referenceCurrency: Currency.ars);
    final marco = Person(name: 'Marco');

    await SelfMemberStore().setSelfMemberId(group.id, marco.id);
    SelfMemberStore.clearCache();

    expect(await SelfMemberStore().getSelfMemberId(group.id), marco.id);

    await SelfMemberStore().clearSelfMemberId(group.id);
    SelfMemberStore.clearCache();

    expect(await SelfMemberStore().getSelfMemberId(group.id), isNull);
  });
}
