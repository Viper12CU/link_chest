import 'package:flutter/material.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

/// Traduce `sync_error` crudo a texto claro para el usuario.
String humanSyncError(String raw) {
  final code = _postgresCode(raw);
  if (code != null && code.startsWith('23')) {
    return 'El servidor rechazó este cambio porque no cumple las reglas de datos';
  }
  if (code == '42501') {
    return 'No tienes permiso para este cambio';
  }
  return 'No se pudo sincronizar';
}

/// Extrae el código Postgres de un `sync_error` guardado
/// (`PostgrestException(..., code: 23505, ...)` o `PostgrestException(23505): ...`).
String? _postgresCode(String raw) {
  final field = RegExp(r'code:\s*([^\s,)]+)').firstMatch(raw);
  if (field != null && field.group(1) != 'null') return field.group(1);
  final compact = RegExp(r'PostgrestException\(([^\s:)]+)\)').firstMatch(raw);
  if (compact != null) return compact.group(1);
  return null;
}

/// `lastSyncedAt` (ISO) como texto relativo en español.
String relativeSyncTime(String? iso) {
  if (iso == null || iso.isEmpty) return 'Aún no se ha sincronizado';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return 'Aún no se ha sincronizado';

  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Hace un momento';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
  return 'Hace ${diff.inDays} días';
}

/// Muestra el aviso de guardado offline si el dispositivo no tiene conexión.
/// El guardado local siempre se completa; esto solo informa al usuario.
Future<void> showOfflineSaveToastIfNeeded(BuildContext context) async {
  if (!context.mounted) return;
  final online = await SyncService.instance.isOnline();
  if (!online && context.mounted) {
    ToastifyFlutter.info(
      context,
      message: 'Guardado sin conexión; se sincronizará cuando haya internet.',
      duration: 4,
      style: ToastStyle.flat,
    );
  }
}
