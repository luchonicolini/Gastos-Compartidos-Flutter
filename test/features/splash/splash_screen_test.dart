import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_compartidos/core/theme/app_theme.dart';
import 'package:gastos_compartidos/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreenView muestra logo y textos en modo claro',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SplashScreenView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Kune'), findsOneWidget);
    expect(find.text('Cuentas claras entre amigos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SplashScreenView muestra logo y textos en modo oscuro',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const SplashScreenView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Kune'), findsOneWidget);
    expect(find.text('Cuentas claras entre amigos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
