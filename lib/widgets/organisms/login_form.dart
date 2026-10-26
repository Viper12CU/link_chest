import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Formulario de inicio de sesión.
///
/// La lógica de autenticación no vive en este widget: [submit] se ejecuta
/// solo cuando todos los campos superan su validación y [onGoogleSignIn]
/// cuando el usuario pulsa el botón de Google.
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

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      return 'Ingresa tu contraseña';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
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
    final double screenWidth = MediaQuery.of(context).size.width;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email ────────────────────────────────────────────────
          Text(
            'Correo electrónico',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: colorScheme.onSecondary),
            decoration: InputDecoration(
              fillColor: colorScheme.secondary,
              filled: true,
              hintText: 'tu@correo.com',
              hintStyle: TextStyle(color: colorScheme.onSecondary),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: colorScheme.onSecondary,
                size: 21,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.onSecondary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 1.5),
              ),
            ),
            validator: _validateEmail,
          ),

          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────
          Text(
            'Contraseña',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _handleSubmit(),
            style: TextStyle(color: colorScheme.onSecondary),
            decoration: InputDecoration(
              fillColor: colorScheme.secondary,
              filled: true,
              hintText: 'Ingresa tu contraseña',
              hintStyle: TextStyle(color: colorScheme.onSecondary),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.onSecondary,
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
                  color: colorScheme.onSecondary,
                  size: 21,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.onSecondary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 1.5),
              ),
            ),
            validator: _validatePassword,
          ),

          const SizedBox(height: 30),

          // ── Submit ───────────────────────────────────────────────
          Align(
            alignment: AlignmentGeometry.center,
            child: SizedBox(
              width: screenWidth * 0.5,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(24),
                  ),
                ),
                onPressed: _handleSubmit,
                child: Text(
                  'Iniciar sesión',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
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
          ),

          const SizedBox(height: 16),

          // ── Google ───────────────────────────────────────────────
          ElevatedButton(
            onPressed: widget.onGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1.5, color: colorScheme.onSecondary),
                borderRadius: BorderRadiusGeometry.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/google.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Iniciar sesión con Google',
                  style: TextStyle(color: colorScheme.onSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
