import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/utils/validators.dart';
import 'package:link_chest/widgets/atoms/pill_button.dart';
import 'package:link_chest/widgets/atoms/profile_password_field.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Hoja inferior para cambiar la contraseña del usuario actual.
/// Devuelve `true` cuando la contraseña se actualizó correctamente.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ToastifyFlutter.error(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      ToastifyFlutter.error(
        context,
        message: 'No pudimos cambiar la contraseña. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cambiar contraseña',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Por seguridad, confirma tu contraseña actual antes de '
                'establecer una nueva.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ProfilePasswordField(
                label: 'Contraseña actual',
                hintText: 'Tu contraseña actual',
                controller: _currentController,
                validator: validatePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              ProfilePasswordField(
                label: 'Nueva contraseña',
                hintText: 'Mínimo 6 caracteres',
                controller: _newController,
                validator: validatePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              ProfilePasswordField(
                label: 'Confirmar nueva contraseña',
                hintText: 'Repite la nueva contraseña',
                controller: _confirmController,
                validator: (value) =>
                    validateConfirmPassword(value, _newController.text),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _handleSubmit(),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 24),
              PillButton(
                label: 'Guardar contraseña',
                loading: _isSubmitting,
                onPressed: _isSubmitting ? () {} : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
