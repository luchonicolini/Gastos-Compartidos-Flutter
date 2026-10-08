import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/local_group_repository.dart';
import 'features/groups/presentation/home_screen.dart';

void main() {
  final database = AppDatabase();
  runApp(GastosCompartidosApp(database: database));
}

class GastosCompartidosApp extends StatelessWidget {
  const GastosCompartidosApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Compartidos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: HomeScreen(repository: LocalGroupRepository(database)),
    );
  }
}

