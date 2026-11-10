import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/widgets/atoms/confirm_dialog.dart';
import 'package:link_chest/widgets/atoms/profile_item.dart';
import 'package:link_chest/widgets/molecules/change_password_sheet.dart';
import 'package:link_chest/widgets/molecules/delete_account_dialog.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Sección "CUENTA" del perfil: correo, contraseña, eliminación y cierre
/// de sesión. Sigue el estilo de `ActiveSessions` / `ProfileAplication`.
class ProfileAccount extends StatelessWidget {
  final String email;
  final bool isVerified;

  const ProfileAccount({
    super.key,
    required this.email,
    required this.isVerified,
  });

  Future<void> _handleChangePassword(BuildContext context) async {
    final bool? changed = await ChangePasswordSheet.show(context);
    if (changed == true && context.mounted) {
      ToastifyFlutter.success(
        context,
        message: 'Contraseña actualizada.',
        duration: 3,
        style: ToastStyle.flat,
      );
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await AuthService.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthFailure catch (e) {
      if (context.mounted) {
        ToastifyFlutter.error(context, message: e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasPassword = AuthService.instance.hasPasswordProvider;

    return Column(
      spacing: 10.0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUENTA',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: [
              ProfileItem(
                icon: Icons.alternate_email_rounded,
                title: 'Correo',
                textLabel: email,
                action: _VerificationPill(isVerified: isVerified),
              ),
              if (hasPassword) ...[
                Divider(height: 1, color: colorScheme.outline),
                ProfileItem(
                  icon: Icons.lock_outline,
                  title: 'Cambiar contraseña',
                  textLabel: 'Actualiza tu contraseña de acceso',
                  action: IconButton(
                    onPressed: () => _handleChangePassword(context),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
              Divider(height: 1, color: colorScheme.outline),
              ProfileItem(
                icon: Icons.delete_forever_outlined,
                title: 'Eliminar cuenta',
                textLabel: 'Esta acción no se puede deshacer',
                iconColor: colorScheme.error,
                titleColor: colorScheme.error,
                action: IconButton(
                  onPressed: () => DeleteAccountDialog.show(context),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.error,
                  ),
                ),
              ),
              Divider(height: 1, color: colorScheme.outline),
              ProfileItem(
                icon: Icons.logout_outlined,
                title: 'Cerrar sesión',
                textLabel: 'Termina la sesión en este dispositivo',
                action: IconButton(
                  onPressed: () {
                    ConfirmDialog.show(
                      context: context,
                      title: 'Cerrar la sesión actual',
                      description:
                          'Se terminará con la sesión en este dispositivo.',
                      actions: [
                        ConfirmAction(
                          label: 'Cerrar sesión',
                          onTap: () => _handleSignOut(context),
                          style: ConfirmActionStyle.destructive,
                        ),
                      ],
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationPill extends StatelessWidget {
  final bool isVerified;

  const _VerificationPill({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    const Color verified = Color(0xFF4FD1B5);
    const Color pending = Color(0xFFE0A100);
    final Color color = isVerified ? verified : pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isVerified ? const Color(0x404FD1B5) : const Color(0x40E0A100),
        ),
      ),
      child: Text(
        isVerified ? 'Verificado' : 'Sin verificar',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
