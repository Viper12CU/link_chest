import 'package:flutter/material.dart';

/// Marcador de estado de sincronización para links y categorías.
/// No se usa en el Vault (decisión: solo lista principal).
class SyncMarker extends StatelessWidget {
  final bool isPending;
  final bool hasError;

  const SyncMarker({super.key, this.isPending = false, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    if (!isPending && !hasError) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final bool error = hasError;
    final Color color = error ? theme.colorScheme.error : const Color(0xFFE0A100);
    final String label = error ? 'No se pudo sincronizar' : 'Pendiente de sincronizar';
    final IconData icon = error ? Icons.error_outline : Icons.sync;

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              error ? 'Error de sync' : 'Pendiente',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
