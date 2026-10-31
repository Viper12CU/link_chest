import 'package:flutter/material.dart';
import 'package:link_chest/utils/validators.dart';
import 'package:link_chest/widgets/atoms/pill_button.dart';
import 'package:link_chest/widgets/molecules/auth_field.dart';
import 'package:link_chest/widgets/molecules/google_button.dart';
import 'package:link_chest/widgets/molecules/or_divider.dart';
import 'package:link_chest/widgets/molecules/password_field.dart';

/// Formulario de inicio de sesión; [submit] se invoca solo si la validación
/// de todos los campos pasa.
class LoginForm extends StatefulWidget {
  final VoidCallback submit;
  final VoidCallback onGoogleSignIn;

  const LoginForm({
    super.key,
    required this.submit,
    required this.onGoogleSignIn,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthField(
            label: 'Correo electrónico',
            hintText: 'tu@correo.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            validator: validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),

          const SizedBox(height: 16),

          PasswordField(
            label: 'Contraseña',
            hintText: 'Ingresa tu contraseña',
            controller: _passwordController,
            validator: validatePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _handleSubmit(),
          ),

          const SizedBox(height: 30),

          Align(
            alignment: Alignment.center,
            child: PillButton(
              label: 'Iniciar sesión',
              onPressed: _handleSubmit,
              widthFactor: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          const OrDivider(),

          const SizedBox(height: 16),

          GoogleButton(
            label: 'Iniciar sesión con Google',
            onPressed: widget.onGoogleSignIn,
          ),
        ],
      ),
    );
  }
}
