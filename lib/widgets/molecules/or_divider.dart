import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
