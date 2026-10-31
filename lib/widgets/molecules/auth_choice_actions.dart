import 'package:flutter/material.dart';
import 'package:link_chest/widgets/atoms/pill_button.dart';

class AuthChoiceActions extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  const AuthChoiceActions({
    super.key,
    required this.onLogin,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 15.0,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PillButton(
          label: 'Inicia Sesión',
          onPressed: onLogin,
          widthFactor: 0.5,
        ),
        PillButton(
          label: 'Crea una cuenta',
          onPressed: onSignUp,
          filled: false,
          widthFactor: 0.5,
        ),
      ],
    );
  }
}
