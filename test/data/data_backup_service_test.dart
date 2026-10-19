import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/data/backup/backup_codec.dart';
import 'package:gastos_compartidos/data/backup/backup_file_port.dart';
import 'package:gastos_compartidos/data/backup/data_backup_service.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';

class _FakeBackupFilePort implements BackupFilePort {
  String? savedContents;
  String? savedFileName;
  bool saveSucceeds = true;
  String? pickedContents;
  bool allowPick = true;

  @override
  Future<bool> saveBackup({
    required String contents,
    required String fileName,
  }) async {
    savedContents = contents;
    savedFileName = fileName;
    return saveSucceeds;
  }

  @override
  Future<String?> pickBackup() async => allowPick ? pickedContents : null;
}

void main() {
  late database.AppDatabase appDatabase;
  late LocalGroupRepository repository;
  late _FakeBackupFilePort filePort;

  setUp(() {
    appDatabase = database.AppDatabase.inMemory();
    repository = LocalGroupRepository(appDatabase);
    filePort = _FakeBackupFilePort();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  DataBackupService buildService() =>
      DataBackupService(repository: repository, filePort: filePort);

  Group buildGroupWithExpense() {
    final ana = Person(id: 'p-ana', name: 'Ana');
    return Group(
      id: 'g-1',
      name: 'Viaje',
      referenceCurrency: Currency.ars,
      members: [ana],
      expenses: [
        Expense(
          id: 'e-1',
          description: 'Cena',
          amount: 2000,
          participants: [ana],
          groupId: 'g-1',
          originalAmount: const Money(cents: 200000, currency: Currency.ars),
          convertedAmount: const Money(cents: 200000, currency: Currency.ars),
        ),
      ],
    );
  }

  test('exporta todos los grupos a un archivo versionado', () async {
    await repository.save(Group(id: 'g-2', name: 'Uno'));
    await repository.save(buildGroupWithExpense());

    final result = await buildService().exportBackup(
      now: DateTime.utc(2026, 10, 19),
    );

    expect(result, isNotNull);
    expect(result!.groupCount, 2);
    expect(result.expenseCount, 1);
    expect(result.fileName, 'gastos-compartidos-2026-10-19.json');
    expect(filePort.savedFileName, 'gastos-compartidos-2026-10-19.json');

    final payload = const BackupCodec().decode(filePort.savedContents!);
    expect(payload.groups, hasLength(2));
    expect(
      payload.groups.map((group) => group.name).toSet(),
      {'Uno', 'Viaje'},
    );
  });

  test('devuelve null si el usuario no comparte el respaldo', () async {
    await repository.save(Group(name: 'Uno'));
    filePort.saveSucceeds = false;

    final result = await buildService().exportBackup();

    expect(result, isNull);
  });

  test('importa un respaldo y reemplaza los datos locales', () async {
    await repository.save(Group(id: 'viejo', name: 'Viejo'));

    filePort.pickedContents = const BackupCodec().encode([
      buildGroupWithExpense(),
    ]);

    final result = await buildService().importBackup();

    expect(result, isNotNull);
    expect(result!.groupCount, 1);
    expect(result.expenseCount, 1);

    final groups = await repository.getAll();
    expect(groups, hasLength(1));
    expect(groups.single.name, 'Viaje');
    expect(groups.single.members.single.name, 'Ana');
    expect(groups.single.expenses.single.description, 'Cena');
  });

  test('cancelar la selección no modifica los datos', () async {
    await repository.save(Group(id: 'viejo', name: 'Viejo'));
    filePort.pickedContents = null;

    final result = await buildService().importBackup();

    expect(result, isNull);
    expect((await repository.getAll()).single.name, 'Viejo');
  });

  test('un archivo inválido no modifica los datos', () async {
    await repository.save(Group(id: 'viejo', name: 'Viejo'));
    filePort.pickedContents = 'esto no es un respaldo';

    await expectLater(
      buildService().importBackup(),
      throwsA(isA<BackupFormatException>()),
    );

    expect((await repository.getAll()).single.name, 'Viejo');
  });
}
