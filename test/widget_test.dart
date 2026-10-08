import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:gastos_compartidos/data/database/app_database.dart';
import 'package:gastos_compartidos/main.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('muestra el estado vacío cuando no existen grupos', (tester) async {
    await tester.pumpWidget(GastosCompartidosApp(database: database));
    await tester.pumpAndSettle();

    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Todavía no tenés grupos'), findsOneWidget);
    expect(find.text('Crear mi primer grupo'), findsOneWidget);
  });

  testWidgets('crea un grupo y abre su detalle', (tester) async {
    await tester.pumpWidget(GastosCompartidosApp(database: database));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi primer grupo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Viaje a la Costa');
    await tester.tap(find.text('Crear grupo'));
    await tester.pumpAndSettle();

    expect(find.text('Viaje a la Costa'), findsOneWidget);
    expect(find.text('0 miembros'), findsOneWidget);

    await tester.tap(find.text('Viaje a la Costa'));
    await tester.pumpAndSettle();

    expect(find.text('Miembros'), findsOneWidget);

    await tester.tap(find.text('Agregar miembro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Luciano');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Luciano'), findsOneWidget);
    expect(find.text('1 activos'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar gasto'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Cena');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Cena'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);
  });
}
