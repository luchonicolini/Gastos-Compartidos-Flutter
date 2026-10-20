import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/backup/backup_codec.dart';
import 'package:gastos_compartidos/data/backup/backup_file_port.dart';
import 'package:gastos_compartidos/data/backup/data_backup_service.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' hide Group;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/features/onboarding/data/onboarding_status_store.dart';
import 'package:gastos_compartidos/features/settings/presentation/app_settings_scope.dart';
import 'package:gastos_compartidos/features/settings/presentation/settings_screen.dart';

class _FakeOnboardingStore implements OnboardingStatusStore {
  bool resetCalled = false;

  @override
  Future<bool> isComplete() async => true;

  @override
  Future<void> markComplete() async {}

  @override
  Future<void> reset() async => resetCalled = true;
}

class _FakeBackupFilePort implements BackupFilePort {
  String? savedContents;
  String? savedFileName;
  bool saveSucceeds = true;
  String? pickedContents;

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
  Future<String?> pickBackup() async => pickedContents;
}

void main() {
  late AppDatabase database;
  late LocalGroupRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = LocalGroupRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildSettingsScreen({
    VoidCallback? onDataChanged,
    DataBackupService? backupService,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: SettingsScreen(
        repository: repository,
        onDataChanged: onDataChanged,
        backupService: backupService,
      ),
    );
  }

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('muestra la vista de Configuración fiel a las referencias',
      (tester) async {
    setTestSize(tester);

    await tester.pumpWidget(buildSettingsScreen());
    await tester.pumpAndSettle();

    // Encabezado
    expect(find.text('Configuración'), findsOneWidget);
    expect(
      find.text('Personalizá la app y gestioná tu información.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings-back-button')), findsOneWidget);

    // Secciones
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Preferencias'), findsOneWidget);
    expect(find.text('Datos y privacidad'), findsOneWidget);
    expect(find.text('Ayuda'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);

    // Apariencia
    expect(find.text('Reducir animaciones'), findsOneWidget);
    expect(find.byKey(const Key('settings-reduce-motion-switch')), findsOneWidget);

    // El tema oscuro está deshabilitado: no se ofrece elegir tema
    expect(find.byKey(const Key('settings-theme-tile')), findsNothing);
    expect(find.text('Tema'), findsNothing);
    expect(find.text('Usar sistema'), findsNothing);

    // Preferencias
    expect(find.text('Moneda predeterminada'), findsOneWidget);
    expect(find.text('Pesos argentinos · ARS'), findsOneWidget);
    expect(
      find.text(
        'Se usará al crear grupos nuevos. Cada grupo puede tener su propia moneda.',
      ),
      findsOneWidget,
    );

    // Datos y privacidad
    expect(
      find.text('Tus datos se guardan en este dispositivo'),
      findsOneWidget,
    );
    expect(find.text('No se sincronizan ni se comparten.'), findsOneWidget);
    expect(find.text('Exportar datos'), findsOneWidget);
    expect(find.text('Importar datos'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Borrar todos los datos locales'), findsOneWidget);

    // Ayuda
    expect(find.text('Cómo funciona Kune'), findsOneWidget);
    expect(find.text('Contactar soporte'), findsOneWidget);

    // Acerca de
    expect(find.text('Versión de la app'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Licencias de código abierto'), findsOneWidget);

    // Modo de prueba
    expect(find.text('Modo de prueba'), findsOneWidget);
    expect(find.text('Ver Onboarding'), findsOneWidget);
    expect(find.text('Restablecer Onboarding'), findsOneWidget);
  });

  testWidgets('permite alternar reducir animaciones', (tester) async {
    setTestSize(tester);

    await tester.pumpWidget(buildSettingsScreen());
    await tester.pumpAndSettle();

    // Alternar switch de reducir animaciones
    final switchFinder = find.byKey(const Key('settings-reduce-motion-switch'));
    expect((tester.widget(switchFinder) as Switch).value, isFalse);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect((tester.widget(switchFinder) as Switch).value, isTrue);
  });

  testWidgets('permite cambiar moneda predeterminada', (tester) async {
    setTestSize(tester);

    await tester.pumpWidget(buildSettingsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-currency-tile')));
    await tester.pumpAndSettle();

    expect(find.text('Dólares estadounidenses · USD'), findsOneWidget);
    await tester.tap(find.text('Dólares estadounidenses · USD'));
    await tester.pumpAndSettle();

    expect(find.text('Dólares estadounidenses · USD'), findsOneWidget);
  });

  testWidgets('muestra políticas, soporte y términos', (tester) async {
    setTestSize(tester);

    await tester.pumpWidget(buildSettingsScreen());
    await tester.pumpAndSettle();

    // Política de privacidad
    await tester.tap(find.byKey(const Key('settings-privacy-tile')));
    await tester.pumpAndSettle();

    expect(find.textContaining('100% local'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    // Contactar soporte
    await tester.tap(find.byKey(const Key('settings-support-tile')));
    await tester.pumpAndSettle();

    expect(find.text('nicolini.luciano33@gmail.com'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    // Términos de uso
    await tester.tap(find.byKey(const Key('settings-terms-tile')));
    await tester.pumpAndSettle();

    expect(find.textContaining('personal e intransferible'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
  });

  testWidgets('borrar datos locales solicita confirmación y limpia la base',
      (tester) async {
    setTestSize(tester);

    final group = Group(name: 'Grupo a borrar');
    await repository.save(group);
    final initialGroups = await repository.getAll();
    expect(initialGroups.length, 1);

    bool clearedCalled = false;
    await tester.pumpWidget(
      buildSettingsScreen(onDataChanged: () => clearedCalled = true),
    );
    await tester.pumpAndSettle();

    // Tocar borrar datos
    await tester.tap(find.byKey(const Key('settings-clear-data-tile')));
    await tester.pumpAndSettle();

    expect(find.text('¿Borrar todos los datos locales?'), findsOneWidget);

    // Cancelar primero
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(clearedCalled, isFalse);
    expect((await repository.getAll()).length, 1);

    // Tocar de nuevo y confirmar
    await tester.tap(find.byKey(const Key('settings-clear-data-tile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm-clear-data-button')));
    await tester.pumpAndSettle();

    expect(clearedCalled, isTrue);
    expect((await repository.getAll()).length, 0);
  });

  testWidgets('permite ver y restablecer el Onboarding desde Modo de prueba',
      (tester) async {
    setTestSize(tester);

    final store = _FakeOnboardingStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: SettingsScreen(
          repository: repository,
          onboardingStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tocar Ver Onboarding
    await tester.tap(find.byKey(const Key('settings-test-onboarding-tile')));
    await tester.pumpAndSettle();

    // Comprueba que abrió la pantalla de Onboarding
    expect(find.text('¿Quién pagó qué?'), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    // Vuelve a Configuración
    expect(find.text('Modo de prueba'), findsOneWidget);

    // Tocar Restablecer Onboarding
    final resetTile = find.byKey(const Key('settings-reset-onboarding-tile'));
    await tester.ensureVisible(resetTile);
    await tester.pumpAndSettle();
    await tester.tap(resetTile);
    await tester.pumpAndSettle();

    expect(store.resetCalled, isTrue);
    expect(
      find.text(
        'Onboarding restablecido. Se mostrará la próxima vez que abras la app.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'reducir animaciones persiste el cambio y actualiza AppSettingsScope',
      (tester) async {
    setTestSize(tester);

    var motionReduced = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return AppSettingsScope(
              reduceMotion: motionReduced,
              setReduceMotion: (val) => setState(() => motionReduced = val),
              defaultCurrency: Currency.ars,
              setDefaultCurrency: (_) {},
              child: Builder(
                builder: (innerContext) {
                  return SettingsScreen(repository: repository);
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const Key('settings-reduce-motion-switch'));
    expect((tester.widget(switchFinder) as Switch).value, isFalse);
    expect(motionReduced, isFalse);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect((tester.widget(switchFinder) as Switch).value, isTrue);
    expect(motionReduced, isTrue);
  });

  testWidgets(
      'cambiar moneda predeterminada actualiza AppSettingsScope',
      (tester) async {
    setTestSize(tester);

    var currentCurrency = Currency.ars;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return AppSettingsScope(
              reduceMotion: false,
              setReduceMotion: (_) {},
              defaultCurrency: currentCurrency,
              setDefaultCurrency: (c) => setState(() => currentCurrency = c),
              child: Builder(
                builder: (innerContext) {
                  return SettingsScreen(repository: repository);
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pesos argentinos · ARS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-currency-tile')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dólares estadounidenses · USD'));
    await tester.pumpAndSettle();

    expect(currentCurrency, Currency.usd);
    expect(find.text('Dólares estadounidenses · USD'), findsOneWidget);
  });

  testWidgets('exportar datos comparte un respaldo con los grupos',
      (tester) async {
    setTestSize(tester);

    await repository.save(Group(id: 'g-1', name: 'Viaje'));

    final port = _FakeBackupFilePort();
    await tester.pumpWidget(
      buildSettingsScreen(
        backupService: DataBackupService(
          repository: repository,
          filePort: port,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-export-data-tile')));
    await tester.pumpAndSettle();

    expect(port.savedContents, isNotNull);
    final payload = const BackupCodec().decode(port.savedContents!);
    expect(payload.groups.single.name, 'Viaje');
    expect(
      find.text('Respaldo exportado correctamente'),
      findsOneWidget,
    );
  });

  testWidgets('importar datos pide confirmación y reemplaza los grupos',
      (tester) async {
    setTestSize(tester);

    await repository.save(Group(id: 'viejo', name: 'Viejo'));

    final port = _FakeBackupFilePort()
      ..pickedContents = const BackupCodec().encode([
        Group(id: 'nuevo', name: 'Restaurado'),
      ]);

    var dataChanged = false;
    await tester.pumpWidget(
      buildSettingsScreen(
        onDataChanged: () => dataChanged = true,
        backupService: DataBackupService(
          repository: repository,
          filePort: port,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Abre la confirmación
    await tester.tap(find.byKey(const Key('settings-import-data-tile')));
    await tester.pumpAndSettle();
    expect(find.text('¿Importar este respaldo?'), findsOneWidget);

    // Cancelar no cambia nada
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect((await repository.getAll()).single.name, 'Viejo');

    // Confirmar reemplaza los datos
    await tester.tap(find.byKey(const Key('settings-import-data-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-import-data-button')));
    await tester.pumpAndSettle();

    final groups = await repository.getAll();
    expect(groups.single.name, 'Restaurado');
    expect(dataChanged, isTrue);
    expect(find.text('Datos importados correctamente'), findsOneWidget);
  });

  testWidgets('importar un archivo inválido avisa y no cambia los datos',
      (tester) async {
    setTestSize(tester);

    await repository.save(Group(id: 'viejo', name: 'Viejo'));

    final port = _FakeBackupFilePort()..pickedContents = 'no es un respaldo';

    await tester.pumpWidget(
      buildSettingsScreen(
        backupService: DataBackupService(
          repository: repository,
          filePort: port,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-import-data-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-import-data-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('El archivo seleccionado no es un respaldo válido'),
      findsOneWidget,
    );
    expect((await repository.getAll()).single.name, 'Viejo');
  });
}
