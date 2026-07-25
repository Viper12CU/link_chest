import 'package:flutter/material.dart';
import 'package:link_chest/widgets/molecules/splash_brand.dart';

Color _withOpacity(Color color, double opacity) => Color.fromRGBO(
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  opacity,
);

class SplashTemplate extends StatelessWidget {
  const SplashTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -32,
            child: _AccentBlob(color: _withOpacity(cs.secondary, 0.12)),
          ),
          Positioned(
            left: -56,
            bottom: -48,
            child: _AccentBlob(color: _withOpacity(cs.primary, 0.10), size: 180),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SplashBrand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _AccentBlob({required this.color, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
