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
import 'package:gastos_compartidos/features/expenses/presentation/create_expense_screen.dart';

void main() {
  late database.AppDatabase db;
  late LocalGroupRepository repository;
  late Group group;

  setUp(() async {
    db = database.AppDatabase.inMemory();
    repository = LocalGroupRepository(db);
    group = Group(
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [
        Person(name: 'Ana'),
        Person(name: 'Marco'),
        Person(name: 'Julia'),
      ],
    );
    await repository.save(group);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildScreen(Group testGroup) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: CreateExpenseScreen(
        repository: repository,
        group: testGroup,
      ),
    );
  }

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets(
      'muestra la pantalla de carga de gastos idéntica a la referencia',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Brasil 2026'), findsOneWidget);
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);

    // Título y bajada
    expect(find.text('Cargá un gasto'), findsOneWidget);
    expect(
      find.text(
        'Anotá lo que pagaron para que las cuentas estén siempre claras.',
      ),
      findsOneWidget,
    );

    // Campos de entrada
    expect(find.text('¿Qué pagaron?'), findsOneWidget);
    expect(find.text('Ej. Cena en la playa'), findsOneWidget);
    expect(find.text('Importe'), findsOneWidget);
    expect(find.text('0,00'), findsOneWidget);
    expect(find.text('ARS'), findsOneWidget);

    // Secciones de pagadores y división
    expect(find.text('¿Quién pagó?'), findsOneWidget);
    expect(find.text('Elegí una o más personas'), findsOneWidget);
    expect(find.text('¿Entre quiénes se divide?'), findsOneWidget);
    expect(find.text('Por ahora, dividilo en partes iguales'), findsOneWidget);

    // Chips de personas presentes
    expect(find.text('Ana'), findsNWidgets(2)); // Payer + Participant
    expect(find.text('Marco'), findsNWidgets(2));
    expect(find.text('Julia'), findsNWidgets(2));

    // Acción para cambiar forma de división
    expect(find.text('Cambiar forma de dividir'), findsOneWidget);

    // Botón deshabilitado inicialmente (como en la Imagen 1)
    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(saveButton, findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    // Leyenda inferior
    expect(find.text('Podés editarlo después.'), findsOneWidget);
  });

  testWidgets(
      'habilita Guardar gasto y persiste los datos al completar la información',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    // Completar descripción y monto
    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Cena en la playa',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '120.000',
    );
    await tester.pumpAndSettle();

    // Ahora el botón debe estar habilitado (como en la Imagen 2)
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    // Guardar el gasto
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verificar persistencia en el repositorio
    final updatedGroups = await repository.getAll();
    expect(updatedGroups.single.expenses, hasLength(1));

    final expense = updatedGroups.single.expenses.first;
    expect(expense.description, 'Cena en la playa');
    expect(expense.amount, 120000.0);
    expect(expense.payer?.name, 'Ana');
    expect(
      expense.participants.map((p) => p.name).toList(),
      unorderedEquals(['Ana', 'Marco', 'Julia']),
    );
    expect(expense.splitType, SplitType.equally);
    expect(expense.originalCurrency.code, 'ARS');
  });

  testWidgets('permite cambiar pagadores y participantes', (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    final marcoId = group.members[1].id;
    // Seleccionar a Marco como pagador
    await tester.tap(find.byKey(Key('payer-$marcoId')));
    await tester.pumpAndSettle();

    // Deseleccionar a Julia como participante
    final juliaId = group.members[2].id;
    await tester.tap(find.byKey(Key('participant-$juliaId')));
    await tester.pumpAndSettle();

    // Completar datos
    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Supermercado',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '50000',
    );
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final updated = (await repository.getAll()).single.expenses.single;
    expect(updated.payers, hasLength(2)); // Ana y Marco
    expect(
      updated.participants.map((p) => p.name).toList(),
      unorderedEquals(['Ana', 'Marco']),
    );
  });

  testWidgets('permite cambiar la moneda del gasto usando el selector moderno',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('currency-picker-button')));
    await tester.pumpAndSettle();

    // Modal Elegí la moneda
    expect(find.text('Elegí la moneda'), findsOneWidget);
    expect(find.text('Moneda del grupo'), findsOneWidget);
    expect(find.byKey(const Key('currency-search-field')), findsOneWidget);

    // Seleccionar USD
    await tester.tap(find.byKey(const Key('currency-option-USD')));
    await tester.pumpAndSettle();

    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets(
      'muestra advertencia de tipo de cambio y deshabilita guardar con moneda extranjera sin tipo de cambio',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    // Cambiar a BRL
    await tester.tap(find.byKey(const Key('currency-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-option-BRL')));
    await tester.pumpAndSettle();

    // Completar descripción y monto 90
    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Almuerzo en Florianópolis',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '90',
    );
    await tester.pumpAndSettle();

    // Advertencia visible (Imagen 1)
    expect(find.text('Falta el tipo de cambio'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);

    // Botón Guardar gasto deshabilitado
    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
  });

  testWidgets(
      'permite configurar el tipo de cambio y guarda el gasto convertido a pesos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    // Cambiar a BRL
    await tester.tap(find.byKey(const Key('currency-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-option-BRL')));
    await tester.pumpAndSettle();

    // Ingresar datos
    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Caipirinhas',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '90',
    );
    await tester.pumpAndSettle();

    // Tocar 'Ingresar' tipo de cambio
    await tester.tap(find.byKey(const Key('enter-exchange-rate-button')));
    await tester.pumpAndSettle();

    // Modal de Tipo de cambio (Imagen 4)
    expect(find.text('Tipo de cambio'), findsOneWidget);
    expect(
      find.text(
        'Indicá cuántos pesos (ARS) valía 1 real brasileño (BRL) cuando pagaste.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 R\$ ='), findsOneWidget);
    expect(find.text('Pesos (ARS)'), findsOneWidget);

    // Escribir cotización 200
    await tester.enterText(
      find.byKey(const Key('exchange-rate-input-field')),
      '200',
    );
    await tester.pumpAndSettle();

    // Ver preview: R$ 90,00 ≈ $ 18.000,00
    expect(find.text('R\$ 90,00 ≈ \$ 18.000,00'), findsOneWidget);

    // Guardar tipo de cambio
    await tester.tap(find.byKey(const Key('save-exchange-rate-button')));
    await tester.pumpAndSettle();

    // Fila de resumen en la pantalla principal (Imagen 2)
    expect(find.text('≈ \$ 18.000'), findsOneWidget);
    expect(find.text(' en pesos (ARS)'), findsOneWidget);
    expect(find.text('1 R\$ = \$ 200'), findsOneWidget);

    // Guardar gasto ahora habilitado
    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verificar persistencia: guardado con tipo de cambio y monto convertido
    final saved = (await repository.getAll()).single.expenses.single;
    expect(saved.description, 'Caipirinhas');
    expect(saved.originalCurrency.code, 'BRL');
    expect(saved.referenceCurrency.code, 'ARS');
    expect(saved.exchangeRate, 200.0);
    expect(saved.originalAmount.decimalValue, 90.0);
    expect(saved.amount, 18000.0); // Converted in reference currency
    expect(saved.convertedAmount.decimalValue, 18000.0);
  });

  testWidgets('permite cambiar la modalidad de división abriendo Dividir gasto',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    // Completar descripción y monto
    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Cena en la playa',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '120.000',
    );
    await tester.pumpAndSettle();

    // Tocar Cambiar forma de dividir
    await tester.tap(find.byKey(const Key('change-split-type-button')));
    await tester.pumpAndSettle();

    // Abre pantalla Dividir gasto
    expect(find.text('Dividir gasto'), findsOneWidget);
    expect(find.text('¿Cómo se divide?'), findsOneWidget);

    // Cambiar a Montos
    await tester.tap(find.byKey(const Key('tab-split-amounts')));
    await tester.pumpAndSettle();

    // Confirmar
    await tester.tap(find.byKey(const Key('split-expense-confirm-button')));
    await tester.pumpAndSettle();

    // Regresa a Crear gasto con la modalidad actualizada
    expect(find.text('Dividilo por montos exactos'), findsOneWidget);
  });

  testWidgets(
      'al editar conserva el aporte de cada pagador en un gasto multidivisa',
      (tester) async {
    setTestSize(tester);
    final ana = group.members[0];
    final marco = group.members[1];
    final expense = Expense(
      id: 'expense-multi',
      description: 'Hotel en dólares',
      amount: 100000,
      originalAmount: Money.fromString('100', Currency.usd),
      originalCurrency: Currency.usd,
      convertedAmount: Money.fromString('100000', Currency.ars),
      referenceCurrency: Currency.ars,
      exchangeRate: 1000,
      payers: [
        ExpensePayer(
          person: ana,
          amount: Money.fromString('60', Currency.usd),
        ),
        ExpensePayer(
          person: marco,
          amount: Money.fromString('40', Currency.usd),
        ),
      ],
      participants: [ana, marco],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CreateExpenseScreen(
          repository: repository,
          group: group,
          initialExpense: expense,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = (await repository.getAll()).single.expenses.single;
    final amountsByPerson = {
      for (final payer in saved.payers) payer.person.name: payer.amount,
    };
    expect(amountsByPerson['Ana']!.decimalValue, 60);
    expect(amountsByPerson['Marco']!.decimalValue, 40);
    expect(amountsByPerson['Ana']!.currency, Currency.usd);
  });

  testWidgets('guarda la fecha de hoy por defecto al crear un gasto',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(group));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Cena',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '1000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    final saved = (await repository.getAll()).single.expenses.single;
    final now = DateTime.now();
    expect(saved.date.year, now.year);
    expect(saved.date.month, now.month);
    expect(saved.date.day, now.day);
  });

  testWidgets('al editar conserva la fecha original del gasto', (tester) async {
    setTestSize(tester);
    final originalDate = DateTime(2026, 1, 10);
    final ana = group.members[0];
    final expense = Expense(
      id: 'expense-date',
      description: 'Cena vieja',
      amount: 5000,
      date: originalDate,
      payer: ana,
      participants: [ana],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CreateExpenseScreen(
          repository: repository,
          group: group,
          initialExpense: expense,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10 de enero de 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    final saved = (await repository.getAll()).single.expenses.single;
    expect(saved.date, originalDate);
  });

  testWidgets('permite elegir otra fecha con el selector', (tester) async {
    setTestSize(tester);
    final ana = group.members[0];
    final expense = Expense(
      id: 'expense-date-2',
      description: 'Cena vieja',
      amount: 5000,
      date: DateTime(2026, 1, 10),
      payer: ana,
      participants: [ana],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CreateExpenseScreen(
          repository: repository,
          group: group,
          initialExpense: expense,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('expense-date-button')));
    await tester.pumpAndSettle();

    expect(find.text('Elegí la fecha del gasto'), findsOneWidget);
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('20 de enero de 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    final saved = (await repository.getAll()).single.expenses.single;
    expect(saved.date.year, 2026);
    expect(saved.date.month, 1);
    expect(saved.date.day, 20);
  });

  testWidgets(
      'recuerda y sugiere automáticamente la última cotización usada para la misma moneda en el grupo',
      (tester) async {
    final groupWithPreviousBrl = group.copyWith(
      expenses: [
        Expense(
          description: 'Cena anterior',
          amount: 40000.0,
          originalAmount: Money.fromDecimal(200.0, Currency.brl),
          originalCurrency: Currency.brl,
          referenceCurrency: Currency.ars,
          exchangeRate: 200.0,
          payer: group.members.first,
          participants: group.members,
        ),
      ],
    );

    setTestSize(tester);
    await tester.pumpWidget(buildScreen(groupWithPreviousBrl));
    await tester.pumpAndSettle();

    // Cambiar a BRL
    await tester.tap(find.byKey(const Key('currency-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-option-BRL')));
    await tester.pumpAndSettle();

    // Completar descripción y monto
    await tester.enterText(
      find.byKey(const Key('expense-description-field')),
      'Supermercado en Brasil',
    );
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '100',
    );
    await tester.pumpAndSettle();

    // Ya no debe decir "Falta el tipo de cambio", sino mostrar la equivalencia sugerida con $ 200
    expect(find.text('Falta el tipo de cambio'), findsNothing);
    expect(find.text('≈ \$ 20.000'), findsOneWidget);
    expect(find.text('1 R\$ = \$ 200'), findsOneWidget);

    // Y el botón Guardar gasto ya debe estar habilitado directamente
    final saveButton = find.byKey(const Key('save-expense-button'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    // Al abrir el modal de tipo de cambio, muestra la pista de cotización sugerida
    await tester.tap(find.byKey(const Key('exchange-rate-banner')));
    await tester.pumpAndSettle();
    expect(
      find.text('Última cotización en este grupo: \$ 200'),
      findsOneWidget,
    );
  });
}
