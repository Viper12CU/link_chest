import 'package:flutter/material.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Modal de confirmación para resetear el vault privado.
/// Exige que el usuario escriba "ELIMINAR" para habilitar el botón de confirmar.
class ResetVaultDialog extends StatefulWidget {
  final Future<void> Function() onConfirmReset;

  const ResetVaultDialog({super.key, required this.onConfirmReset});

  /// Helper para mostrar el diálogo desde cualquier parte de la app.
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onConfirmReset,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ResetVaultDialog(onConfirmReset: onConfirmReset),
    );
  }

  @override
  State<ResetVaultDialog> createState() => _ResetVaultDialogState();
}

class _ResetVaultDialogState extends State<ResetVaultDialog> {
  static const _confirmWord = 'ELIMINAR';

  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  String? _validator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (value.trim() != _confirmWord) {
      return 'Debes escribir "$_confirmWord" exactamente';
    }
    return null;
  }

  Future<void> _handleConfirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      if (mounted) Navigator.of(context).pop();
      await widget.onConfirmReset();
    } catch (e) {
      debugPrint("-------------------------------------------------------Error: ${e.toString()}");
      if (mounted) {
        ToastifyFlutter.error(
          context,
          message: "Error al reiniciar pin",
          duration: 3,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.down,
      title: const Text('¿Olvidaste tu PIN?'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esto eliminará permanentemente el contenido del vault '
                'privado. No se puede deshacer.',
              ),
              const SizedBox(height: 16),
             
              Text.rich(TextSpan(
                text: 'Escribe ',
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: _confirmWord,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.red),
                  ),
                  const TextSpan(text: ' para confirmar:'),
                ],
              )),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                validator: _validator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: _confirmWord,
                  border: OutlineInputBorder(),
                ),
                enabled: !_isSubmitting,
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
          onPressed: _isSubmitting ? null : _handleConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar vault'),
        ),
      ],
    );
  }
}
