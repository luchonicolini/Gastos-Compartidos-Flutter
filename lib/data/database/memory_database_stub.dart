import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

DatabaseConnection openMemoryDatabase() =>
    driftDatabase(name: 'gastos_compartidos_test');

