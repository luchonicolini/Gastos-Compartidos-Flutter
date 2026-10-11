import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/domain/models/split_type.dart';
import 'package:gastos_compartidos/features/expenses/presentation/split_expense_screen.dart';

void main() {
  final ana = Person(id: 'ana-id', name: 'Ana');
  final marco = Person(id: 'marco-id', name: 'Marco');
  final julia = Person(id: 'julia-id', name: 'Julia');
  final members = [ana, marco, julia];

  Widget buildScreen({
    String description = 'Cena en la playa',
    double totalAmount = 120000.0,
    Map<String, double>? initialPayers,
    SplitType initialSplitType = SplitType.equally,
    Map<String, double>? initialSplitDetails,
    Set<String>? initialParticipantIds,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: SplitExpenseScreen(
        description: description,
        totalAmount: totalAmount,
        currency: Currency.ars,
        members: members,
        initialPayers: initialPayers ??
            {
              ana.id: 80000.0,
              marco.id: 40000.0,
              julia.id: 0.0,
            },
        initialSplitType: initialSplitType,
        initialSplitDetails: initialSplitDetails,
        initialParticipantIds: initialParticipantIds,
      ),
    );
  }

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets(
      'Imagen 1: reproduce vista con ¿Quién pagó? y modalidad Igual',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Cena en la playa · \$120.000'), findsOneWidget);
    expect(find.text('Dividir gasto'), findsOneWidget);

    // Sección 1: ¿Quién pagó?
    expect(find.text('¿Quién pagó?'), findsOneWidget);
    expect(
      find.text('Marcá a quienes pusieron plata e indicá cuánto.'),
      findsOneWidget,
    );
    expect(find.text('\$ 80.000'), findsOneWidget); // Pill de Ana
    expect(find.text('\$ 40.000'), findsOneWidget); // Pill de Marco
    expect(find.text('\$40.000'), findsNWidgets(3)); // 3 participantes en Igual
    expect(find.text('\$ 0'), findsOneWidget); // Pill de Julia
    expect(find.text('Suma \$120.000 de \$120.000'), findsOneWidget);

    // Sección 2: ¿Cómo se divide?
    expect(find.text('¿Cómo se divide?'), findsOneWidget);
    expect(find.text('Igual'), findsOneWidget);
    expect(find.text('Montos'), findsOneWidget);
    expect(find.text('%'), findsOneWidget);
    expect(find.text('Partes'), findsOneWidget);

    // En modalidad Igual: cada persona paga $40.000
    expect(find.text('Cada persona paga \$40.000'), findsOneWidget);

    // Botón Listo habilitado
    final submitButtonFinder =
        find.byKey(const Key('split-expense-confirm-button'));
    expect(submitButtonFinder, findsOneWidget);
    final submitButton = tester.widget<FilledButton>(submitButtonFinder);
    expect(submitButton.onPressed, isNotNull);
  });

  testWidgets(
      'Imagen 2: reproduce pestaña % con porcentajes y montos calculados',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      buildScreen(
        initialSplitType: SplitType.byPercentage,
        initialSplitDetails: {
          ana.id: 50.0,
          marco.id: 30.0,
          julia.id: 20.0,
        },
      ),
    );
    await tester.pumpAndSettle();

    // Porcentajes en los pills
    expect(find.text('50 %'), findsOneWidget);
    expect(find.text('30 %'), findsOneWidget);
    expect(find.text('20 %'), findsOneWidget);

    // Subtítulos calculados debajo de los nombres
    expect(find.text('\$60.000'), findsOneWidget); // 50% de 120.000
    expect(find.text('\$36.000'), findsOneWidget); // 30% de 120.000
    expect(find.text('\$24.000'), findsOneWidget); // 20% de 120.000

    // Verificación de suma 100%
    expect(find.text('Suma 100 %'), findsOneWidget);

    // Botón Listo habilitado
    final submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('split-expense-confirm-button')),
    );
    expect(submitButton.onPressed, isNotNull);
  });

  testWidgets(
      'Imagen 3: reproduce pestaña Montos con faltante y botón Listo deshabilitado',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      buildScreen(
        initialSplitType: SplitType.byAmount,
        initialSplitDetails: {
          ana.id: 50000.0,
          marco.id: 40000.0,
          julia.id: 20000.0, // Suma 110.000 (faltan 10.000)
        },
      ),
    );
    await tester.pumpAndSettle();

    // Montos en los pills de división
    expect(find.text('\$ 50.000'), findsOneWidget);
    expect(find.text('\$ 20.000'), findsOneWidget);

    // Alerta de faltante
    expect(
      find.text('Faltan \$10.000 para llegar a \$120.000'),
      findsOneWidget,
    );

    // Botón Listo deshabilitado (null onPressed)
    final submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('split-expense-confirm-button')),
    );
    expect(submitButton.onPressed, isNull);
  });

  testWidgets(
      'Imagen 4: reproduce pestaña Partes con steppers y valor por parte',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      buildScreen(
        initialSplitType: SplitType.byShares,
        initialSplitDetails: {
          ana.id: 2.0,
          marco.id: 1.0,
          julia.id: 1.0,
        },
      ),
    );
    await tester.pumpAndSettle();

    // Valores en los steppers
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));

    // Subtítulos calculados (4 partes en total: $30.000 por parte)
    expect(find.text('\$60.000'), findsOneWidget); // 2 partes = 60.000
    expect(find.text('\$30.000'), findsNWidgets(2)); // 1 parte = 30.000 c/u

    // Leyenda de resumen
    expect(
      find.text('4 partes · cada parte vale \$30.000'),
      findsOneWidget,
    );

    // Botón Listo habilitado
    final submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('split-expense-confirm-button')),
    );
    expect(submitButton.onPressed, isNotNull);
  });

  testWidgets(
      'permite alternar tabs de división y ajustar valores dinámicamente',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Inicia en Igual
    expect(find.text('Cada persona paga \$40.000'), findsOneWidget);

    // Cambiar a pestaña Montos
    await tester.tap(find.byKey(const Key('tab-split-amounts')));
    await tester.pumpAndSettle();

    // Inicialmente los montos se auto-reparten a 40.000 c/u (suma 120.000)
    expect(find.text('Suma \$120.000 de \$120.000'), findsNWidgets(2));

    // Cambiar a pestaña Partes
    await tester.tap(find.byKey(const Key('tab-split-shares')));
    await tester.pumpAndSettle();

    // Incrementar partes de Ana con el botón plus
    await tester.tap(find.byKey(Key('shares-plus-${ana.id}')));
    await tester.pumpAndSettle();

    // Ahora Ana tiene 2 partes, Marco 1, Julia 1 = 4 partes
    expect(find.text('4 partes · cada parte vale \$30.000'), findsOneWidget);
  });

  testWidgets(
      'tocar Listo devuelve SplitExpenseResult con los datos configurados',
      (tester) async {
    setTestSize(tester);

    SplitExpenseResult? capturedResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    capturedResult =
                        await Navigator.of(context).push<SplitExpenseResult>(
                      MaterialPageRoute(
                        builder: (_) => SplitExpenseScreen(
                          description: 'Cena en la playa',
                          totalAmount: 120000.0,
                          currency: Currency.ars,
                          members: members,
                          initialPayers: {
                            ana.id: 80000.0,
                            marco.id: 40000.0,
                            julia.id: 0.0,
                          },
                          initialSplitType: SplitType.byShares,
                          initialSplitDetails: {
                            ana.id: 2.0,
                            marco.id: 1.0,
                            julia.id: 1.0,
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    // Confirmar en pantalla Dividir gasto
    await tester.tap(find.byKey(const Key('split-expense-confirm-button')));
    await tester.pumpAndSettle();

    expect(capturedResult, isNotNull);
    expect(capturedResult!.payerAmounts[ana.id], 80000.0);
    expect(capturedResult!.payerAmounts[marco.id], 40000.0);
    expect(capturedResult!.splitType, SplitType.byShares);
    expect(capturedResult!.splitDetails[ana.id], 2.0);
    expect(capturedResult!.splitDetails[marco.id], 1.0);
    expect(capturedResult!.participantIds, hasLength(3));
  });
}
