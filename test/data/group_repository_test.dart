import 'package:flutter_test/flutter_test.dart';

import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';

void main() {
  late database.AppDatabase appDatabase;
  late LocalGroupRepository repository;

  setUp(() {
    appDatabase = database.AppDatabase.inMemory();
    repository = LocalGroupRepository(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('guarda y recupera un grupo con miembros activos y archivados', () async {
    final group = Group(
      id: 'group-1',
      name: 'Viaje a Brasil',
      creationDate: DateTime(2026, 10, 8),
      iconName: 'flight',
      colorHex: '#2563EB',
      members: [
        Person(id: 'person-1', name: 'Luciano'),
        Person(id: 'person-2', name: 'Ana', isArchived: true),
      ],
    );

    await repository.save(group);
    final groups = await repository.getAll();

    expect(groups, hasLength(1));
    expect(groups.single.id, 'group-1');
    expect(groups.single.name, 'Viaje a Brasil');
    expect(groups.single.members, hasLength(2));
    expect(groups.single.members.first.name, 'Luciano');
    expect(groups.single.members.last.isArchived, isTrue);
  });

  test('actualiza miembros y elimina un grupo completo', () async {
    final group = Group(
      id: 'group-2',
      name: 'Fin de semana',
      members: [Person(id: 'person-3', name: 'Luciano')],
    );

    await repository.save(group);
    await repository.save(
      group.copyWith(
        members: [
          group.members.single.copyWith(isArchived: true),
          Person(id: 'person-4', name: 'Sofía'),
        ],
      ),
    );

    var groups = await repository.getAll();
    expect(groups.single.members, hasLength(2));
    expect(groups.single.members.first.isArchived, isFalse);
    expect(groups.single.members.last.name, 'Luciano');

    await repository.delete(group.id);
    groups = await repository.getAll();
    expect(groups, isEmpty);
  });

  test('persiste gastos con pagador, participantes y reparto', () async {
    final luciano = Person(id: 'person-5', name: 'Luciano');
    final ana = Person(id: 'person-6', name: 'Ana');
    final group = Group(
      id: 'group-3',
      name: 'Cena',
      members: [luciano, ana],
      expenses: [
        Expense(
          id: 'expense-1',
          description: 'Pizza',
          amount: 120,
          payer: luciano,
          participants: [luciano, ana],
          splitType: SplitType.byPercentage,
          splitDetails: {'person-5': 60, 'person-6': 40},
        ),
      ],
    );

    await repository.save(group);
    final loaded = (await repository.getAll()).single;

    expect(loaded.expenses, hasLength(1));
    expect(loaded.expenses.single.description, 'Pizza');
    expect(loaded.expenses.single.payer?.id, luciano.id);
    expect(loaded.expenses.single.participants, hasLength(2));
    expect(loaded.expenses.single.splitType, SplitType.byPercentage);
    expect(loaded.expenses.single.splitDetails?['person-6'], 40);
  });
}
