import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/utils/validators.dart';
import 'package:link_chest/widgets/atoms/profile_password_field.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Confirmación de eliminación de cuenta.
/// Exige escribir "ELIMINAR" y, en cuentas email/contraseña, la contraseña
/// actual para reautenticar antes de borrar.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  static const _confirmWord = 'ELIMINAR';

  final _formKey = GlobalKey<FormState>();
  final _confirmController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _hasPassword = AuthService.instance.hasPasswordProvider;
  bool _isSubmitting = false;

  String? _validateConfirmWord(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (value.trim() != _confirmWord) {
      return 'Debes escribir "$_confirmWord" exactamente';
    }
    return null;
  }

  Future<void> _handleDelete() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.deleteAccount(
        currentPassword: _hasPassword ? _passwordController.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      rootNavigator.popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ToastifyFlutter.error(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      ToastifyFlutter.error(
        context,
        message: 'No pudimos eliminar la cuenta. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.down,
      title: const Text('Eliminar cuenta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esto eliminará tu cuenta de Link Chest de forma permanente. '
                'Tus links guardados en este dispositivo no se borrarán. '
                'No se puede deshacer.',
              ),
              if (_hasPassword) ...[
                const SizedBox(height: 16),
                ProfilePasswordField(
                  label: 'Contraseña actual',
                  hintText: 'Confirma tu contraseña',
                  controller: _passwordController,
                  validator: validatePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_isSubmitting,
                ),
              ],
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'Escribe ',
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: _confirmWord,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' para confirmar:'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                validator: _validateConfirmWord,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: _confirmWord,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleDelete,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}
