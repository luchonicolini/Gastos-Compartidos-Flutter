import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/data/database/app_database.dart' as db;
import 'package:gastos_compartidos/data/repositories/local_group_repository.dart';
import 'package:gastos_compartidos/domain/models/currency.dart';
import 'package:gastos_compartidos/domain/models/group.dart';
import 'package:gastos_compartidos/domain/models/person.dart';
import 'package:gastos_compartidos/features/groups/presentation/group_detail_screen.dart';
import 'package:gastos_compartidos/features/members/presentation/group_members_screen.dart';
import 'package:gastos_compartidos/data/preferences/self_member_store.dart';

void main() {
  late db.AppDatabase database;
  late LocalGroupRepository repository;
  late Person ana;
  late Person marco;
  late Person julia;
  late Person sofia;
  late Group sampleGroup;
  late Group emptyMembersGroup;

  setUp(() async {
    database = db.AppDatabase.inMemory();
    repository = LocalGroupRepository(database);

    ana = Person(name: 'Ana');
    marco = Person(name: 'Marco');
    julia = Person(name: 'Julia');
    sofia = Person(name: 'Sofía', isArchived: true);

    sampleGroup = Group(
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [ana, marco, julia, sofia],
    );

    emptyMembersGroup = Group(
      name: 'Brasil 2026',
      iconName: 'flight',
      colorHex: '#0D7E88',
      referenceCurrency: Currency.ars,
      members: [],
    );

    await repository.save(sampleGroup);
    await repository.save(emptyMembersGroup);
  });

  tearDown(() async {
    await database.close();
  });

  void setTestSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget buildScreen(Group group) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: GroupMembersScreen(
        group: group,
        repository: repository,
      ),
    );
  }

  testWidgets(
      'muestra vista de Personas con integrantes activos y archivados fiel a Imagen 1',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Top Navigation
    expect(find.text('Brasil 2026'), findsOneWidget);
    expect(find.text('Personas'), findsNWidgets(2)); // Header y Bottom Nav
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);

    // Título y subtítulo
    expect(find.text('¿Quiénes participan?'), findsOneWidget);
    expect(
      find.text('Administrá las personas que comparten\ngastos en este grupo.'),
      findsOneWidget,
    );
    expect(find.text('3 personas activas'), findsOneWidget);

    // Miembros activos
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Vos'), findsOneWidget); // Badge Vos en el primer miembro
    expect(find.text('Marco'), findsOneWidget);
    expect(find.text('Julia'), findsOneWidget);

    // Sección de archivadas
    expect(find.text('Archivadas'), findsOneWidget);
    expect(find.text('No participan de gastos nuevos.'), findsOneWidget);
    expect(find.text('Sofía'), findsOneWidget);
    expect(find.text('Archivada'), findsOneWidget);
    expect(find.text('Reactivar'), findsOneWidget);

    // Botón principal
    expect(find.byKey(const Key('add-person-button')), findsOneWidget);
    expect(find.text('Agregar persona'), findsOneWidget);

    // Bottom Navigation Bar tabs
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
  });

  testWidgets(
      'muestra estado vacío de Personas fiel a Imagen 2 cuando hay 0 miembros',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(emptyMembersGroup));
    await tester.pumpAndSettle();

    // Contador en 0
    expect(find.text('0 personas activas'), findsOneWidget);

    // Ilustración y texto central del estado vacío
    expect(
      find.text('Sumá a las personas que van a compartir gastos.'),
      findsOneWidget,
    );

    // Botón de agregar persona disponible
    expect(find.byKey(const Key('add-person-button')), findsOneWidget);
  });

  testWidgets(
      'menú de tres puntos abre opciones y permite archivar miembro con confirmación (Imágenes 3 y 4)',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Abrir menú de 3 puntos de Marco
    final marcoMenu = find.byKey(Key('member-menu-${marco.id}'));
    expect(marcoMenu, findsOneWidget);
    await tester.tap(marcoMenu);
    await tester.pumpAndSettle();

    // Opciones del menú (Imagen 4)
    expect(find.text('Editar nombre'), findsOneWidget);
    expect(find.text('Archivar persona'), findsOneWidget);

    // Tocar "Archivar persona"
    await tester.tap(find.text('Archivar persona'));
    await tester.pumpAndSettle();

    // Diálogo modal de confirmación (Imagen 3)
    expect(find.text('¿Archivar a Marco?'), findsOneWidget);
    expect(
      find.text(
        'No aparecerá al cargar gastos nuevos, pero sus cuentas anteriores se conservarán.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cancel-archive-button')), findsOneWidget);
    expect(find.byKey(const Key('confirm-archive-button')), findsOneWidget);

    // Confirmar archivado
    await tester.tap(find.byKey(const Key('confirm-archive-button')));
    await tester.pumpAndSettle();

    // Marco ahora está archivado
    expect(find.text('2 personas activas'), findsOneWidget);
    expect(find.text('Marco'), findsOneWidget);
    expect(find.text('Archivada'), findsNWidgets(2)); // Sofía y Marco
  });

  testWidgets('permite reactivar un miembro archivado', (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    expect(find.text('3 personas activas'), findsOneWidget);

    // Reactivar a Sofía
    final reactivateSofia = find.byKey(Key('reactivate-member-${sofia.id}'));
    expect(reactivateSofia, findsOneWidget);
    await tester.tap(reactivateSofia);
    await tester.pumpAndSettle();

    // Ahora hay 4 activas y no hay archivadas
    expect(find.text('4 personas activas'), findsOneWidget);
    expect(find.text('Sofía'), findsOneWidget);
    expect(find.text('Archivadas'), findsNothing);
  });

  testWidgets('permite editar el nombre de un integrante', (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Abrir menú de Julia
    await tester.tap(find.byKey(Key('member-menu-${julia.id}')));
    await tester.pumpAndSettle();

    // Tocar "Editar nombre"
    await tester.tap(find.text('Editar nombre'));
    await tester.pumpAndSettle();

    expect(find.text('Editar nombre'), findsOneWidget);

    // Modificar nombre
    await tester.enterText(find.byKey(const Key('edit-name-field')), 'Julieta');
    await tester.tap(find.byKey(const Key('save-name-button')));
    await tester.pumpAndSettle();

    // Julia ahora se llama Julieta
    expect(find.text('Julieta'), findsOneWidget);
    expect(find.text('Julia'), findsNothing);
  });

  testWidgets('permite agregar una persona desde el botón principal',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Tocar "+ Agregar persona"
    await tester.tap(find.byKey(const Key('add-person-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Sumá a una persona que comparta gastos en este grupo.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirm-add-person-button')), findsOneWidget);

    // Escribir nombre y guardar
    await tester.enterText(
        find.byKey(const Key('add-person-name-field')), 'Lucas');
    await tester.tap(find.byKey(const Key('confirm-add-person-button')));
    await tester.pumpAndSettle();

    // Lucas ahora está en la lista activa
    expect(find.text('Lucas'), findsOneWidget);
    expect(find.text('4 personas activas'), findsOneWidget);
  });

  testWidgets('navega fluidamente entre pestañas Gastos y Personas',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GroupDetailScreen(
          group: sampleGroup,
          repository: repository,
          initialTab: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pestaña Gastos activa
    expect(find.text('Cargar gasto'), findsOneWidget);
    expect(find.text('Todos los gastos'), findsOneWidget);

    // Cambiar a Personas
    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();

    // Pestaña Personas activa
    expect(find.text('¿Quiénes participan?'), findsOneWidget);
    expect(find.text('Agregar persona'), findsOneWidget);

    // Volver a Gastos
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();

    expect(find.text('Cargar gasto'), findsOneWidget);
    expect(find.text('Todos los gastos'), findsOneWidget);
  });

  testWidgets(
      'deslizar miembro activo a la izquierda revela acciones de Editar y Archivar (Slidable)',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Deslizar tarjeta de Marco a la izquierda
    await tester.drag(find.text('Marco'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Las acciones de Slidable deben ser visibles
    expect(find.byKey(Key('slidable-edit-member-${marco.id}')), findsOneWidget);
    expect(find.byKey(Key('slidable-archive-member-${marco.id}')), findsOneWidget);
  });

  testWidgets(
      'sugiere alternativa numerada si se intenta agregar un nombre existente',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Tocar "+ Agregar persona"
    await tester.tap(find.byKey(const Key('add-person-button')));
    await tester.pumpAndSettle();

    // Ingresar "Ana" (que ya existe)
    await tester.enterText(
        find.byKey(const Key('add-person-name-field')), 'Ana');
    await tester.tap(find.byKey(const Key('confirm-add-person-button')));
    await tester.pumpAndSettle();

    // Debe mostrar el error y la sugerencia
    expect(find.text('Ya existe un miembro con ese nombre'), findsOneWidget);
    expect(find.text('Sugerencia: "Ana (2)"'), findsOneWidget);
    expect(
        find.byKey(const Key('apply-suggested-name-add-dialog-button')),
        findsOneWidget);

    // Tocar "Usar" para aplicar la sugerencia
    await tester.tap(
        find.byKey(const Key('apply-suggested-name-add-dialog-button')));
    await tester.pumpAndSettle();

    // El campo ahora tiene "Ana (2)" y no hay error
    expect(find.text('Ya existe un miembro con ese nombre'), findsNothing);
    expect(find.text('Ana (2)'), findsOneWidget);

    // Confirmar
    await tester.tap(find.byKey(const Key('confirm-add-person-button')));
    await tester.pumpAndSettle();

    // Ahora Ana (2) se agregó al grupo
    expect(find.text('Ana (2)'), findsOneWidget);
  });

  testWidgets(
      'sugiere alternativa si se intenta editar con un nombre existente',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Tocar tres puntos de Marco y Editar
    await tester.tap(find.byKey(Key('member-menu-${marco.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar nombre'));
    await tester.pumpAndSettle();

    // Cambiar por "Ana" (que ya existe)
    await tester.enterText(find.byKey(const Key('edit-name-field')), 'Ana');
    await tester.tap(find.byKey(const Key('save-name-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe un miembro con ese nombre'), findsOneWidget);
    expect(find.text('Sugerencia: "Ana (2)"'), findsOneWidget);
    expect(find.byKey(const Key('apply-suggested-name-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apply-suggested-name-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ana (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-name-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ana (2)'), findsOneWidget);
  });

  testWidgets(
      'permite marcar a otra persona como Vos desde el menú de 3 puntos',
      (tester) async {
    setTestSize(tester);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Inicialmente Ana es la primera y tiene el badge "Vos"
    expect(find.text('Vos'), findsOneWidget);

    // Abrir menú de Marco (segundo integrante)
    await tester.tap(find.byKey(Key('member-menu-${marco.id}')));
    await tester.pumpAndSettle();

    // Debe mostrar la opción "Marcar como 'Vos'"
    expect(find.text('Marcar como "Vos"'), findsOneWidget);

    // Tocar "Marcar como 'Vos'"
    await tester.tap(find.text('Marcar como "Vos"'));
    await tester.pumpAndSettle();

    // El badge "Vos" sigue presente (ahora en Marco)
    expect(find.text('Vos'), findsOneWidget);
    expect(
      find.text('Ahora Marco figura como "Vos" en este grupo.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'al archivar a quien figura como Vos, el badge pasa al siguiente activo',
      (tester) async {
    setTestSize(tester);
    addTearDown(SelfMemberStore.clearCache);
    await tester.pumpWidget(buildScreen(sampleGroup));
    await tester.pumpAndSettle();

    // Ana arranca como "Vos"
    expect(
      tester.getCenter(find.text('Vos')).dy,
      closeTo(tester.getCenter(find.text('Ana')).dy, 1),
    );

    // Archivar a Ana
    await tester.tap(find.byKey(Key('member-menu-${ana.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivar persona'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-archive-button')));
    await tester.pumpAndSettle();

    // Quedan Julia y Marco activos; Julia pasa a ser "Vos".
    expect(find.text('Vos'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Vos')).dy,
      closeTo(tester.getCenter(find.text('Julia')).dy, 1),
    );
  });
}
