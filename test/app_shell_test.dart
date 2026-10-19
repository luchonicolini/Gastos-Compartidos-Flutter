import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as database;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/features/onboarding/data/onboarding_status_store.dart';
import 'package:gastos_compartidos/main.dart';

class _CompletedOnboarding implements OnboardingStatusStore {
  @override
  Future<bool> isComplete() async => true;

  @override
  Future<void> markComplete() async {}

  @override
  Future<void> reset() async {}
}

void main() {
  testWidgets('la app arranca y lee los grupos locales', (tester) async {
    final appDatabase = database.AppDatabase.inMemory();
    addTearDown(appDatabase.close);
    await LocalGroupRepository(appDatabase).save(Group(name: 'Viaje guardado'));

    await tester.pumpWidget(
      GastosCompartidosApp(
        database: appDatabase,
        onboardingStore: _CompletedOnboarding(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Tus grupos y gastos compartidos.'), findsOneWidget);
    expect(find.text('Viaje guardado'), findsOneWidget);
    expect(find.text('Crear un nuevo grupo'), findsOneWidget);
    expect(find.text('Ver grupos finalizados'), findsOneWidget);
  });

  testWidgets('muestra una guía cuando todavía no hay grupos', (tester) async {
    final appDatabase = database.AppDatabase.inMemory();
    addTearDown(appDatabase.close);

    await tester.pumpWidget(
      GastosCompartidosApp(
        database: appDatabase,
        onboardingStore: _CompletedOnboarding(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Creá tu primer grupo'), findsOneWidget);
    expect(find.text('Crear mi primer grupo'), findsOneWidget);
  });

  testWidgets('usa siempre el tema claro y no define tema oscuro',
      (tester) async {
    final appDatabase = database.AppDatabase.inMemory();
    addTearDown(appDatabase.close);

    await tester.pumpWidget(
      GastosCompartidosApp(
        database: appDatabase,
        onboardingStore: _CompletedOnboarding(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.darkTheme, isNull);
  });

  testWidgets('crea el primer grupo con su estilo elegido', (tester) async {
    final appDatabase = database.AppDatabase.inMemory();
    addTearDown(appDatabase.close);
    final repository = LocalGroupRepository(appDatabase);

    await tester.pumpWidget(
      GastosCompartidosApp(
        database: appDatabase,
        onboardingStore: _CompletedOnboarding(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi primer grupo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo se llama el grupo?'), findsOneWidget);

    final continueButton = find.byKey(const Key('continue-create-group'));
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Brasil 2026');
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    final colorFinder = find.bySemanticsLabel('Color #C6500A');
    await tester.ensureVisible(colorFinder);
    await tester.tap(colorFinder);

    final iconFinder = find.bySemanticsLabel('Ícono beach');
    await tester.ensureVisible(iconFinder);
    await tester.tap(iconFinder);

    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    final groups = await repository.getAll();
    expect(groups, hasLength(1));
    expect(groups.single.name, 'Brasil 2026');
    expect(groups.single.iconName, 'beach');
    expect(groups.single.colorHex, '#C6500A');
    expect(find.text('¿Quiénes participan?'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('member-name-field')), 'Ana');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();

    expect(find.text('Integrantes'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('continue-to-expenses')))
          .onPressed,
      isNotNull,
    );
    expect((await repository.getAll()).single.members.single.name, 'Ana');
  });
}
