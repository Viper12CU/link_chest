import 'package:flutter/material.dart';
import 'package:link_chest/widgets/atoms/pill_button.dart';

class VerifyEmailTemplate extends StatelessWidget {
  final String email;
  final bool isChecking;
  final bool isResending;
  final int resendCooldown;
  final VoidCallback onCheck;
  final VoidCallback onResend;
  final VoidCallback onSignOut;

  const VerifyEmailTemplate({
    super.key,
    required this.email,
    required this.isChecking,
    required this.isResending,
    required this.resendCooldown,
    required this.onCheck,
    required this.onResend,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final bool canResend = !isResending && resendCooldown == 0;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 64,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _MailBadge()),
                  const SizedBox(height: 28),
                  Text(
                    'Verifica tu correo',
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enviamos un enlace de verificación a',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(
                        email,
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _StepsCard(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: isChecking
                          ? 'Verificando...'
                          : 'Ya verifiqué mi correo',
                      onPressed: isChecking ? () {} : onCheck,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: canResend ? onResend : null,
                    icon: isResending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      isResending
                          ? 'Reenviando...'
                          : resendCooldown > 0
                          ? 'Reenviar en ${resendCooldown}s'
                          : 'Reenviar correo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSignOut,
                    child: const Text('Usar otra cuenta'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Si no lo encuentras, revisa la carpeta de spam.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MailBadge extends StatelessWidget {
  const _MailBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.18),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Icon(
        Icons.mark_email_read_outlined,
        size: 48,
        color: cs.onPrimary,
        semanticLabel: 'Correo de verificación',
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  static const List<String> _steps = [
    'Abre el correo de Link Chest.',
    'Toca el enlace de verificación.',
    'Vuelve aquí y confirma tu cuenta.',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _steps[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
