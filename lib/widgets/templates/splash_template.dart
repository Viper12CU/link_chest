import 'package:flutter/material.dart';
import 'package:link_chest/widgets/molecules/splash_brand.dart';

class SplashTemplate extends StatelessWidget {
  const SplashTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SplashBrand(),
        ),
      ),
    );
  }
}
