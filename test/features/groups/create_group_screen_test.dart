import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as db;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/features/groups/presentation/create_group_screen.dart';

void main() {
  late db.AppDatabase database;
  late LocalGroupRepository repository;

  setUp(() async {
    database = db.AppDatabase.inMemory();
    repository = LocalGroupRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildScreen({bool hasExistingGroups = true}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            key: const Key('open-create-group'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateGroupScreen(
                  repository: repository,
                  hasExistingGroups: hasExistingGroups,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'no queda con spinner infinito al volver hacia atras desde Quienes participan',
      (tester) async {
    await tester.pumpWidget(buildScreen(hasExistingGroups: true));
    await tester.pumpAndSettle();

    // Abrir CreateGroupScreen
    await tester.tap(find.byKey(const Key('open-create-group')));
    await tester.pumpAndSettle();

    // Escribir nombre del grupo
    await tester.enterText(find.byType(TextField), 'Viaje Bariloche');
    await tester.pumpAndSettle();

    // Presionar Continuar
    await tester.tap(find.byKey(const Key('continue-create-group')));
    await tester.pumpAndSettle();

    // Estamos en la pantalla "¿Quiénes participan?"
    expect(find.text('¿Quiénes participan?'), findsOneWidget);

    // Tocar el botón de volver (arrow_back_rounded)
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    // Regresamos a la pantalla "Crear grupo"
    expect(find.text('Crear grupo'), findsOneWidget);
    expect(find.text('¿Cómo se llama el grupo?'), findsOneWidget);

    // El botón NO debe tener el CircularProgressIndicator y debe decir 'Continuar'
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Continuar'), findsOneWidget);

    // Si modificamos el nombre y volvemos a presionar Continuar
    await tester.enterText(find.byType(TextField), 'Viaje Bariloche 2026');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('continue-create-group')));
    await tester.pumpAndSettle();

    // Vuelve a abrirse Quiénes participan
    expect(find.text('¿Quiénes participan?'), findsOneWidget);

    // En la base de datos debe haber UN SOLO grupo con el nombre actualizado, no dos
    final allGroups = await repository.getAll();
    expect(allGroups.length, 1);
    expect(allGroups.first.name, 'Viaje Bariloche 2026');
  });

  testWidgets('limpia el grupo borrador si el usuario cancela y vuelve a Mis grupos',
      (tester) async {
    await tester.pumpWidget(buildScreen(hasExistingGroups: true));
    await tester.pumpAndSettle();

    // Abrir CreateGroupScreen
    await tester.tap(find.byKey(const Key('open-create-group')));
    await tester.pumpAndSettle();

    // Escribir nombre del grupo
    await tester.enterText(find.byType(TextField), 'Grupo Cancelado');
    await tester.pumpAndSettle();

    // Presionar Continuar
    await tester.tap(find.byKey(const Key('continue-create-group')));
    await tester.pumpAndSettle();

    // Volver desde Quiénes participan
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    // Ahora salir de Crear grupo presionando volver a Mis grupos
    await tester.tap(find.byKey(const Key('create-group-back-button')));
    await tester.pumpAndSettle();

    // Estamos de nuevo en la pantalla inicial previa
    expect(find.byKey(const Key('open-create-group')), findsOneWidget);

    // El grupo no debe quedar guardado como basura en la base de datos
    final allGroups = await repository.getAll();
    expect(allGroups, isEmpty);
  });
}
