import 'package:flutter/material.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/services/backup_service/backup_service.dart';
import 'package:link_chest/services/backup_service/sqlite_backup_store.dart';
import 'package:link_chest/widgets/atoms/profile_item.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

class ProfileExportData extends StatefulWidget {
  const ProfileExportData({super.key});

  @override
  State<ProfileExportData> createState() => _ProfileExportDataState();
}

class _ProfileExportDataState extends State<ProfileExportData> {
  final BackupService _service = BackupService(
    SqliteBackupStore(DatabaseHelper()),
  );

  bool _busy = false;

  void _snack(String message) {
    ToastifyFlutter.info(context, message: message);
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final saved = await _service.exportWithPicker();
      if (!mounted) return;
      // saved == null -> el usuario canceló: no se muestra nada.
      if (saved != null) _snack('Respaldo guardado correctamente');
    } on BackupException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      // merge: solo añade lo que falta, no borra nada.
      final result = await _service.importWithPicker(mode: ImportMode.merge);
      if (!mounted || result == null) return; // canceló

      // Recarga tus Providers para que la UI vea los datos nuevos:
      // context.read<CategoryProvider>().loadCategories();
      // context.read<LinkProvider>().loadLinks();

      var message = result.linksAdded == 0
          ? 'No había links nuevos para importar'
          : 'Se importaron ${result.linksAdded} links';
      if (result.linksSkipped > 0) {
        message += ' (${result.linksSkipped} ya existían)';
      }
      if (result.warnings.isNotEmpty) {
        message += ' · ${result.warnings.length} avisos';
      }
      _snack(message);
    } on BackupException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      spacing: 10.0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MIS DATOS',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                ProfileItem(
                  icon: Icons.download,
                  title: "Exporta tus links",
                  textLabel: "Links y categorías en formato JSON",
                  action: IconButton(
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outline),
                ProfileItem(
                  icon: Icons.upload_file_outlined,
                  title: "Importar links",
                  textLabel: "Desde un respaldo en formato JSON",
                  action: IconButton(
                    onPressed: _busy ? null : _import,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}