import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _pages = [
    _PageCopy(
      title: '¿Quién pagó qué?',
      description:
          'Taxis, cenas y entradas: en un viaje en grupo todos pagan algo. Anotalo en el momento y no se pierde nada.',
    ),
    _PageCopy(
      title: 'Dividí a tu manera',
      description:
          'Un gasto puede tener varios pagadores y repartirse en partes iguales, montos, porcentajes o proporciones.',
    ),
    _PageCopy(
      title: 'Viajá con distintas monedas',
      description:
          'Cada gasto conserva su moneda e importe original y se convierte a la moneda de referencia del grupo.',
    ),
    _PageCopy(
      title: 'Terminá con las cuentas claras',
      description:
          'Mirá el balance de cada persona y los pagos sugeridos para saldar todo con pocas transferencias.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await widget.onFinish();
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar. Intentá otra vez.')),
      );
    }
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, 560.0);
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _Progress(currentPage: _page)),
                          const SizedBox(width: 22),
                          if (_page < _pages.length - 1)
                            TextButton(
                              onPressed: _finishing ? null : _finish,
                              child: const Text('Saltar'),
                            )
                          else
                            const SizedBox(width: 64, height: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (value) => setState(() => _page = value),
                        itemBuilder: (context, index) =>
                            _OnboardingPage(copy: _pages[index], index: index),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          dotWidth: 8,
                          dotHeight: 8,
                          expansionFactor: 3.5,
                          spacing: 6,
                          activeDotColor: Theme.of(context).colorScheme.primary,
                          dotColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppPalette.darkTrack
                                  : AppPalette.lightTrack,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: FilledButton(
                        onPressed: _finishing ? null : _next,
                        child: Text(
                          _page == _pages.length - 1 ? 'Comenzar' : 'Siguiente',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageCopy {
  const _PageCopy({required this.title, required this.description});

  final String title;
  final String description;
}

class _Progress extends StatelessWidget {
  const _Progress({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.primary;
    final track = dark ? AppPalette.darkTrack : AppPalette.lightTrack;
    return Semantics(
      label: 'Paso ${currentPage + 1} de 4',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < 4; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= currentPage ? color : track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.copy, required this.index});

  final _PageCopy copy;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final artHeight =
            (constraints.maxHeight - (index < 2 ? 285 : 340) * textScale).clamp(
              180.0,
              620.0,
            );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeIn(
                duration: const Duration(milliseconds: 350),
                animate: !disableAnimations,
                child: SizedBox(
                  height: artHeight,
                  child: ExcludeSemantics(child: _Illustration(index: index)),
                ),
              ),
              const SizedBox(height: 18),
              FadeInUp(
                from: 14,
                duration: const Duration(milliseconds: 320),
                delay: const Duration(milliseconds: 60),
                animate: !disableAnimations,
                child: Text(
                  copy.title,
                  key: ValueKey('onboarding-title-$index'),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                from: 14,
                duration: const Duration(milliseconds: 320),
                delay: const Duration(milliseconds: 120),
                animate: !disableAnimations,
                child: Text(
                  copy.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16.5,
                    height: 1.48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? AppPalette.darkIllustration
            : AppPalette.lightIllustration,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 340,
            child: switch (index) {
              0 => const _WhoPaidArt(),
              1 => const _SplitArt(),
              2 => const _CurrencyArt(),
              _ => const _SettlementArt(),
            },
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? AppPalette.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.12 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WhoPaidArt extends StatelessWidget {
  const _WhoPaidArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExpenseDemoRow(
          title: 'Cena en el puerto',
          detail: 'Pagó Ana',
          amount: '€ 86,40',
          avatar: const _Avatar(letter: 'A', color: AppPalette.lightTeal),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: _ExpenseDemoRow(
            title: 'Taxi al aeropuerto',
            detail: '¿Quién pagó?',
            amount: '€ 32,00',
            avatar: _UnknownPayer(),
          ),
        ),
        const SizedBox(height: 12),
        const _ExpenseDemoRow(
          title: 'Entradas al museo',
          detail: '¿Quién pagó?',
          amount: '€ 45,00',
          avatar: _UnknownPayer(),
        ),
      ],
    );
  }
}

class _ExpenseDemoRow extends StatelessWidget {
  const _ExpenseDemoRow({
    required this.title,
    required this.detail,
    required this.amount,
    required this.avatar,
  });

  final String title;
  final String detail;
  final String amount;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DemoCard(
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            amount,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 19,
    backgroundColor: color,
    child: Text(
      letter,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
    ),
  );
}

class _UnknownPayer extends StatelessWidget {
  const _UnknownPayer();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return CustomPaint(
      painter: _DashedCirclePainter(muted),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    for (var i = 0; i < 12; i++) {
      canvas.drawArc(rect, i * math.pi / 6, math.pi / 10, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SplitArt extends StatelessWidget {
  const _SplitArt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.brightness == Brightness.dark
        ? AppPalette.darkTrack
        : AppPalette.lightTrack;
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cena en el puerto',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '€ 120,00',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  'Pagaron',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                const _Avatar(letter: 'A', color: AppPalette.lightTeal),
                const SizedBox(width: 5),
                Text(
                  '€ 80',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                const _Avatar(letter: 'M', color: Color(0xFFB83C16)),
                const SizedBox(width: 5),
                Text(
                  '€ 40',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                for (final label in ['Igual', 'Montos', '%', 'Partes'])
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: label == '%'
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: label == '%'
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _PercentRow(
            letter: 'A',
            color: AppPalette.lightTeal,
            value: 0.5,
            text: '50%',
          ),
          const SizedBox(height: 10),
          const _PercentRow(
            letter: 'M',
            color: Color(0xFFB83C16),
            value: 0.3,
            text: '30%',
          ),
          const SizedBox(height: 10),
          const _PercentRow(
            letter: 'J',
            color: Color(0xFF42539C),
            value: 0.2,
            text: '20%',
          ),
        ],
      ),
    );
  }
}

class _PercentRow extends StatelessWidget {
  const _PercentRow({
    required this.letter,
    required this.color,
    required this.value,
    required this.text,
  });
  final String letter;
  final Color color;
  final double value;
  final String text;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.darkTrack
        : AppPalette.lightTrack;
    return Row(
      children: [
        _Avatar(letter: letter, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: track,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            text,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _CurrencyArt extends StatelessWidget {
  const _CurrencyArt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = theme.colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lo que pagaste · Tokio',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '¥ 12.400',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text('JPY · moneda original', style: TextStyle(color: muted)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 11),
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          child: const Icon(Icons.south_rounded, color: Colors.white, size: 29),
        ),
        _DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'En la moneda del grupo',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Text(
                '≈ € 76,07',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                  color: accent,
                ),
              ),
              const SizedBox(height: 5),
              Text('EUR · 1 € = 163 ¥', style: TextStyle(color: muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettlementArt extends StatelessWidget {
  const _SettlementArt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const _BalanceLine(
          name: 'Ana',
          amount: '+ € 42,00',
          color: AppPalette.lightTeal,
          amountColor: Color(0xFF087568),
        ),
        const SizedBox(height: 10),
        const _BalanceLine(
          name: 'Marco',
          amount: '− € 30,00',
          color: Color(0xFFB83C16),
          amountColor: Color(0xFFC14411),
        ),
        const SizedBox(height: 10),
        const _BalanceLine(
          name: 'Julia',
          amount: '− € 12,00',
          color: Color(0xFF42539C),
          amountColor: Color(0xFFC14411),
        ),
        const SizedBox(height: 10),
        _DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PAGOS SUGERIDOS',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 9),
              const _SuggestedPayment(name: 'Marco', amount: '€ 30,00'),
              const SizedBox(height: 5),
              const _SuggestedPayment(name: 'Julia', amount: '€ 12,00'),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.name,
    required this.amount,
    required this.color,
    required this.amountColor,
  });

  final String name;
  final String amount;
  final Color color;
  final Color amountColor;

  @override
  Widget build(BuildContext context) => _DemoCard(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color,
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
        ),
      ],
    ),
  );
}

class _SuggestedPayment extends StatelessWidget {
  const _SuggestedPayment({required this.name, required this.amount});
  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$name ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: 'paga a '),
              const TextSpan(
                text: 'Ana',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  );
}
