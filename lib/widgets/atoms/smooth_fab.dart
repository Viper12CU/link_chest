import 'package:flutter/material.dart';

class SmoothFab extends StatelessWidget {
  const SmoothFab({
    super.key,
    required this.extended,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOutCubic,
    this.backgroundColor,
    this.foregroundColor,
  });

  final bool extended;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Duration duration;
  final Curve curve;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = this.backgroundColor ?? scheme.primaryContainer;
    final foregroundColor = this.foregroundColor ?? scheme.onPrimaryContainer;

    return Material(
      color: backgroundColor,
      elevation: 6,
      borderRadius: BorderRadius.circular(18.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foregroundColor, size: 24,),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: extended ? 1.0 : 0.0),
                  duration: duration,
                  curve: curve,
                  builder: (context, t, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: t, // anima el ancho
                        child: Opacity(
                          opacity: Curves.easeIn.transform(t), // fade del texto
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
