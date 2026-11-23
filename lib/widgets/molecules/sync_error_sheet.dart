import 'package:flutter/material.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/utils/shared/sync_ui_helpers.dart';

/// Hoja con la lista de cambios que fallaron al sincronizar.
/// Permite reintentar todo o descartar (decisión: limpiar sync_error + dirty).
class SyncErrorSheet extends StatefulWidget {
  const SyncErrorSheet({super.key});

  static Future<T?> show<T>({required BuildContext context}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SyncErrorSheet(),
    );
  }

  @override
  State<SyncErrorSheet> createState() => _SyncErrorSheetState();
}

class _SyncErrorSheetState extends State<SyncErrorSheet> {
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

  Future<void> _retryAll() async {
    await _sync.retryErrored();
    if (mounted) Navigator.pop(context);
  }

  void _discardAll() {
    _sync.discardErrored();
    if (mounted) Navigator.pop(context);
  }

  void _discardOne(SyncErrorItem item) {
    _sync.discardError(item);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final items = _sync.errorItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.error_outline, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text('Errores de sincronización', style: theme.textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay cambios con error.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final typeLabel = item.type == SyncErrorType.category
                      ? 'Categoría'
                      : 'Link';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.isEmpty ? '(sin título)' : item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$typeLabel · ${humanSyncError(item.error)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Descartar',
                          onPressed: () => _discardOne(item),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (items.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _discardAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('Descartar'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: items.isEmpty ? null : _retryAll,
                  child: const Text('Reintentar todo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
