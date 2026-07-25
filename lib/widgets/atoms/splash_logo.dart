import 'package:flutter/material.dart';

Color _withOpacity(Color color, double opacity) => Color.fromRGBO(
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  opacity,
);

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _withOpacity(cs.primary, 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Image.asset(
          'assets/logo.png',
          width: 110,
          height: 110,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
