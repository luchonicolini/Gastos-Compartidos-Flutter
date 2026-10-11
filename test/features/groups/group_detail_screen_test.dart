import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/features/groups/presentation/group_detail_screen.dart';

void main() {
  late database.AppDatabase db;
  late LocalGroupRepository repository;
  late Person ana;
  late Person marco;
  late Person julia;
  late Group emptyGroup;
  late Group groupWithExpenses;

  setUp(() async {
    db = database.AppDatabase.inMemory();
    repository = LocalGroupRepository(db);

    ana = Person(name: 'Ana');
    marco = Person(name: 'Marco');
    julia = Person(name: 'Julia');

    emptyGroup = Group(
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [ana, marco, julia],
    );

    final expense = Expense(
      description: 'Cena en la playa',
      amount: 120000.0,
      payer: ana,
      payers: [
        ExpensePayer(
          person: ana,
          amount: Money.fromDecimal(120000.0, Currency.ars),
        ),
      ],
      participants: [ana, marco, julia],
      groupId: emptyGroup.id,
      splitType: SplitType.equally,
      originalCurrency: Currency.ars,
      referenceCurrency: Currency.ars,
      date: DateTime.now(),
    );

    groupWithExpenses = emptyGroup.copyWith(
      expenses: [expense],
    );

    await repository.save(emptyGroup);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildScreen(Group group) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: GroupDetailScreen(
        group: group,
        repository: repository,
      ),
    );
  }

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets(
      'muestra Detalle del grupo sin gastos en pestaña Gastos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(emptyGroup));
    await tester.pumpAndSettle();

    // Top Navigation
    expect(find.text('Brasil 2026'), findsOneWidget);
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);

    // Header
    expect(find.text('Todos los gastos'), findsOneWidget);
    expect(find.text('Revisá y editá los gastos del viaje.'), findsOneWidget);

    // Empty state central
    expect(find.textContaining('Todavía no cargaste'), findsOneWidget);
    expect(
      find.textContaining('Anotá el primero para empezar'),
      findsOneWidget,
    );

    // Botón de acción flotante extendido
    final fabFinder = find.byKey(const Key('load-expense-button'));
    expect(fabFinder, findsOneWidget);
    final fab = tester.widget<FloatingActionButton>(fabFinder);
    expect(fab.backgroundColor, const Color(0xFF0D7E88));
    final shape = fab.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(find.text('Cargar gasto'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Tabs inferiores
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Personas'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
  });

  testWidgets(
      'muestra Detalle del grupo con gastos en pestaña Gastos con FAB extendido',
      (tester) async {
    setTestSize(tester);
    await repository.save(groupWithExpenses);

    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Todos los gastos'), findsOneWidget);
    expect(find.textContaining('Total gastado'), findsOneWidget);
    expect(find.textContaining('1 gasto'), findsOneWidget);

    // Gasto listado
    expect(find.text('Cena en la playa'), findsOneWidget);
    expect(find.textContaining('Pagó Ana'), findsOneWidget);
    expect(find.textContaining('3 personas'), findsOneWidget);

    // Botón de acción flotante extendido
    expect(find.byKey(const Key('load-expense-button')), findsOneWidget);
  });

  testWidgets(
      'en pestaña Personas no aparece el FAB de cargar gasto sino Agregar persona',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    // Navegar a pestaña Personas
    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();

    // No debe aparecer Cargar gasto
    expect(find.byKey(const Key('load-expense-button')), findsNothing);

    // Debe aparecer Agregar persona
    expect(find.byKey(const Key('add-person-button')), findsOneWidget);
    expect(find.text('Agregar persona'), findsOneWidget);
  });

  testWidgets(
      'en pestaña Cuentas no aparece el FAB de cargar gasto',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    // Navegar a pestaña Cuentas
    await tester.tap(find.text('Cuentas'));
    await tester.pumpAndSettle();

    // No debe aparecer Cargar gasto ni Agregar persona
    expect(find.byKey(const Key('load-expense-button')), findsNothing);
    expect(find.byKey(const Key('add-person-button')), findsNothing);
  });

  testWidgets(
      'el FAB se oculta cuando el teclado está abierto',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 300), // Simula teclado abierto
          ),
          child: GroupDetailScreen(
            group: groupWithExpenses,
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El FAB debe estar oculto bajo el teclado
    expect(find.byKey(const Key('load-expense-button')), findsNothing);
  });
}
