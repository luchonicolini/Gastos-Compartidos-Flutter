import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.borderRadius,
    this.pressScale = 0.985,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final BorderRadius? borderRadius;
  final double pressScale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onPressed != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : context.tokens.durationPress;
    final child = AnimatedScale(
      scale: _pressed && interactive ? widget.pressScale : 1,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    );

    return Semantics(
      button: interactive,
      enabled: interactive,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: interactive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: interactive
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: interactive
              ? () => setState(() => _pressed = false)
              : null,
          onTap: widget.onPressed,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
