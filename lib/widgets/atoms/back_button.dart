import 'package:flutter/material.dart';

class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AuthBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onPressed,
      label: Text('Volver', style: theme.textTheme.bodyLarge),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }
}
