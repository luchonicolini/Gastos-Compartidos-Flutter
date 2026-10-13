import 'package:flutter/widgets.dart';

/// Provee acceso al estado de configuración de la app en todo el árbol de widgets.
class AppSettingsScope extends InheritedWidget {
  const AppSettingsScope({
    super.key,
    required this.reduceMotion,
    required this.setReduceMotion,
    required super.child,
  });

  final bool reduceMotion;
  final ValueChanged<bool> setReduceMotion;

  static AppSettingsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();

  static AppSettingsScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppSettingsScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppSettingsScope oldWidget) =>
      reduceMotion != oldWidget.reduceMotion;
}
