// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gastos_compartidos/main.dart';

void main() {
  testWidgets('muestra el grupo de demostración inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const GastosCompartidosApp());

    expect(find.text('Mis Grupos'), findsOneWidget);
    expect(find.text('Viaje a la Costa'), findsOneWidget);
    expect(find.text('3 miembros • 1 gastos'), findsOneWidget);
    expect(find.text('2 pago(s) pendiente(s)'), findsOneWidget);
  });

  testWidgets('abre el detalle del grupo al tocarlo', (WidgetTester tester) async {
    await tester.pumpWidget(const GastosCompartidosApp());
    await tester.tap(find.text('Viaje a la Costa'));
    await tester.pumpAndSettle();

    expect(find.text('Pagos Sugeridos para Liquidar'), findsOneWidget);
    expect(find.text('Ana paga a Luciano'), findsOneWidget);
  });
}
