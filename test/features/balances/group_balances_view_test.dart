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
import 'package:gastos_compartidos/features/balances/presentation/group_balances_screen.dart';
import 'package:gastos_compartidos/features/groups/presentation/group_detail_screen.dart';

void main() {
  late db.AppDatabase database;
  late LocalGroupRepository repository;
  late Person ana;
  late Person marco;
  late Person julia;
  late Group emptyGroup;
  late Group groupWithExpense;

  setUp(() async {
    database = db.AppDatabase.inMemory();
    repository = LocalGroupRepository(database);

    ana = Person(name: 'Ana');
    marco = Person(name: 'Marco');
    julia = Person(name: 'Julia');

    emptyGroup = Group(
      id: 'empty-group-id',
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [ana, marco, julia],
      expenses: [],
    );

    final expense = Expense(
      id: 'expense-1',
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
      groupId: 'expense-group-id',
      splitType: SplitType.equally,
      originalCurrency: Currency.ars,
      referenceCurrency: Currency.ars,
      date: DateTime.now(),
    );

    groupWithExpense = Group(
      id: 'expense-group-id',
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [ana, marco, julia],
      expenses: [expense],
    );

    await repository.save(emptyGroup);
    await repository.save(groupWithExpense);
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
      home: GroupBalancesScreen(
        group: group,
        repository: repository,
      ),
    );
  }

  testWidgets(
      'muestra estado vacío de Cuentas fiel a Imagen 1 cuando no hay gastos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(emptyGroup));
    await tester.pumpAndSettle();

    // Top Navigation
    expect(find.text('Brasil 2026'), findsOneWidget);
    expect(find.text('Cuentas'), findsNWidgets(2)); // Header y Bottom Nav
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);

    // Título y subtítulo
    expect(find.text('Así van las cuentas'), findsOneWidget);
    expect(
      find.text(
        'Cuando haya cuentas por liquidar, te vamos a mostrar\nla forma más simple de saldar.',
      ),
      findsOneWidget,
    );

    // Contenedor de estado vacío
    expect(
      find.text('Todavía no hay cuentas para calcular.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNWidgets(2)); // Card + Bottom Nav
    expect(find.byKey(const Key('go-to-expenses-button')), findsOneWidget);
    expect(find.text('Ir a gastos'), findsOneWidget);
  });

  testWidgets(
      'botón "Ir a gastos" en estado vacío navega a la pestaña de Gastos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GroupDetailScreen(
          group: emptyGroup,
          repository: repository,
          initialTab: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay cuentas para calcular.'), findsOneWidget);

    // Tocar "Ir a gastos"
    await tester.tap(find.byKey(const Key('go-to-expenses-button')));
    await tester.pumpAndSettle();

    // Debe estar en la pestaña Gastos
    expect(find.text('Cargar gasto'), findsOneWidget);
    expect(find.text('Todos los gastos'), findsOneWidget);
  });

  testWidgets(
      'muestra resumen de gastos, balances y pagos sugeridos fiel a Imagen 2',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpense));
    await tester.pumpAndSettle();

    // Hero Total gastado
    expect(find.text('Total gastado'), findsOneWidget);
    expect(find.text(r'$120.000'), findsOneWidget);
    expect(find.text('1 gasto · 3 personas'), findsOneWidget);

    // Sección Balances
    expect(find.text('Balances'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Vos'), findsOneWidget); // Badge Vos
    expect(find.text(r'Le deben $80.000'), findsOneWidget);

    expect(find.text('Marco'), findsOneWidget);
    expect(find.text(r'Debe $40.000'), findsNWidgets(2)); // Marco y Julia

    expect(find.text('Julia'), findsOneWidget);

    // Sección Pagos sugeridos
    expect(find.text('Pagos sugeridos'), findsOneWidget);
    expect(
      find.text('Con estos pagos, las cuentas quedan equilibradas.'),
      findsOneWidget,
    );

    expect(find.text('Marco paga a Ana'), findsOneWidget);
    expect(find.text('Julia paga a Ana'), findsOneWidget);
    expect(find.text('Marcar como pagado'), findsNWidgets(2));
  });

  testWidgets(
      'tocar "Marcar como pagado" abre modal ¿Confirmar pago? fiel a Imagen 1 y cancelar no altera cuentas',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpense));
    await tester.pumpAndSettle();

    // Tocar "Marcar como pagado" de Marco a Ana
    final settleMarco = find.byKey(Key('settle-button-${marco.id}-${ana.id}'));
    expect(settleMarco, findsOneWidget);
    await tester.tap(settleMarco);
    await tester.pumpAndSettle();

    // Verificar modal (Imagen 1)
    expect(find.text('¿Confirmar pago?'), findsOneWidget);
    expect(
      find.text('Este pago se registrará en el grupo y actualizará las cuentas.'),
      findsOneWidget,
    );
    expect(find.text('Pago sugerido para saldar cuentas'), findsOneWidget);
    expect(find.text('Fecha del pago'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    expect(find.text('Nota opcional'), findsOneWidget);
    expect(find.text('Ej. Transferencia bancaria'), findsOneWidget);
    expect(find.byKey(const Key('modal-confirm-payment-button')), findsOneWidget);
    expect(find.byKey(const Key('modal-cancel-payment-button')), findsOneWidget);

    // Cancelar
    await tester.tap(find.byKey(const Key('modal-cancel-payment-button')));
    await tester.pumpAndSettle();

    // El modal se cierra y el pago sigue pendiente
    expect(find.text('¿Confirmar pago?'), findsNothing);
    expect(find.text('Marco paga a Ana'), findsOneWidget);
    expect(find.byKey(const Key('payment-registered-toast')), findsNothing);
  });

  testWidgets(
      'confirmar pagos sugeridos salda todas las deudas y muestra ¡Cuentas claras! y toast Pago registrado fiel a Imágenes 2 y 3',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithExpense));
    await tester.pumpAndSettle();

    // Confirmar primer pago: Marco paga a Ana
    final settleMarco = find.byKey(Key('settle-button-${marco.id}-${ana.id}'));
    expect(settleMarco, findsOneWidget);
    await tester.tap(settleMarco);
    await tester.pumpAndSettle();

    // Confirmar en el modal
    await tester.tap(find.byKey(const Key('modal-confirm-payment-button')));
    await tester.pumpAndSettle();

    // Muestra toast flotante de éxito (Imagen 2)
    expect(find.byKey(const Key('payment-registered-toast')), findsOneWidget);
    expect(find.text('Pago registrado'), findsOneWidget);

    // Estado reflejado en Balances (Imagen 2)
    expect(find.text(r'Le deben $40.000'), findsOneWidget); // Ana
    expect(find.text(r'Al día · $0'), findsOneWidget); // Marco
    expect(find.text(r'Debe $40.000'), findsOneWidget); // Julia

    // Ahora sólo queda 1 pago sugerido pendiente (Julia paga a Ana $40.000)
    expect(find.text('Julia paga a Ana'), findsOneWidget);
    expect(find.text('Marco paga a Ana'), findsNothing);

    // Confirmar segundo pago: Julia paga a Ana
    final settleJulia = find.byKey(Key('settle-button-${julia.id}-${ana.id}'));
    expect(settleJulia, findsOneWidget);
    await tester.tap(settleJulia);
    await tester.pumpAndSettle();

    // Confirmar en el modal
    await tester.tap(find.byKey(const Key('modal-confirm-payment-button')));
    await tester.pumpAndSettle();

    // Ahora todos los balances están al día (Imagen 3)
    expect(find.text(r'Al día · $0'), findsNWidgets(3)); // Ana, Marco y Julia

    // Sección ¡Cuentas claras! (Imagen 3)
    expect(find.text('¡Cuentas claras!'), findsOneWidget);
    expect(
      find.text('No quedan pagos pendientes en este grupo.'),
      findsOneWidget,
    );
    expect(find.text('Pagos sugeridos'), findsNothing);

    // Toast flotante también visible tras el registro (Imagen 3)
    expect(find.byKey(const Key('payment-registered-toast')), findsOneWidget);
  });
}
