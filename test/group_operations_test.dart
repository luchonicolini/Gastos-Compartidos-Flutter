import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/data/database/app_database.dart';
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/features/groups/application/group_operations.dart';

void main() {
  test(
    'las operaciones de grupos y miembros preservan los datos locales',
    () async {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      final operations = GroupOperations(LocalGroupRepository(database));

      var group = await operations.createGroup(name: '  Viaje   a Brasil  ');
      expect(group.name, 'Viaje a Brasil');

      group = await operations.addMember(group, '  Ana  ');
      expect(group.members.single.name, 'Ana');
      await expectLater(
        operations.addMember(group, 'ana'),
        throwsArgumentError,
      );

      group = await operations.setMemberArchived(
        group,
        group.members.single.id,
        true,
      );
      expect(group.members.single.isArchived, isTrue);
      expect(
        (await operations.listGroups()).single.members.single.isArchived,
        isTrue,
      );

      group = await operations.setMemberArchived(
        group,
        group.members.single.id,
        false,
      );
      expect(group.members.single.isArchived, isFalse);

      group = await operations.editMember(
        group,
        group.members.single.id,
        '  Anita  ',
      );
      expect(group.members.single.name, 'Anita');
      expect(
        (await operations.listGroups()).single.members.single.name,
        'Anita',
      );
    },
  );
}
