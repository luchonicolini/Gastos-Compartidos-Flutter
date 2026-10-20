import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreenView extends StatelessWidget {
  const SplashScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF11232D) : const Color(0xFFE3EEED),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              isDark
                  ? 'assets/branding/splash_icon_dark.png'
                  : 'assets/branding/splash_icon_light.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kune',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuentas claras entre amigos',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Figtree',
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppPalette.lightTeal : AppPalette.lightTeal,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: reduceMotion
            ? content
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.96 + (0.04 * value),
                      child: child,
                    ),
                  );
                },
                child: content,
              ),
      ),
    );
  }
}
