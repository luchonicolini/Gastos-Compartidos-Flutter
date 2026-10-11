import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' hide Group, Expense, Person;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/features/groups/presentation/edit_group_screen.dart';
import 'package:gastos_compartidos/features/groups/presentation/group_detail_screen.dart';

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

  Group createTestGroup() {
    final p1 = Person(name: 'Luciano');
    final p2 = Person(name: 'Ana');
    final p3 = Person(name: 'Carlos');
    final p4 = Person(name: 'Sofi');

    return Group(
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [p1, p2, p3, p4],
      expenses: List.generate(
        8,
        (i) => Expense(
          id: 'exp-$i',
          description: 'Gasto $i',
          amount: 100.0,
          payer: p1,
          participants: [p1, p2],
          groupId: 'test-group',
          splitType: SplitType.equally,
          originalCurrency: Currency.ars,
          referenceCurrency: Currency.ars,
          date: DateTime.now(),
        ),
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

  Widget buildEditGroupScreen(Group group) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: EditGroupScreen(
        group: group,
        repository: repository,
      ),
    );
  }

  testWidgets('muestra pantalla de Editar grupo fiel a las referencias visuales',
      (tester) async {
    setTestSize(tester);

    final group = createTestGroup();
    await repository.save(group);

    await tester.pumpWidget(buildEditGroupScreen(group));
    await tester.pumpAndSettle();

    // Título y navegación
    expect(find.text('Editar grupo'), findsOneWidget);
    expect(find.byKey(const Key('edit-group-back-button')), findsOneWidget);

    // Sección 1: Información del grupo
    expect(find.text('Información del grupo'), findsOneWidget);
    expect(find.text('Nombre del grupo'), findsOneWidget);
    expect(find.text('Brasil 2026'), findsNWidgets(2)); // En campo y vista previa

    // Sección 2: Personalización
    expect(find.text('Personalización'), findsOneWidget);
    expect(
      find.text('Elegí cómo reconocer este viaje en tu lista.'),
      findsOneWidget,
    );
    expect(find.text('Vista previa'), findsOneWidget);
    expect(find.text('4 personas · 8 gastos'), findsOneWidget);

    // Sección 3: Moneda del grupo
    expect(find.text('Moneda del grupo'), findsOneWidget);
    expect(find.text('Moneda de referencia'), findsOneWidget);
    expect(find.text('Se usa para balances y pagos sugeridos.'), findsOneWidget);
    expect(find.text(r'ARS · $'), findsOneWidget);
    expect(
      find.text('Cambiarla no modifica los gastos ya cargados.'),
      findsOneWidget,
    );

    // Sección 4: Acciones del grupo
    expect(find.text('Acciones del grupo'), findsOneWidget);
    expect(find.text('Archivar grupo'), findsOneWidget);
    expect(
      find.text('Lo ocultás de tu lista sin perder sus datos'),
      findsOneWidget,
    );
    expect(find.text('Eliminar grupo'), findsOneWidget);
    expect(
      find.text('Se borrarán gastos, personas y pagos'),
      findsOneWidget,
    );

    // Botón Guardar cambios inicialmente deshabilitado (sin cambios)
    final saveButtonFinder = find.byKey(const Key('save-group-changes-button'));
    expect(saveButtonFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(saveButtonFinder);
    expect(button.onPressed, isNull);
  });

  testWidgets('modificar nombre, ícono y color habilita Guardar cambios y actualiza el grupo',
      (tester) async {
    setTestSize(tester);

    final group = createTestGroup();
    await repository.save(group);

    await tester.pumpWidget(buildEditGroupScreen(group));
    await tester.pumpAndSettle();

    // Cambiar nombre
    final nameField = find.byKey(const Key('edit-group-name-field'));
    await tester.enterText(nameField, 'Brasil y Uruguay 2026');
    await tester.pumpAndSettle();

    // Cambiar ícono a playa (beach)
    await tester.tap(find.byKey(const Key('edit-icon-beach')));
    await tester.pumpAndSettle();

    // Cambiar color a naranja
    await tester.tap(find.byKey(const Key('edit-color-#C6500A')));
    await tester.pumpAndSettle();

    // Vista previa actualizada
    expect(find.text('Brasil y Uruguay 2026'), findsNWidgets(2));

    // El botón se habilita
    final saveButtonFinder = find.byKey(const Key('save-group-changes-button'));
    final button = tester.widget<FilledButton>(saveButtonFinder);
    expect(button.onPressed, isNotNull);

    // Guardar
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Verificar en el repositorio
    final updated = await repository.getById(group.id);
    expect(updated, isNotNull);
    expect(updated!.name, 'Brasil y Uruguay 2026');
    expect(updated.iconName, 'beach');
    expect(updated.colorHex, '#C6500A');
  });

  testWidgets('cambiar moneda de referencia actualiza el grupo',
      (tester) async {
    setTestSize(tester);

    final group = createTestGroup();
    await repository.save(group);

    await tester.pumpWidget(buildEditGroupScreen(group));
    await tester.pumpAndSettle();

    // Tocar selector de moneda
    await tester.tap(find.byKey(const Key('edit-group-currency-tile')));
    await tester.pumpAndSettle();

    expect(find.text('Dólar estadounidense · USD'), findsOneWidget);
    await tester.tap(find.text('Dólar estadounidense · USD'));
    await tester.pumpAndSettle();

    expect(find.text('USD · US\$'), findsOneWidget);

    // Guardar
    await tester.tap(find.byKey(const Key('save-group-changes-button')));
    await tester.pumpAndSettle();

    final updated = await repository.getById(group.id);
    expect(updated!.referenceCurrency, Currency.usd);
  });

  testWidgets('tocar Archivar grupo abre modal con diseño fiel', (tester) async {
    setTestSize(tester);

    final group = createTestGroup();
    await repository.save(group);

    await tester.pumpWidget(buildEditGroupScreen(group));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-group-archive-tile')));
    await tester.pumpAndSettle();

    expect(find.text('¿Archivar Brasil 2026?'), findsOneWidget);
    expect(
      find.text(
        'El grupo dejará de aparecer en Mis grupos, pero sus gastos, personas y cuentas se conservarán.',
      ),
      findsOneWidget,
    );
    expect(find.text('Podés recuperarlo cuando quieras.'), findsOneWidget);
    expect(find.byKey(const Key('confirm-archive-group-button')), findsOneWidget);
    expect(find.byKey(const Key('cancel-archive-group-button')), findsOneWidget);

    // Cancelar cierra el modal
    await tester.tap(find.byKey(const Key('cancel-archive-group-button')));
    await tester.pumpAndSettle();

    expect(find.text('¿Archivar Brasil 2026?'), findsNothing);
  });

  testWidgets('tocar Eliminar grupo solicita confirmación y borra el grupo',
      (tester) async {
    setTestSize(tester);

    final group = createTestGroup();
    await repository.save(group);

    await tester.pumpWidget(buildEditGroupScreen(group));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-group-delete-tile')));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar Brasil 2026?'), findsOneWidget);
    expect(
      find.text(
        'Se eliminarán permanentemente 8 gastos, 4 personas y los pagos registrados.',
      ),
      findsOneWidget,
    );
    expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);
    expect(find.byKey(const Key('confirm-delete-group-button')), findsOneWidget);
    expect(find.byKey(const Key('cancel-delete-group-button')), findsOneWidget);

    // Cancelar primero
    await tester.tap(find.byKey(const Key('cancel-delete-group-button')));
    await tester.pumpAndSettle();

    expect(await repository.getById(group.id), isNotNull);

    // Eliminar de verdad
    await tester.tap(find.byKey(const Key('edit-group-delete-tile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm-delete-group-button')));
    await tester.pumpAndSettle();

    expect(await repository.getById(group.id), isNull);
  });

  testWidgets('desde GroupDetailScreen se puede abrir Editar grupo',
      (tester) async {
    setTestSize(tester);

    final group = createTestGroup();
    await repository.save(group);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GroupDetailScreen(group: group, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    // Abrir menú de 3 puntos
    await tester.tap(find.byKey(const Key('group-detail-menu-button')));
    await tester.pumpAndSettle();

    expect(find.text('Editar grupo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-detail-menu-edit')));
    await tester.pumpAndSettle();

    // Abre Editar grupo
    expect(find.text('Información del grupo'), findsOneWidget);
    expect(find.byKey(const Key('edit-group-name-field')), findsOneWidget);
  });
}
