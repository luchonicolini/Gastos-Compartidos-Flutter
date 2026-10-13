import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as db;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/money.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/features/expenses/presentation/all_expenses_screen.dart';
import 'package:gastos_compartidos/features/groups/presentation/group_detail_screen.dart';

void main() {
  late db.AppDatabase database;
  late LocalGroupRepository repository;
  late Person ana;
  late Person marco;
  late Person julia;
  late Group emptyGroup;
  late Group groupWithExpenses;
  late Expense expense1;
  late Expense expense2;

  setUp(() async {
    database = db.AppDatabase.inMemory();
    repository = LocalGroupRepository(database);

    ana = Person(name: 'Ana');
    marco = Person(name: 'Marco');
    julia = Person(name: 'Julia');

    emptyGroup = Group(
      id: 'empty-group-all-expenses',
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [ana, marco, julia],
      expenses: [],
    );

    expense1 = Expense(
      id: 'exp-1',
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
      groupId: 'group-with-all-expenses',
      splitType: SplitType.equally,
      originalCurrency: Currency.ars,
      referenceCurrency: Currency.ars,
      date: DateTime.now(),
    );

    expense2 = Expense(
      id: 'exp-2',
      description: 'Taxi al aeropuerto',
      amount: 18000.0,
      payer: julia,
      payers: [
        ExpensePayer(
          person: julia,
          amount: Money.fromDecimal(90.0, Currency.brl),
        ),
      ],
      participants: [ana, marco, julia],
      groupId: 'group-with-all-expenses',
      splitType: SplitType.equally,
      originalCurrency: Currency.brl,
      originalAmount: Money.fromDecimal(90.0, Currency.brl),
      referenceCurrency: Currency.ars,
      date: DateTime.now().subtract(const Duration(days: 1)),
    );

    groupWithExpenses = Group(
      id: 'group-with-all-expenses',
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [ana, marco, julia],
      expenses: [expense1, expense2],
    );

    await repository.save(emptyGroup);
    await repository.save(groupWithExpenses);
  });

  tearDown(() async {
    await database.close();
  });

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget buildScreen(Group group) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: AllExpensesScreen(
        group: group,
        repository: repository,
      ),
    );
  }

  testWidgets(
      'muestra estado vacío de Todos los gastos fiel a Imagen 2 cuando no hay gastos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(emptyGroup));
    await tester.pumpAndSettle();

    // Top Navigation
    expect(find.text('Brasil 2026'), findsOneWidget);
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Título y subtítulo
    expect(find.text('Todos los gastos'), findsOneWidget);
    expect(find.text('Revisá y editá los gastos de este grupo.'), findsOneWidget);

    // Tarjeta menta de estado vacío
    expect(find.text('Todavía no cargaste\ngastos'), findsOneWidget);
    expect(
      find.text('Anotá el primero para empezar a\nordenar las cuentas.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('load-expense-button')), findsOneWidget);

    // Barra inferior
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Personas'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
  });

  testWidgets(
      'muestra lista de gastos agrupada por fecha y multidivisa fiel a Imagen 1',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    // Hero Total gastado
    expect(find.text('Total gastado'), findsOneWidget);
    expect(find.text(r'$138.000'), findsOneWidget);
    expect(find.text('2 gastos'), findsOneWidget);

    // Encabezados de fecha
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);

    // Gastos individuales
    expect(find.text('Cena en la playa'), findsOneWidget);
    expect(find.text('Pagó Ana · Entre 3 personas'), findsOneWidget);
    expect(find.text(r'$120.000'), findsOneWidget);

    expect(find.text('Taxi al aeropuerto'), findsOneWidget);
    expect(find.text('Pagó Julia · Entre 3 personas'), findsOneWidget);
    expect(find.text(r'$18.000'), findsOneWidget);
    expect(find.text(r'R$ 90 · BRL'), findsOneWidget);

    // Botón inferior para cargar gasto
    expect(find.byKey(const Key('load-expense-button')), findsOneWidget);
  });

  testWidgets(
      'tocar tarjeta de gasto abre menú con Editar y Eliminar fiel a Imagen 3',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    final card = find.byKey(Key('expense-card-${expense1.id}'));
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    // Menú flotante contextual
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets(
      'seleccionar Eliminar abre modal de confirmación y permite cancelar o eliminar fiel a Imagen 4',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    // Abrir menú de Cena en la playa
    await tester.tap(find.byKey(Key('expense-card-${expense1.id}')));
    await tester.pumpAndSettle();

    // Tocar Eliminar en el menú
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // Modal de confirmación (Imagen 4)
    expect(find.text('¿Eliminar este gasto?'), findsOneWidget);
    expect(
      find.text('Los balances del grupo se recalcularán.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cancel-delete-expense-button')), findsOneWidget);
    expect(find.byKey(const Key('confirm-delete-expense-button')), findsOneWidget);

    // Cancelar
    await tester.tap(find.byKey(const Key('cancel-delete-expense-button')));
    await tester.pumpAndSettle();

    // El gasto sigue existiendo
    expect(find.text('Cena en la playa'), findsOneWidget);

    // Abrir de nuevo y confirmar eliminación
    await tester.tap(find.byKey(Key('expense-card-${expense1.id}')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm-delete-expense-button')));
    await tester.pumpAndSettle();

    // Cena en la playa ya no está, solo queda Taxi al aeropuerto
    expect(find.text('Cena en la playa'), findsNothing);
    expect(find.text('Taxi al aeropuerto'), findsOneWidget);
    expect(find.text('1 gasto'), findsOneWidget);
  });

  testWidgets(
      'al abrir Detalle del grupo muestra directamente la pestaña Todos los gastos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GroupDetailScreen(
          group: groupWithExpenses,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ahora estamos directamente en Todos los gastos (pestaña Gastos)
    expect(find.text('Todos los gastos'), findsOneWidget);
    expect(find.text('Total gastado'), findsOneWidget);
    expect(find.text('Cena en la playa'), findsOneWidget);
  });

  testWidgets(
      'deslizar gasto a la izquierda revela acciones de Editar y Eliminar (Slidable)',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpenses));
    await tester.pumpAndSettle();

    final card = find.byKey(Key('expense-card-${expense1.id}'));
    expect(card, findsOneWidget);

    // Deslizar tarjeta a la izquierda
    await tester.drag(card, const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Las acciones de Slidable deben ser visibles
    final editAction = find.byKey(Key('slidable-edit-${expense1.id}'));
    final deleteAction = find.byKey(Key('slidable-delete-${expense1.id}'));
    expect(editAction, findsOneWidget);
    expect(deleteAction, findsOneWidget);

    // Tocar Eliminar desde el Slidable abre modal de confirmación
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar este gasto?'), findsOneWidget);
    expect(find.byKey(const Key('cancel-delete-expense-button')), findsOneWidget);

    // Cancelar
    await tester.tap(find.byKey(const Key('cancel-delete-expense-button')));
    await tester.pumpAndSettle();
    expect(find.text('Cena en la playa'), findsOneWidget);
  });
}
