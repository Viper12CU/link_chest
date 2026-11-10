import 'package:flutter/material.dart';
import 'package:link_chest/widgets/molecules/auth_field.dart';

class PasswordField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  const PasswordField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AuthField(
      label: widget.label,
      hintText: widget.hintText,
      prefixIcon: Icons.lock_outline,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: colorScheme.onSecondary,
          size: 21,
        ),
      ),
    );
  }
}
