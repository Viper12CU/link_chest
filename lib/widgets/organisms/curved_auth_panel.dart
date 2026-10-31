import 'package:flutter/material.dart';
import 'package:link_chest/models/form_sizes.dart';

/// Panel curvo animado del flujo de autenticación.
///
/// Interpola altura y sombras entre [from] y [to]. El contenido se maqueta
/// una sola vez con la altura de [contentMax], anclado abajo y recortado por
/// la curva: la animación solo revela, nunca reubica.
class CurvedAuthPanel extends StatelessWidget {
  final Animation<double> animation;
  final FormSizes from;
  final FormSizes to;
  final FormSizesType contentMax;
  final Widget child;

  const CurvedAuthPanel({
    super.key,
    required this.animation,
    required this.from,
    required this.to,
    required this.contentMax,
    required this.child,
  });

  static const double bottomPadding = 35;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final ThemeData theme = Theme.of(context);
    final double contentHeight =
        screenHeight * contentMax.primary - bottomPadding;
    final Widget content = RepaintBoundary(child: child);

    return AnimatedBuilder(
      animation: animation,
      child: content,
      builder: (context, child) {
        final FormSizes sizes = from.lerpTo(
          to,
          Curves.easeOutCubic.transform(animation.value),
        );

        return Container(
          padding: const EdgeInsets.only(bottom: bottomPadding),
          width: screenWidth,
          height: screenHeight * sizes.primary,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.vertical(
              top: Radius.elliptical(411, 211),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDADBDC),
                offset: Offset(0, sizes.secondShadow),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFD0D3D4),
                offset: Offset(0, sizes.firstShadow),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: OverflowBox(
            minHeight: 0,
            maxHeight: contentHeight,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
    );
  }
}
