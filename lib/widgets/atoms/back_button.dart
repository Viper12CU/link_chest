import 'package:flutter/material.dart';

class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AuthBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
      label: Text(
        'Volver',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }
}
