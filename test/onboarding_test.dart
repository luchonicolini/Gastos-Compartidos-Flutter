import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/data/database/app_database.dart';
import 'package:gastos_compartidos/features/onboarding/data/onboarding_status_store.dart';
import 'package:gastos_compartidos/main.dart';

class _MemoryStatusStore implements OnboardingStatusStore {
  bool completed = false;

  @override
  Future<bool> isComplete() async => completed;

  @override
  Future<void> markComplete() async => completed = true;
}

void main() {
  testWidgets('muestra cuatro pasos y recuerda cuando se completan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final store = _MemoryStatusStore();
    await tester.pumpWidget(
      GastosCompartidosApp(database: database, onboardingStore: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('¿Quién pagó qué?'), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 1 de 4'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Dividí a tu manera'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Viajá con distintas monedas'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Terminá con las cuentas claras'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(store.completed, isTrue);
    expect(find.text('Empezá tu próximo viaje'), findsOneWidget);
    await tester.pumpWidget(
      GastosCompartidosApp(database: database, onboardingStore: store),
    );
    await tester.pumpAndSettle();
    expect(find.text('¿Quién pagó qué?'), findsNothing);
  });

  testWidgets('Saltar completa el onboarding desde el primer paso', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final store = _MemoryStatusStore();
    await tester.pumpWidget(
      GastosCompartidosApp(database: database, onboardingStore: store),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(store.completed, isTrue);
    expect(find.text('Empezá tu próximo viaje'), findsOneWidget);
  });
}
