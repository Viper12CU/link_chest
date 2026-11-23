import 'package:flutter/material.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/utils/shared/sync_ui_helpers.dart';
import 'package:link_chest/widgets/atoms/profile_item.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Sección «SINCRONIZACIÓN» del perfil: último sync y botón «Sincronizar ahora».
class ProfileSync extends StatefulWidget {
  const ProfileSync({super.key});

  @override
  State<ProfileSync> createState() => _ProfileSyncState();
}

class _ProfileSyncState extends State<ProfileSync> {
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = SyncService.instance;
    _sync.addListener(_onChanged);
  }

  @override
  void dispose() {
    _sync.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _syncNow() async {
    if (_sync.isRunning) return;

    final online = await _sync.isOnline();
    if (!online) {
      if (mounted) {
        ToastifyFlutter.info(
          context,
          message: 'Sin conexión. Se sincronizará cuando vuelva internet.',
          duration: 4,
          style: ToastStyle.flat,
        );
      }
      return;
    }

    await _sync.syncNow();

    if (!mounted) return;
    if (_sync.phase == SyncPhase.offline) {
      ToastifyFlutter.info(
        context,
        message: 'Sin conexión. Se sincronizará cuando vuelva internet.',
        duration: 4,
        style: ToastStyle.flat,
      );
    } else if (_sync.phase == SyncPhase.idle) {
      ToastifyFlutter.success(
        context,
        message: 'Sincronizado',
        duration: 3,
        style: ToastStyle.flat,
      );
    } else if (_sync.phase == SyncPhase.error) {
      ToastifyFlutter.error(
        context,
        message: 'No se pudo sincronizar',
        duration: 4,
        style: ToastStyle.flat,
      );
    } else if (_sync.phase == SyncPhase.needsLogin) {
      ToastifyFlutter.error(
        context,
        message: 'Tu sesión expiró. Inicia sesión para sincronizar.',
        duration: 4,
        style: ToastStyle.flat,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool running = _sync.isRunning;
    final String lastText = relativeSyncTime(_sync.lastSyncedAt);

    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SINCRONIZACIÓN',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            children: [
              ProfileItem(
                icon: Icons.sync_rounded,
                title: running ? 'Sincronizando…' : 'Última sincronización',
                textLabel: running ? 'Espera un momento' : lastText,
                action: running
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _syncNow,
                        tooltip: 'Sincronizar ahora',
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
              ),
              Divider(height: 1, color: cs.outline),
              ProfileItem(
                icon: Icons.cloud_sync_outlined,
                title: 'Sincronizar ahora',
                textLabel: running
                    ? 'Ya hay una sincronización en curso'
                    : 'Sube y descarga los cambios pendientes',
                action: TextButton(
                  onPressed: running ? null : _syncNow,
                  child: Text(
                    running ? 'En curso…' : 'Sincronizar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: running ? cs.onSurfaceVariant : cs.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
