import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/local_group_repository.dart';
import 'features/groups/presentation/home_screen.dart';
import 'features/onboarding/data/onboarding_status_store.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

void main() {
  final database = AppDatabase();
  runApp(GastosCompartidosApp(database: database));
}

class GastosCompartidosApp extends StatelessWidget {
  const GastosCompartidosApp({
    super.key,
    required this.database,
    this.onboardingStore,
  });

  final AppDatabase database;
  final OnboardingStatusStore? onboardingStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Compartidos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _OnboardingGate(
        store: onboardingStore ?? LocalOnboardingStatusStore(),
        repository: LocalGroupRepository(database),
      ),
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({required this.store, required this.repository});

  final OnboardingStatusStore store;
  final LocalGroupRepository repository;

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late final Future<bool> _completion = widget.store.isComplete();
  bool _finishedThisSession = false;

  Future<void> _finish() async {
    await widget.store.markComplete();
    if (mounted) setState(() => _finishedThisSession = true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _completion,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_finishedThisSession || snapshot.data == true) {
          return HomeScreen(repository: widget.repository);
        }
        return OnboardingScreen(onFinish: _finish);
      },
    );
  }
}
