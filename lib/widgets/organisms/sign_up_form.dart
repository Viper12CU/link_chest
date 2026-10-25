import 'package:flutter/material.dart';

/// Formulario de creación de cuenta.
///
/// La lógica de registro no vive en este widget: [submit] se ejecuta solo
/// cuando todos los campos superan su validación y [onGoogleSignUp] cuando
/// el usuario pulsa el botón de Google.
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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Ingresa tu nombre';
    }

    if (name.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Name ─────────────────────────────────────────────────
          Text('Nombre', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              hintText: 'Ingresa tu nombre',
              prefixIcon: Icon(
                Icons.person_outline,
                color: colorScheme.tertiary,
                size: 21,
              ),
            ),
            validator: _validateName,
          ),

          const SizedBox(height: 16),

          // ── Email ────────────────────────────────────────────────
          Text('Correo electrónico', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              hintText: 'tu@correo.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: colorScheme.tertiary,
                size: 21,
              ),
            ),
            validator: _validateEmail,
          ),

          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────
          Text('Contraseña', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              hintText: 'Crea una contraseña',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.tertiary,
                size: 21,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colorScheme.secondary,
                  size: 21,
                ),
              ),
            ),
            validator: _validatePassword,
          ),

          const SizedBox(height: 16),

          // ── Confirm password ─────────────────────────────────────
          Text('Confirmar contraseña', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _handleSubmit(),
            decoration: InputDecoration(
              hintText: 'Repite tu contraseña',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.tertiary,
                size: 21,
              ),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colorScheme.secondary,
                  size: 21,
                ),
              ),
            ),
            validator: _validateConfirmPassword,
          ),

          const SizedBox(height: 20),

          // ── Submit ───────────────────────────────────────────────
          ElevatedButton(
            onPressed: _handleSubmit,
            child: const Text('Crear cuenta'),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o', style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 16),

          // ── Google ───────────────────────────────────────────────
          OutlinedButton(
            onPressed: widget.onGoogleSignUp,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'G',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Crear cuenta con Google'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
