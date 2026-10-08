import 'package:flutter_test/flutter_test.dart';

import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';

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
}
