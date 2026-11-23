import 'dart:async';

import 'package:flutter/material.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/pages/login_page.dart';
import 'package:link_chest/widgets/molecules/sync_error_sheet.dart';

/// Banner de estado de sincronización en la pantalla principal.
/// Prioridad: needsLogin → errores → offline → syncing (>1 s) → nada.
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  Timer? _syncDelay;
  bool _showSyncing = false;
  SyncService? _sync;

  @override
  void initState() {
    super.initState();
    _sync = SyncService.instance;
    _sync!.addListener(_onSyncChanged);
    _updateSyncingDelay();
  }

  @override
  void dispose() {
    _sync?.removeListener(_onSyncChanged);
    _syncDelay?.cancel();
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted) return;
    setState(() {});
    _updateSyncingDelay();
  }

  /// Evita parpadeo: «Sincronizando…» solo tras ~1 s en esa fase.
  void _updateSyncingDelay() {
    _syncDelay?.cancel();
    final phase = _sync?.phase;
    if (phase == SyncPhase.syncing) {
      _showSyncing = false;
      _syncDelay = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        if (_sync?.phase == SyncPhase.syncing) {
          setState(() => _showSyncing = true);
        }
      });
    } else {
      _showSyncing = false;
    }
  }

  void _openErrorSheet() {
    SyncErrorSheet.show(context: context);
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final sync = _sync;
    if (sync == null || !sync.isActive) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    // 1. Sesión vencida
    if (sync.phase == SyncPhase.needsLogin) {
      return _banner(
        context,
        icon: Icons.lock_outline,
        color: cs.error,
        text: 'Tu sesión expiró. Inicia sesión para sincronizar',
        actionLabel: 'Iniciar sesión',
        onAction: _goToLogin,
      );
    }

    // 2. Cambios con error definitivo
    final errors = sync.errorCount;
    if (errors > 0) {
      return _banner(
        context,
        icon: Icons.error_outline,
        color: cs.error,
        text: errors == 1
            ? '1 cambio no se pudo sincronizar'
            : '$errors cambios no se pudieron sincronizar',
        actionLabel: 'Revisar',
        onAction: _openErrorSheet,
      );
    }

    // 3. Sin conexión (con o sin pendientes)
    if (sync.phase == SyncPhase.offline) {
      final pending = sync.pendingCount;
      final text = pending > 0
          ? 'Sin conexión · $pending ${pending == 1 ? 'cambio pendiente' : 'cambios pendientes'} de sincronizar'
          : 'Sin conexión · sin cambios pendientes';
      return _banner(
        context,
        icon: Icons.wifi_off_rounded,
        color: const Color(0xFFE0A100),
        text: text,
      );
    }

    // 4. Sincronizando (tras 1 s)
    if (sync.phase == SyncPhase.syncing && _showSyncing) {
      return _banner(
        context,
        icon: Icons.sync,
        color: cs.primary,
        text: 'Sincronizando…',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _banner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
