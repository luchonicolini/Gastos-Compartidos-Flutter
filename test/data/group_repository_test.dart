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
            ExpensePayer(person: luciano, amount: Money.fromString('60000', Currency.ars)),
            ExpensePayer(person: ana, amount: Money.fromString('27500', Currency.ars)),
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
    expect(expense.payers.first.amount.cents + expense.payers.last.amount.cents, 8750000);
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
          amount: 50,
          groupId: 'group-5',
          currency: Currency.ars,
        ),
      ],
    );

    await repository.save(group);
    final loaded = (await repository.getAll()).single;

    expect(loaded.settlementPayments, hasLength(1));
    expect(loaded.settlementPayments.single.payerId, ana.id);
    expect(loaded.settlementPayments.single.amount, 50);
  });
}
