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
import 'package:gastos_compartidos/features/groups/presentation/home_screen.dart';

void main() {
  late database.AppDatabase db;
  late LocalGroupRepository repository;

  setUp(() async {
    db = database.AppDatabase.inMemory();
    repository = LocalGroupRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.light(),
      home: HomeScreen(repository: repository),
    );
  }

  testWidgets(
      'muestra pantalla de Mis grupos con diseño fiel a la imagen de referencia',
      (tester) async {
    setTestSize(tester);

    // Miembros
    final yo = Person(name: 'Yo');
    final p2 = Person(name: 'Ana');
    final p3 = Person(name: 'Marcos');
    final p4 = Person(name: 'Julia');

    // Grupo 1: Te deben $ 12.500
    final group1 = Group(
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [yo, p2, p3, p4],
    );
    // Yo pagó 12500 por los otros 3 -> a Yo le deben exactamente 12500
    final expense1 = Expense(
      description: 'Alojamiento',
      amount: 12500.0,
      payer: yo,
      payers: [
        ExpensePayer(
          person: yo,
          amount: Money.fromDecimal(12500.0, Currency.ars),
        ),
      ],
      participants: [p2, p3, p4],
      groupId: group1.id,
      splitType: SplitType.equally,
      originalCurrency: Currency.ars,
      referenceCurrency: Currency.ars,
      date: DateTime.now(),
    );
    // Agregamos gastos adicionales ficticios para llegar a 8 gastos
    final group1WithExpenses = group1.copyWith(
      expenses: [
        expense1,
        for (var i = 1; i < 8; i++)
          Expense(
            description: 'Gasto $i',
            amount: 0.0,
            payer: yo,
            payers: [
              ExpensePayer(
                person: yo,
                amount: Money.fromDecimal(0.0, Currency.ars),
              ),
            ],
            participants: [yo, p2, p3, p4],
            groupId: group1.id,
            splitType: SplitType.equally,
            originalCurrency: Currency.ars,
            referenceCurrency: Currency.ars,
            date: DateTime.now(),
          ),
      ],
    );

    // Grupo 2: Debés $ 4.200
    final group2 = Group(
      name: 'Escapada a Mendoza',
      iconName: 'briefcase',
      colorHex: '#C6500A',
      referenceCurrency: Currency.ars,
      members: [yo, p2, p3, p4],
    );
    // Ana pagó 4200 por Yo -> Yo debe exactamente 4200
    final expense2 = Expense(
      description: 'Bodega',
      amount: 4200.0,
      payer: p2,
      payers: [
        ExpensePayer(
          person: p2,
          amount: Money.fromDecimal(4200.0, Currency.ars),
        ),
      ],
      participants: [yo],
      groupId: group2.id,
      splitType: SplitType.equally,
      originalCurrency: Currency.ars,
      referenceCurrency: Currency.ars,
      date: DateTime.now(),
    );
    final group2WithExpenses = group2.copyWith(
      expenses: [
        expense2,
        for (var i = 1; i < 8; i++)
          Expense(
            description: 'Gasto $i',
            amount: 0.0,
            payer: yo,
            payers: [
              ExpensePayer(
                person: yo,
                amount: Money.fromDecimal(0.0, Currency.ars),
              ),
            ],
            participants: [yo, p2, p3, p4],
            groupId: group2.id,
            splitType: SplitType.equally,
            originalCurrency: Currency.ars,
            referenceCurrency: Currency.ars,
            date: DateTime.now(),
          ),
      ],
    );

    // Grupo 3: Todo al día
    final group3 = Group(
      name: 'Casa de la costa',
      iconName: 'home',
      colorHex: '#6C49C8',
      referenceCurrency: Currency.ars,
      members: [yo, p2, p3, p4],
    );
    final group3WithExpenses = group3.copyWith(
      expenses: [
        for (var i = 0; i < 8; i++)
          Expense(
            description: 'Gasto $i',
            amount: 0.0,
            payer: yo,
            payers: [
              ExpensePayer(
                person: yo,
                amount: Money.fromDecimal(0.0, Currency.ars),
              ),
            ],
            participants: [yo, p2, p3, p4],
            groupId: group3.id,
            splitType: SplitType.equally,
            originalCurrency: Currency.ars,
            referenceCurrency: Currency.ars,
            date: DateTime.now(),
          ),
      ],
    );

    await repository.save(group1WithExpenses);
    await repository.save(group2WithExpenses);
    await repository.save(group3WithExpenses);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Encabezado
    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Tus grupos y gastos compartidos.'), findsOneWidget);
    expect(find.byKey(const Key('settings-header-button')), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    // Grupo 1
    expect(find.text('Brasil 2026'), findsOneWidget);
    expect(find.text('4 personas · 8 gastos'), findsNWidgets(3));
    expect(find.text('Te deben'), findsOneWidget);
    expect(find.text(r'$ 12.500'), findsOneWidget);

    // Grupo 2
    expect(find.text('Escapada a Mendoza'), findsOneWidget);
    expect(find.text('Debés'), findsOneWidget);
    expect(find.text(r'$ 4.200'), findsOneWidget);

    // Grupo 3
    expect(find.text('Casa de la costa'), findsOneWidget);
    expect(find.text('Todo al día'), findsOneWidget);

    // Enlace de grupos finalizados
    expect(find.text('Ver grupos finalizados'), findsOneWidget);
    expect(find.byKey(const Key('view-finalized-groups-button')), findsOneWidget);

    // Botón inferior
    expect(find.text('Crear un nuevo grupo'), findsOneWidget);
    expect(find.byKey(const Key('create-group-bottom-button')), findsOneWidget);
  });

  testWidgets('tocar Ver grupos finalizados abre modal explicativo',
      (tester) async {
    setTestSize(tester);

    final group = Group(name: 'Grupo de prueba');
    await repository.save(group);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('view-finalized-groups-button')));
    await tester.pumpAndSettle();

    expect(find.text('Grupos finalizados'), findsOneWidget);
    expect(
      find.textContaining('Por el momento no tenés grupos archivados'),
      findsOneWidget,
    );
    expect(find.text('Entendido'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(find.text('Grupos finalizados'), findsNothing);
  });

  testWidgets(
      'si ya hay grupos, Crear un nuevo grupo permite regresar a Mis grupos',
      (tester) async {
    setTestSize(tester);

    final group = Group(name: 'Grupo existente');
    await repository.save(group);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Tocar el botón de crear grupo
    await tester.tap(find.byKey(const Key('create-group-bottom-button')));
    await tester.pumpAndSettle();

    // Debe estar en Crear grupo y tener botón de volver
    expect(find.text('Crear grupo'), findsOneWidget);
    expect(find.byKey(const Key('create-group-back-button')), findsOneWidget);

    // Tocar volver
    await tester.tap(find.byKey(const Key('create-group-back-button')));
    await tester.pumpAndSettle();

    // Regresa a Mis grupos
    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Grupo existente'), findsOneWidget);
  });

  testWidgets(
      'si todavía no hay grupos, Crear grupo no muestra botón para regresar',
      (tester) async {
    setTestSize(tester);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Estado vacío inicial
    expect(find.text('Creá tu primer grupo'), findsOneWidget);
    await tester.tap(find.text('Crear mi primer grupo'));
    await tester.pumpAndSettle();

    // Está en Crear grupo pero NO tiene botón para regresar
    expect(find.text('Crear grupo'), findsOneWidget);
    expect(find.byKey(const Key('create-group-back-button')), findsNothing);
  });

  testWidgets(
      'tocar el botón de configuración en Mis grupos abre Configuración',
      (tester) async {
    setTestSize(tester);

    final group = Group(name: 'Grupo de prueba');
    await repository.save(group);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-header-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Personalizá la app y gestioná tu información.'),
      findsOneWidget,
    );
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.byKey(const Key('settings-back-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Mis grupos'), findsOneWidget);
  });

  testWidgets(
      'deslizar grupo a la izquierda revela botón Eliminar y permite eliminar con confirmación',
      (tester) async {
    setTestSize(tester);

    final group = Group(name: 'Grupo Para Borrar');
    await repository.save(group);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Grupo Para Borrar'), findsOneWidget);

    // Deslizar la tarjeta del grupo a la izquierda
    await tester.drag(
      find.byKey(Key('group-card-${group.id}')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    // Acciones reveladas
    expect(find.byKey(Key('slidable-delete-group-${group.id}')), findsOneWidget);
    expect(find.byKey(Key('slidable-edit-group-${group.id}')), findsOneWidget);

    // Tocar Eliminar
    await tester.tap(find.byKey(Key('slidable-delete-group-${group.id}')));
    await tester.pumpAndSettle();

    // Se muestra el bottom sheet de confirmación
    expect(find.text('¿Eliminar Grupo Para Borrar?'), findsOneWidget);
    expect(find.byKey(const Key('confirm-delete-group-button')), findsOneWidget);

    // Confirmar eliminación
    await tester.tap(find.byKey(const Key('confirm-delete-group-button')));
    await tester.pumpAndSettle();

    // El grupo ya no está
    expect(find.text('Grupo Para Borrar'), findsNothing);
  });
}
