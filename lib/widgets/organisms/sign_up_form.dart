import 'package:flutter/material.dart';
import 'package:link_chest/utils/validators.dart';
import 'package:link_chest/widgets/atoms/pill_button.dart';
import 'package:link_chest/widgets/molecules/auth_field.dart';
import 'package:link_chest/widgets/molecules/google_button.dart';
import 'package:link_chest/widgets/molecules/or_divider.dart';
import 'package:link_chest/widgets/molecules/password_field.dart';

/// Formulario de registro; [submit] se invoca solo si la validación de todos
/// los campos pasa.
class SignUpForm extends StatefulWidget {
  final VoidCallback submit;
  final VoidCallback onGoogleSignUp;

  const SignUpForm({
    super.key,
    required this.submit,
    required this.onGoogleSignUp,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            label: 'Nombre',
            hintText: 'Ingresa tu nombre',
            prefixIcon: Icons.person_outline,
            controller: _nameController,
            validator: validateName,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),

          const SizedBox(height: 16),

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
            hintText: 'Crea una contraseña',
            controller: _passwordController,
            validator: validatePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),

          const SizedBox(height: 16),

          PasswordField(
            label: 'Confirmar contraseña',
            hintText: 'Repite tu contraseña',
            controller: _confirmPasswordController,
            validator: (value) => validateConfirmPassword(
              value,
              _passwordController.text,
            ),
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _handleSubmit(),
          ),

          const SizedBox(height: 30),

          Align(
            alignment: Alignment.center,
            child: PillButton(
              label: 'Crear cuenta',
              onPressed: _handleSubmit,
              widthFactor: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          const OrDivider(),

          const SizedBox(height: 16),

          GoogleButton(
            label: 'Crear cuenta con Google',
            onPressed: widget.onGoogleSignUp,
          ),
        ],
      ),
    );
  }
}
