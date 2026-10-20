import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as db;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/features/members/presentation/add_members_screen.dart';

void main() {
  late db.AppDatabase database;
  late LocalGroupRepository repository;
  late Group group;

  setUp(() async {
    database = db.AppDatabase.inMemory();
    repository = LocalGroupRepository(database);

    group = Group(
      name: 'Viaje Bariloche',
      referenceCurrency: Currency.ars,
      members: [Person(name: 'Pedro')],
    );
    await repository.save(group);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets(
      'muestra sugerencia si se intenta agregar un nombre repetido y permite usarla',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AddMembersScreen(
          repository: repository,
          group: group,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El grupo ya tiene a Pedro
    expect(find.text('Pedro'), findsOneWidget);

    // Escribir "Pedro" de nuevo
    await tester.enterText(find.byKey(const Key('member-name-field')), 'Pedro');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();

    // Debe aparecer la sugerencia "Pedro (2)"
    expect(
      find.text('Ya existe en el grupo. Sugerencia: "Pedro (2)"'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('apply-suggested-name-add-screen-button')),
      findsOneWidget,
    );

    // Tocar "Usar"
    await tester.tap(
      find.byKey(const Key('apply-suggested-name-add-screen-button')),
    );
    await tester.pumpAndSettle();

    // El campo de texto ahora contiene "Pedro (2)"
    expect(find.text('Pedro (2)'), findsOneWidget);

    // Presionar agregar
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();

    // Ahora hay ambos en la lista
    expect(find.text('Pedro'), findsOneWidget);
    expect(find.text('Pedro (2)'), findsOneWidget);
  });

  testWidgets(
      'mantiene el badge Vos en el primer integrante aunque otro nombre ordene antes',
      (tester) async {
    final emptyGroup = Group(
      name: 'Grupo Nuevo',
      referenceCurrency: Currency.ars,
      members: [],
    );
    await repository.save(emptyGroup);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AddMembersScreen(
          repository: repository,
          group: emptyGroup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Debe mostrar guía inicial de Vos
    expect(find.text('Tu nombre (Vos)'), findsOneWidget);
    expect(
      find.text('Ingresá tu nombre primero para identificarte en este grupo.'),
      findsOneWidget,
    );

    // Agregar primera persona "Luciano"
    await tester.enterText(
        find.byKey(const Key('member-name-field')), 'Luciano');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();

    // Luciano ahora tiene badge Vos
    expect(find.text('Luciano'), findsOneWidget);
    expect(find.text('Vos'), findsOneWidget);

    // El campo ahora pide "Nombre de la persona"
    expect(find.text('Nombre de la persona'), findsOneWidget);

    // Agregar segunda persona "Lucas"
    await tester.enterText(find.byKey(const Key('member-name-field')), 'Lucas');
    await tester.tap(find.byKey(const Key('add-member')));
    await tester.pumpAndSettle();

    expect(find.text('Lucas'), findsOneWidget);

    // "Lucas" ordena antes que "Luciano", pero el badge "Vos" debe seguir
    // en Luciano porque fue el primero en ingresar.
    expect(find.text('Vos'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Vos')).dy,
      closeTo(tester.getCenter(find.text('Luciano')).dy, 1),
    );
    expect(
      tester.getCenter(find.text('Vos')).dy,
      isNot(closeTo(tester.getCenter(find.text('Lucas')).dy, 1)),
    );
    expect(find.text('Soy yo'), findsNothing);
  });
}
