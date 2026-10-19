import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' hide Expense;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/settlement_payment.dart';
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

  test(
    'no permite cambiar la moneda de referencia si el grupo ya tiene gastos',
    () async {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      final operations = GroupOperations(LocalGroupRepository(database));

      var group = await operations.createGroup(name: 'Viaje');
      group = await operations.addMember(group, 'Ana');
      final ana = group.members.single;

      group = await operations.saveExpense(
        group,
        Expense(
          description: 'Cena',
          amount: 1000,
          payer: ana,
          participants: [ana],
          groupId: group.id,
        ),
      );

      await expectLater(
        operations.editGroup(
          group,
          name: group.name,
          referenceCurrency: Currency.usd,
        ),
        throwsArgumentError,
      );

      expect(
        (await operations.listGroups()).single.referenceCurrency,
        Currency.ars,
      );
    },
  );

  test(
    'no permite cambiar la moneda de referencia si el grupo ya tiene liquidaciones',
    () async {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      final operations = GroupOperations(LocalGroupRepository(database));

      var group = await operations.createGroup(name: 'Viaje');
      group = await operations.addMember(group, 'Ana');
      group = await operations.addMember(group, 'Beto');
      final ana = group.members.firstWhere((m) => m.name == 'Ana');
      final beto = group.members.firstWhere((m) => m.name == 'Beto');

      group = await operations.confirmSettlement(
        group,
        FormattedSettlement(
          payerId: beto.id,
          payeeId: ana.id,
          payerName: beto.name,
          payeeName: ana.name,
          amount: 10,
          formattedAmount: r'$ 10,00',
        ),
      );

      await expectLater(
        operations.editGroup(
          group,
          name: group.name,
          referenceCurrency: Currency.usd,
        ),
        throwsArgumentError,
      );

      expect(
        (await operations.listGroups()).single.referenceCurrency,
        Currency.ars,
      );
    },
  );

  test('un grupo sin historial sí puede cambiar de moneda de referencia',
      () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final operations = GroupOperations(LocalGroupRepository(database));

    final group = await operations.createGroup(name: 'Viaje nuevo');
    final updated = await operations.editGroup(
      group,
      name: group.name,
      referenceCurrency: Currency.usd,
    );

    expect(updated.referenceCurrency, Currency.usd);
    expect(
      (await operations.listGroups()).single.referenceCurrency,
      Currency.usd,
    );
  });
}
