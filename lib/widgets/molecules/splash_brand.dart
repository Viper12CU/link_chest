import 'package:flutter/material.dart';
import 'package:link_chest/widgets/atoms/splash_logo.dart';

Color _withOpacity(Color color, double opacity) => Color.fromRGBO(
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  opacity,
);

class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SplashLogo(),
        const SizedBox(height: 28),
        Text(
          'Link Chest',
          textAlign: TextAlign.center,
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu colección personal de links',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: _withOpacity(Theme.of(context).colorScheme.onSurface, 0.72),
          ),
        ),
      ],
    );
  }
}
