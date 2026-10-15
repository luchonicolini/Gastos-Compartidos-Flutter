import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/local_group_repository.dart';
import 'domain/models/currency.dart';
import 'features/groups/presentation/home_screen.dart';
import 'features/onboarding/data/onboarding_status_store.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/settings/data/app_settings_store.dart';
import 'features/settings/presentation/app_settings_scope.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final database = AppDatabase();
  runApp(GastosCompartidosApp(database: database));
}

class GastosCompartidosApp extends StatefulWidget {
  const GastosCompartidosApp({
    super.key,
    required this.database,
    this.onboardingStore,
    this.settingsStore,
  });

  final AppDatabase database;
  final OnboardingStatusStore? onboardingStore;
  final AppSettingsStore? settingsStore;

  @override
  State<GastosCompartidosApp> createState() => _GastosCompartidosAppState();
}

class _GastosCompartidosAppState extends State<GastosCompartidosApp> {
  late final AppSettingsStore _settingsStore =
      widget.settingsStore ?? LocalAppSettingsStore();
  bool _reduceMotion = false;
  Currency _defaultCurrency = Currency.ars;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _settingsStore.isReduceMotionEnabled();
    final defaultCurrency = await _settingsStore.getDefaultCurrency();
    if (mounted) {
      setState(() {
        _reduceMotion = enabled;
        _defaultCurrency = defaultCurrency;
      });
    }
  }

  Future<void> _setReduceMotion(bool enabled) async {
    setState(() => _reduceMotion = enabled);
    await _settingsStore.setReduceMotionEnabled(enabled);
  }

  Future<void> _setDefaultCurrency(Currency currency) async {
    setState(() => _defaultCurrency = currency);
    await _settingsStore.setDefaultCurrency(currency);
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      reduceMotion: _reduceMotion,
      setReduceMotion: _setReduceMotion,
      defaultCurrency: _defaultCurrency,
      setDefaultCurrency: _setDefaultCurrency,
      child: MaterialApp(
        title: 'Gastos Compartidos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              disableAnimations: _reduceMotion || mediaQuery.disableAnimations,
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.35,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: _OnboardingGate(
          store: widget.onboardingStore ?? LocalOnboardingStatusStore(),
          settingsStore: _settingsStore,
          repository: LocalGroupRepository(widget.database),
        ),
      ),
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({
    required this.store,
    required this.settingsStore,
    required this.repository,
  });

  final OnboardingStatusStore store;
  final AppSettingsStore settingsStore;
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
          return const SplashScreenView();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            FlutterNativeSplash.remove();
          } catch (_) {}
        });
        if (_finishedThisSession || snapshot.data == true) {
          return HomeScreen(
            repository: widget.repository,
            onboardingStore: widget.store,
            settingsStore: widget.settingsStore,
          );
        }
        return OnboardingScreen(onFinish: _finish);
      },
    );
  }
}
