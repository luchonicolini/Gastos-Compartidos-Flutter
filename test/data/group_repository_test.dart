import 'package:flutter_test/flutter_test.dart';

import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/domain/models/settlement_payment.dart';

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

  test(
    'guarda y recupera un grupo con miembros activos y archivados',
    () async {
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
    },
  );

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

  test('persiste moneda original, conversión y múltiples pagadores', () async {
    final luciano = Person(id: 'person-7', name: 'Luciano');
    final ana = Person(id: 'person-8', name: 'Ana');
    final group = Group(
      id: 'group-4',
      name: 'Brasil',
      members: [luciano, ana],
      expenses: [
        Expense(
          id: 'expense-2',
          description: 'Hotel',
          amount: 87500,
          originalAmount: Money.fromString('350', Currency.brl),
          originalCurrency: Currency.brl,
          convertedAmount: Money.fromString('87500', Currency.ars),
          referenceCurrency: Currency.ars,
          exchangeRate: 250,
          payers: [
            ExpensePayer(
              person: luciano,
              amount: Money.fromString('60000', Currency.ars),
            ),
            ExpensePayer(
              person: ana,
              amount: Money.fromString('27500', Currency.ars),
            ),
          ],
          participants: [luciano, ana],
        ),
      ],
    );

    await repository.save(group);
    final expense = (await repository.getAll()).single.expenses.single;

    expect(expense.originalAmount, Money.fromString('350', Currency.brl));
    expect(expense.originalCurrency, Currency.brl);
    expect(expense.referenceCurrency, Currency.ars);
    expect(expense.exchangeRate, 250);
    expect(expense.payers, hasLength(2));
    expect(
      expense.payers.first.amount.cents + expense.payers.last.amount.cents,
      8750000,
    );
  });

  test('persiste liquidaciones confirmadas', () async {
    final luciano = Person(id: 'person-9', name: 'Luciano');
    final ana = Person(id: 'person-10', name: 'Ana');
    final group = Group(
      id: 'group-5',
      name: 'Liquidación',
      members: [luciano, ana],
      settlementPayments: [
        SettlementPayment(
          id: 'settlement-1',
          payerId: ana.id,
          payeeId: luciano.id,
          payerName: ana.name,
          payeeName: luciano.name,
          money: Money.fromString('50', Currency.ars),
          groupId: 'group-5',
        ),
      ],
    );

    await repository.save(group);
    final loaded = (await repository.getAll()).single;

    expect(loaded.settlementPayments, hasLength(1));
    expect(loaded.settlementPayments.single.payerId, ana.id);
    expect(loaded.settlementPayments.single.amount, 50);
    expect(loaded.settlementPayments.single.money.cents, 5000);
  });

  test('persiste una liquidación en la moneda de referencia BRL', () async {
    final luciano = Person(id: 'person-11', name: 'Luciano');
    final ana = Person(id: 'person-12', name: 'Ana');
    final group = Group(
      id: 'group-6',
      name: 'Brasil',
      referenceCurrency: Currency.brl,
      members: [luciano, ana],
      settlementPayments: [
        SettlementPayment(
          id: 'settlement-brl',
          payerId: ana.id,
          payeeId: luciano.id,
          payerName: ana.name,
          payeeName: luciano.name,
          money: Money.fromString('12.34', Currency.brl),
          groupId: 'group-6',
        ),
      ],
    );

    await repository.save(group);
    final loaded = (await repository.getAll()).single;

    expect(loaded.referenceCurrency, Currency.brl);
    expect(
      loaded.settlementPayments.single.money,
      Money.fromString('12.34', Currency.brl),
    );
  });

  test('operaciones granulares: guarda y elimina gasto sin tocar miembros',
      () async {
    final luciano = Person(id: 'p-1', name: 'Luciano');
    final ana = Person(id: 'p-2', name: 'Ana');
    final group = Group(
      id: 'g-granular',
      name: 'Viaje Granular',
      members: [luciano, ana],
    );
    await repository.save(group);

    final expense = Expense(
      id: 'exp-granular',
      description: 'Cena Granular',
      amount: 1500,
      payer: luciano,
      participants: [luciano, ana],
      category: 'Comida',
      notes: 'Propina incluida',
    );

    // Guardar gasto de manera granular
    await repository.saveExpense(group.id, expense);

    var loaded = await repository.getById(group.id);
    expect(loaded, isNotNull);
    expect(loaded!.expenses, hasLength(1));
    expect(loaded.expenses.single.description, 'Cena Granular');
    expect(loaded.expenses.single.category, 'Comida');
    expect(loaded.expenses.single.notes, 'Propina incluida');
    expect(loaded.expenses.single.convertedAmount.cents, 150000);

    // Eliminar gasto de manera granular
    await repository.deleteExpense(expense.id);
    loaded = await repository.getById(group.id);
    expect(loaded!.expenses, isEmpty);
    expect(loaded.members, hasLength(2)); // Los miembros siguen intactos
  });

  test('operaciones granulares: archivar grupo y gestionar miembros', () async {
    final group = Group(
      id: 'g-archive',
      name: 'Grupo Para Archivar',
      budgetCents: 5000000,
    );
    await repository.save(group);

    // Agregar miembro granular
    final marco = Person(id: 'p-marco', name: 'Marco');
    await repository.addMember(group.id, marco);

    var loaded = await repository.getById(group.id);
    expect(loaded!.members, hasLength(1));
    expect(loaded.members.single.name, 'Marco');
    expect(loaded.budgetCents, 5000000);

    // Archivar grupo
    await repository.setGroupArchived(group.id, true);
    loaded = await repository.getById(group.id);
    expect(loaded!.isArchived, isTrue);

    // Filtrar archivados en getAll
    final activeOnly = await repository.getAll(includeArchived: false);
    expect(activeOnly.any((g) => g.id == group.id), isFalse);

    final all = await repository.getAll(includeArchived: true);
    expect(all.any((g) => g.id == group.id), isTrue);
  });

  test('watchAll y watchById emiten actualizaciones reactivas', () async {
    final person = Person(id: 'p-w', name: 'P');
    final group = Group(
      id: 'g-watch',
      name: 'Grupo Reactivo',
      members: [person],
    );
    await repository.save(group);

    final events = <int>[];
    final sub = repository.watchById(group.id).listen((g) {
      if (g != null) {
        events.add(g.expenses.length);
      }
    });

    // Esperar primer evento inicial
    await pumpEventQueue();

    // Agregar gasto para gatillar actualización reactiva
    await repository.saveExpense(
      group.id,
      Expense(
        id: 'exp-w',
        description: 'Reactivo',
        amount: 200,
        payer: person,
        participants: [person],
      ),
    );

    // Esperar procesamiento de eventos
    await pumpEventQueue();
    await sub.cancel();

    expect(events.first, 0);
    expect(events.last, 1);
  });

  test('replaceAll reemplaza todos los datos locales', () async {
    await repository.save(
      Group(id: 'g-viejo', name: 'Viejo', members: [Person(id: 'p-1', name: 'A')]),
    );

    await repository.replaceAll([
      Group(id: 'g-nuevo', name: 'Nuevo', members: [Person(id: 'p-2', name: 'B')]),
    ]);

    final groups = await repository.getAll();
    expect(groups, hasLength(1));
    expect(groups.single.id, 'g-nuevo');
    expect(groups.single.members.single.name, 'B');
  });

  test('replaceAll no pierde los datos anteriores si falla', () async {
    await repository.save(Group(id: 'g-viejo', name: 'Viejo'));

    final invalido = Group(
      id: 'g-nuevo',
      name: 'Nuevo',
      settlementPayments: [
        SettlementPayment(
          payerId: 'p-1',
          payeeId: 'p-2',
          payerName: 'A',
          payeeName: 'B',
          money: const Money(cents: 100, currency: Currency.brl),
        ),
      ],
    );

    await expectLater(
      repository.replaceAll([invalido]),
      throwsArgumentError,
    );

    final groups = await repository.getAll();
    expect(groups, hasLength(1));
    expect(groups.single.name, 'Viejo');
  });
}
