import 'package:flutter/material.dart';

class SplashLogo extends StatefulWidget {
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const SplashLogo({
    super.key,
    this.duration = const Duration(milliseconds: 900),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.elasticOut,
  });

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleY = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(widget.delay);
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    Widget logo = Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      ),
    );

    if (disableAnimations) return logo;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scaleY: _scaleY.value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: logo,
    );
  }
}
