import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/utils/validators.dart';
import 'package:link_chest/widgets/atoms/pill_button.dart';
import 'package:link_chest/widgets/molecules/auth_field.dart';
import 'package:link_chest/widgets/molecules/google_button.dart';
import 'package:link_chest/widgets/molecules/or_divider.dart';
import 'package:link_chest/widgets/molecules/password_field.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Formulario de inicio de sesión; [submit] se invoca solo si la validación
/// de todos los campos pasa.
class LoginForm extends StatefulWidget {
  final VoidCallback onGoogleSignIn;

  const LoginForm({super.key, required this.onGoogleSignIn});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      // No navegues aquí: AuthGate detecta la sesión y cambia de pantalla solo.
    } on AuthFailure catch (e) {
      if (!mounted) return;

      ToastifyFlutter.error(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      ToastifyFlutter.error(context, message: "Ocurrió un error inesperado.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
              onPressed: _isLoading ? () {} : _handleSubmit,
              widthFactor: 0.5,
              loading: _isLoading,
            ),
          ),

          const SizedBox(height: 16),

          const OrDivider(),

          const SizedBox(height: 16),

          GoogleButton(
            label: 'Iniciar sesión con Google',
            onPressed: _isLoading ? () {} : widget.onGoogleSignIn,
          ),
        ],
      ),
    );
  }
}
