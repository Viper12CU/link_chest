import 'package:flutter/material.dart';
import 'package:link_chest/widgets/atoms/auth_field_label.dart';
import 'package:link_chest/widgets/atoms/auth_text_field.dart';

class AuthField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final void Function(String)? onFieldSubmitted;

  const AuthField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(text: label),
        const SizedBox(height: 6),
        AuthTextField(
          controller: controller,
          hintText: hintText,
          prefixIcon: prefixIcon,
          validator: validator,
          obscureText: obscureText,
          suffixIcon: suffixIcon,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
