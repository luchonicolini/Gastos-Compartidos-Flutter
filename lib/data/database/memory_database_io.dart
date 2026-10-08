import 'package:drift/drift.dart';
import 'package:drift/native.dart';

DatabaseConnection openMemoryDatabase() =>
    DatabaseConnection(NativeDatabase.memory());
