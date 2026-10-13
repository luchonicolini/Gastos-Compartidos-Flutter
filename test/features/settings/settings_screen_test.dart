import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' hide Group;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/features/onboarding/data/onboarding_status_store.dart';
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

  Widget buildSettingsScreen({VoidCallback? onDataCleared}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: SettingsScreen(
        repository: repository,
        onDataCleared: onDataCleared,
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
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Usar sistema'), findsOneWidget);
    expect(find.text('Reducir animaciones'), findsOneWidget);
    expect(find.byKey(const Key('settings-reduce-motion-switch')), findsOneWidget);

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
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Borrar todos los datos locales'), findsOneWidget);

    // Ayuda
    expect(find.text('Cómo funciona Gastos Compartidos'), findsOneWidget);
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

  testWidgets('permite cambiar tema y alternar reducir animaciones',
      (tester) async {
    setTestSize(tester);

    await tester.pumpWidget(buildSettingsScreen());
    await tester.pumpAndSettle();

    // Cambiar tema
    await tester.tap(find.byKey(const Key('settings-theme-tile')));
    await tester.pumpAndSettle();

    expect(find.text('Tema de la app'), findsOneWidget);
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(find.text('Oscuro'), findsOneWidget);

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

    expect(find.text('soporte@gastoscompartidos.app'), findsOneWidget);
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
      buildSettingsScreen(onDataCleared: () => clearedCalled = true),
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
    await tester.tap(find.byKey(const Key('settings-reset-onboarding-tile')));
    await tester.pumpAndSettle();

    expect(store.resetCalled, isTrue);
    expect(
      find.text(
        'Onboarding restablecido. Se mostrará la próxima vez que abras la app.',
      ),
      findsOneWidget,
    );
  });
}
