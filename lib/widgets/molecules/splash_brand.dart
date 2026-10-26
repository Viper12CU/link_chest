import 'package:flutter/material.dart';
import 'package:link_chest/widgets/atoms/splash_logo.dart';

class SplashBrand extends StatefulWidget {
  const SplashBrand({super.key});

  @override
  State<SplashBrand> createState() => _SplashBrandState();
}

class _SplashBrandState extends State<SplashBrand> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SplashLogo(),
        const SizedBox(height: 32),
        Text(
          'Link Chest',
          textAlign: TextAlign.center,
          style: textTheme.displayMedium?.copyWith(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu colección personal de links',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w400,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 48),
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: null,
                  minHeight: 3,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cs.primary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
