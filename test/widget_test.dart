import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/expense.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/main.dart';

void main() {
  late database.AppDatabase appDatabase;

  setUp(() {
    appDatabase = database.AppDatabase.inMemory();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  testWidgets('muestra el estado vacío cuando no existen grupos', (
    tester,
  ) async {
    await tester.pumpWidget(GastosCompartidosApp(database: appDatabase));
    await tester.pumpAndSettle();

    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Todavía no tenés grupos'), findsOneWidget);
    expect(find.text('Crear mi primer grupo'), findsOneWidget);
  });

  testWidgets('crea un grupo y abre su detalle', (tester) async {
    await tester.pumpWidget(GastosCompartidosApp(database: appDatabase));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi primer grupo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('group-name-field')),
      'Viaje a la Costa',
    );
    await tester.tap(find.text('Crear grupo'));
    await tester.pumpAndSettle();

    expect(find.text('Viaje a la Costa'), findsOneWidget);
    expect(find.text('0 miembros'), findsOneWidget);

    await tester.tap(find.text('Viaje a la Costa'));
    await tester.pumpAndSettle();

    expect(find.text('Miembros'), findsOneWidget);

    await tester.tap(find.text('Agregar miembro'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('member-name-field')),
      'Luciano',
    );
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Luciano'), findsOneWidget);
    expect(find.text('1 activos'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar gasto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense-description-field')),
      'Cena',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense-amount-field')),
      '100',
    );
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Cena', skipOffstage: false), findsOneWidget);
    expect(find.text(r'$100.00', skipOffstage: false), findsOneWidget);
  });

  testWidgets('muestra y confirma una liquidación sugerida', (tester) async {
    final luciano = Person(id: 'balance-1', name: 'Luciano');
    final ana = Person(id: 'balance-2', name: 'Ana');
    await LocalGroupRepository(appDatabase).save(
      Group(
        id: 'balance-group',
        name: 'Viaje saldable',
        members: [luciano, ana],
        expenses: [
          Expense(
            description: 'Hotel',
            amount: 100,
            payer: luciano,
            participants: [luciano, ana],
          ),
        ],
      ),
    );

    await tester.pumpWidget(GastosCompartidosApp(database: appDatabase));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viaje saldable'));
    await tester.pumpAndSettle();

    expect(find.text('Pagos sugeridos'), findsOneWidget);
    expect(find.text('Ana → Luciano'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar').last);
    await tester.pumpAndSettle();

    expect(find.text('Pagos registrados'), findsOneWidget);
    expect(find.text('Viaje saldado'), findsOneWidget);
  });
}
