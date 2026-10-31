import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final double? widthFactor;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget button = ElevatedButton(
      style: filled
          ? ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(24),
              ),
            )
          : ElevatedButton.styleFrom(
              foregroundColor: colorScheme.secondary,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 2,
                  color: colorScheme.secondary,
                ),
                borderRadius: BorderRadiusGeometry.circular(24),
              ),
            ),
      onPressed: onPressed,
      child: Text(
        label,
        style: theme.textTheme.bodyLarge!.copyWith(
          color: colorScheme.onSecondary,
        ),
      ),
    );

    if (widthFactor == null) return button;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * widthFactor!,
      child: button,
    );
  }
}
