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

@DriftDatabase(tables: [Groups, Persons, GroupMembers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'gastos_compartidos'));

  AppDatabase.inMemory() : super(openMemoryDatabase());

  @override
  int get schemaVersion => 1;
}
