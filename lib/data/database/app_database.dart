import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'memory_database.dart';

part 'app_database.g.dart';

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get creationDate => dateTime()();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get referenceCurrencyCode => text().withDefault(const Constant('ARS'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Persons extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get creationDate => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GroupMembers extends Table {
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get personId => text().references(Persons, #id)();

  @override
  Set<Column<Object>> get primaryKey => {groupId, personId};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get payerId => text().nullable()();
  IntColumn get splitType => integer()();
  TextColumn get splitDetailsJson => text().nullable()();
  IntColumn get originalAmountCents => integer().withDefault(const Constant(0))();
  TextColumn get originalCurrencyCode => text().withDefault(const Constant('ARS'))();
  TextColumn get referenceCurrencyCode => text().withDefault(const Constant('ARS'))();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExpensePayers extends Table {
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get personId => text().references(Persons, #id)();
  IntColumn get amountCents => integer()();
  TextColumn get currencyCode => text()();

  @override
  Set<Column<Object>> get primaryKey => {expenseId, personId};
}

class ExpenseParticipants extends Table {
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get personId => text().references(Persons, #id)();

  @override
  Set<Column<Object>> get primaryKey => {expenseId, personId};
}

class ExpenseSplits extends Table {
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get personId => text().references(Persons, #id)();
  RealColumn get value => real()();

  @override
  Set<Column<Object>> get primaryKey => {expenseId, personId};
}

class Settlements extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get payerId => text()();
  TextColumn get payeeId => text()();
  TextColumn get payerName => text()();
  TextColumn get payeeName => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currencyCode => text()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Groups, Persons, GroupMembers, Expenses, ExpensePayers, ExpenseParticipants, ExpenseSplits, Settlements])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'gastos_compartidos'));

  AppDatabase.inMemory() : super(openMemoryDatabase());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator migrator) => migrator.createAll(),
        onUpgrade: (Migrator migrator, int from, int to) async {
          if (from < 2) {
            await migrator.createTable(expenses);
            await migrator.createTable(expenseParticipants);
            await migrator.createTable(expenseSplits);
          }
          if (from < 3) {
            await migrator.addColumn(expenses, expenses.originalAmountCents);
            await migrator.addColumn(expenses, expenses.originalCurrencyCode);
            await migrator.addColumn(expenses, expenses.referenceCurrencyCode);
            await migrator.addColumn(expenses, expenses.exchangeRate);
            await migrator.createTable(expensePayers);
          }
          if (from < 4) {
            await migrator.addColumn(groups, groups.referenceCurrencyCode);
          }
          if (from < 5) {
            await migrator.createTable(settlements);
          }
        },
      );
}
