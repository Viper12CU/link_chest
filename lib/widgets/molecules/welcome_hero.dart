import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bienvenida del login: mensaje central rodeado de nubes de chips de links.
class WelcomeHero extends StatefulWidget {
  const WelcomeHero({super.key});

  @override
  State<WelcomeHero> createState() => _WelcomeHeroState();
}

class _WelcomeHeroState extends State<WelcomeHero>
    with SingleTickerProviderStateMixin {
  static const List<({String domain, double angle, double dy})> _topLinks = [
    (domain: 'github.com', angle: -7, dy: 0),
    (domain: 'youtube.com', angle: 5, dy: 9),
    (domain: 'medium.com', angle: -3, dy: 3),
  ];

  static const List<({String domain, double angle, double dy})> _bottomLinks = [
    (domain: 'flutter.dev', angle: 6, dy: 7),
    (domain: 'notion.so', angle: -5, dy: 1),
  ];

  late final AnimationController _float;
  late final Animation<double> _floatY;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _animate) {
      _animate = false;
      _float.stop();
      _float.value = 0.5;
    } else if (!reduce && !_animate) {
      _animate = true;
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  /// Nube de chips centrada; flota de forma conjunta con la otra nube.
  Widget _chipCluster(List<({String domain, double angle, double dy})> links) {
    Widget cluster = Semantics(
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final link in links)
            _LinkChip(domain: link.domain, angle: link.angle, dy: link.dy),
        ],
      ),
    );

    if (_animate) {
      cluster = AnimatedBuilder(
        animation: _floatY,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _floatY.value),
          child: child,
        ),
        child: cluster,
      );
    }
    return cluster;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double screenHeight = MediaQuery.sizeOf(context).height;

    final TextStyle headline = textTheme.displaySmall!.copyWith(
      fontFamily: 'Sora',
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 1.08,
      color: cs.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: screenHeight * 0.2),
          _chipCluster(_topLinks),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              text: 'Bienvenido a\n',
              style: headline.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              children: [
                TextSpan(text: 'tu cofre de links', style: headline),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _chipCluster(_bottomLinks),
        ],
      ),
    );
  }
}

/// Miniatura de un link guardado con una ligera rotación.
class _LinkChip extends StatelessWidget {
  final String domain;
  final double angle;
  final double dy;

  const _LinkChip({required this.domain, required this.angle, required this.dy});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFDADBDC),
                offset: Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0xFFD0D3D4),
                offset: Offset(0, 2),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link,
                size: 13,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Text(
                domain,
                style: textTheme.labelSmall?.copyWith(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
