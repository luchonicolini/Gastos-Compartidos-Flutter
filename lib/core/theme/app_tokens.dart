import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceSecondary,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.separator,
    required this.action,
    required this.positive,
    required this.negative,
    required this.radiusCard,
    required this.radiusControl,
    required this.spacePage,
    required this.spaceSection,
    required this.durationPress,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSecondary;
  final Color labelPrimary;
  final Color labelSecondary;
  final Color separator;
  final Color action;
  final Color positive;
  final Color negative;
  final double radiusCard;
  final double radiusControl;
  final double spacePage;
  final double spaceSection;
  final Duration durationPress;

  static const light = AppTokens(
    canvas: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF0F1F5),
    labelPrimary: Color(0xFF17181C),
    labelSecondary: Color(0xFF62656D),
    separator: Color(0xFFE3E5EA),
    action: Color(0xFF2563EB),
    positive: Color(0xFF18794E),
    negative: Color(0xFFB42318),
    radiusCard: 16,
    radiusControl: 14,
    spacePage: 16,
    spaceSection: 28,
    durationPress: Duration(milliseconds: 90),
  );

  static const dark = AppTokens(
    canvas: Color(0xFF101216),
    surface: Color(0xFF191B20),
    surfaceSecondary: Color(0xFF24272E),
    labelPrimary: Color(0xFFF4F5F7),
    labelSecondary: Color(0xFFAEB2BB),
    separator: Color(0xFF353942),
    action: Color(0xFF78A9FF),
    positive: Color(0xFF63D39B),
    negative: Color(0xFFFF938C),
    radiusCard: 16,
    radiusControl: 14,
    spacePage: 16,
    spaceSection: 28,
    durationPress: Duration(milliseconds: 90),
  );

  static AppTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>();
    assert(tokens != null, 'AppTokens missing from ThemeData.extensions');
    return tokens!;
  }

  @override
  AppTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSecondary,
    Color? labelPrimary,
    Color? labelSecondary,
    Color? separator,
    Color? action,
    Color? positive,
    Color? negative,
    double? radiusCard,
    double? radiusControl,
    double? spacePage,
    double? spaceSection,
    Duration? durationPress,
  }) {
    return AppTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      labelPrimary: labelPrimary ?? this.labelPrimary,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      separator: separator ?? this.separator,
      action: action ?? this.action,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusControl: radiusControl ?? this.radiusControl,
      spacePage: spacePage ?? this.spacePage,
      spaceSection: spaceSection ?? this.spaceSection,
      durationPress: durationPress ?? this.durationPress,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      labelPrimary: Color.lerp(labelPrimary, other.labelPrimary, t)!,
      labelSecondary: Color.lerp(labelSecondary, other.labelSecondary, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      action: Color.lerp(action, other.action, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      radiusCard: _lerp(radiusCard, other.radiusCard, t),
      radiusControl: _lerp(radiusControl, other.radiusControl, t),
      spacePage: _lerp(spacePage, other.spacePage, t),
      spaceSection: _lerp(spaceSection, other.spaceSection, t),
      durationPress: t < 0.5 ? durationPress : other.durationPress,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => AppTokens.of(this);
}
