import 'dart:async';

import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/database/repositories/repositories.dart';
import 'package:link_chest/database/repositories/sqlite_repositories.dart';
import 'package:link_chest/services/sync/remote_sync_api.dart';
import 'package:sqlite3/sqlite3.dart';

/// Excepción de sesión inválida (401 / token vencido).
class SyncAuthException implements Exception {
  SyncAuthException([this.message = 'Sesión inválida']);
  final String message;

  @override
  String toString() => message;
}

/// Excepción de red (sin conexión, timeout, 5xx).
class SyncNetworkException implements Exception {
  SyncNetworkException([this.message = 'Error de red']);
  final String message;

  @override
  String toString() => message;
}

/// Resultado de una ronda completa de sync.
class SyncRunResult {
  const SyncRunResult({
    this.uploadedCategories = 0,
    this.uploadedLinks = 0,
    this.downloadedCategories = 0,
    this.downloadedLinks = 0,
  });

  final int uploadedCategories;
  final int uploadedLinks;
  final int downloadedCategories;
  final int downloadedLinks;

  int get downloadedTotal => downloadedCategories + downloadedLinks;
  int get uploadedTotal => uploadedCategories + uploadedLinks;
}

/// Lógica de subida (dirty → servidor) y descarga (cursor → local).
/// No decide cuándo corre: eso lo hace `SyncService`.
class SyncEngine {
  SyncEngine({
    required this.helper,
    required this.api,
    this.uploadBatch = 100,
    this.downloadBatch = 500,
  });

  /// Solapamiento al reiniciar el cursor (transacciones tardías del servidor).
  static const Duration cursorOverlap = Duration(minutes: 2);

  final DatabaseHelper helper;
  final RemoteSyncApi api;
  final int uploadBatch;
  final int downloadBatch;

  late final CategoryRepository _categories =
      SqliteCategoryRepository.withHelper(helper);
  late final LinkRepository _links =
      SqliteLinkRepository.withHelper(helper);

  Database get _db => helper.db;

  /// Sube + baja una ronda completa.
  Future<SyncRunResult> run() async {
    final upCats = await _uploadCategories();
    final upLinks = await _uploadLinks();
    final downCats = await _downloadCategories();
    final downLinks = await _downloadLinks();

    helper.setSyncState(
      'last_synced_at',
      DateTime.now().toUtc().toIso8601String(),
    );
    if (helper.getSyncState('initial_sync_done') != '1') {
      helper.setSyncState('initial_sync_done', '1');
    }

    return SyncRunResult(
      uploadedCategories: upCats,
      uploadedLinks: upLinks,
      downloadedCategories: downCats,
      downloadedLinks: downLinks,
    );
  }

  // ─── SUBIDA ───────────────────────────────────────────────────────────────

  Future<int> _uploadCategories() async {
    var total = 0;
    while (true) {
      final batch = _categories.getDirty(limit: uploadBatch);
      if (batch.isEmpty) break;
      total += await _uploadCategoryBatch(batch);
      if (batch.length < uploadBatch) break;
    }
    return total;
  }

  Future<int> _uploadLinks() async {
    var total = 0;
    while (true) {
      // Solo públicos: la bóveda privada no se sincroniza en v1.
      final batch = _links.getDirty(limit: uploadBatch, publicOnly: true);
      if (batch.isEmpty) break;
      total += await _uploadLinkBatch(batch);
      if (batch.length < uploadBatch) break;
    }
    return total;
  }

  Future<int> _uploadCategoryBatch(List<CategoryModel> batch) async {
    final payloads = <Map<String, dynamic>>[];
    final versions = <String, int>{};
    for (final c in batch) {
      payloads.add(_categoryPayload(c));
      versions[c.id!] = c.version;
    }

    try {
      await api.upsertCategories(payloads);
      versions.forEach(_categories.markSynced);
      return payloads.length;
    } catch (e) {
      if (!isDefinitiveError(e)) rethrow;
      return _isolateRows<CategoryModel>(
        rows: batch,
        payload: _categoryPayload,
        upsert: api.upsertCategories,
        markSynced: _categories.markSynced,
        setSyncError: _categories.setSyncError,
        versions: versions,
      );
    }
  }

  Future<int> _uploadLinkBatch(List<LinkModel> batch) async {
    final payloads = <Map<String, dynamic>>[];
    final versions = <String, int>{};
    for (final l in batch) {
      payloads.add(_linkPayload(l));
      versions[l.id!] = l.version;
    }

    try {
      await api.upsertLinks(payloads);
      versions.forEach(_links.markSynced);
      return payloads.length;
    } catch (e) {
      if (!isDefinitiveError(e)) rethrow;
      return _isolateRows<LinkModel>(
        rows: batch,
        payload: _linkPayload,
        upsert: api.upsertLinks,
        markSynced: _links.markSynced,
        setSyncError: _links.setSyncError,
        versions: versions,
      );
    }
  }

  /// Error definitivo (restricción 23* o RLS 42501): reintenta fila a fila.
  Future<int> _isolateRows<T>({
    required List<T> rows,
    required Map<String, dynamic> Function(T row) payload,
    required Future<void> Function(List<Map<String, dynamic>>) upsert,
    required void Function(String id, int expectedVersion) markSynced,
    required void Function(String id, String error) setSyncError,
    required Map<String, int> versions,
  }) async {
    var ok = 0;
    for (final row in rows) {
      final id = _idOf(row);
      final p = [payload(row)];
      try {
        await upsert(p);
        markSynced(id, versions[id]!);
        ok++;
      } catch (rowError) {
        if (isDefinitiveError(rowError)) {
          setSyncError(id, rowError.toString());
        } else {
          rethrow;
        }
      }
    }
    return ok;
  }

  String _idOf(Object? row) {
    if (row is CategoryModel) return row.id!;
    if (row is LinkModel) return row.id!;
    throw ArgumentError('Fila desconocida: $row');
  }

  Map<String, dynamic> _categoryPayload(CategoryModel c) => {
    'id': c.id,
    'user_id': c.userId,
    'title': c.title,
    'icon': c.icon,
    'color': c.color,
    // RLS: el usuario nunca crea/edita la default.
    'is_default': false,
    'created_at': c.createdAt,
    'deleted_at': c.deletedAt,
  };

  Map<String, dynamic> _linkPayload(LinkModel l) => {
    'id': l.id,
    'user_id': l.userId,
    'category_id': l.categoryId,
    'status': l.status.value,
    'title': l.title,
    'url': l.url,
    'description': l.description,
    'created_at': l.createdAt,
    'deleted_at': l.deletedAt,
  };

  // ─── DESCARGA ─────────────────────────────────────────────────────────────

  Future<int> _downloadCategories() async {
    var applied = 0;
    var start = _readCursorStart('categories');

    while (true) {
      final page = await api.fetchCategories(
        updatedAt: start?.at,
        id: start?.id,
        limit: downloadBatch,
      );

      applied += _applyPage(
        page: page,
        parse: _parseCategory,
        isDirty: (id) =>
            _categories.getByIdIncludingDeleted(id)?.isPendingSync ?? false,
        apply: _categories.updateFromServer,
      );

      if (page.isNotEmpty) {
        final at = page.last['updated_at'] as String;
        final id = page.last['id'] as String;
        _advanceCursor('categories', at, id);
        start = (at: at, id: id);
      }

      if (page.length < downloadBatch) break;
    }
    return applied;
  }

  Future<int> _downloadLinks() async {
    var applied = 0;
    var start = _readCursorStart('links');

    while (true) {
      final page = await api.fetchLinks(
        updatedAt: start?.at,
        id: start?.id,
        limit: downloadBatch,
      );

      applied += _applyPage(
        page: page,
        parse: _parseLink,
        isDirty: (id) =>
            _links.getByIdIncludingDeleted(id)?.isPendingSync ?? false,
        apply: _links.updateFromServer,
      );

      if (page.isNotEmpty) {
        final at = page.last['updated_at'] as String;
        final id = page.last['id'] as String;
        _advanceCursor('links', at, id);
        start = (at: at, id: id);
      }

      if (page.length < downloadBatch) break;
    }
    return applied;
  }

  /// Cursor con solapamiento de 2 minutos; null = desde el inicio.
  ({String at, String id})? _readCursorStart(String table) {
    final at = helper.getSyncState('${table}_cursor_updated_at');
    final id = helper.getSyncState('${table}_cursor_id');
    if (at == null || id == null) return null;
    final base = DateTime.tryParse(at);
    if (base == null) return (at: at, id: id);
    final overlapped = base.toUtc().subtract(cursorOverlap);
    return (at: overlapped.toIso8601String(), id: id);
  }

  /// Guarda el cursor solo si avanza (nunca retrocede).
  void _advanceCursor(String table, String at, String id) {
    final keyAt = '${table}_cursor_updated_at';
    final keyId = '${table}_cursor_id';
    final curAt = helper.getSyncState(keyAt);
    final curId = helper.getSyncState(keyId);
    if (curAt != null) {
      final cmp = at.compareTo(curAt);
      if (cmp < 0) return;
      if (cmp == 0 && curId != null && id.compareTo(curId) <= 0) return;
    }
    helper.setSyncState(keyAt, at);
    helper.setSyncState(keyId, id);
  }

  int _applyPage<T>({
    required List<Map<String, dynamic>> page,
    required T Function(Map<String, dynamic>) parse,
    required bool Function(String id) isDirty,
    required void Function(T row) apply,
  }) {
    if (page.isEmpty) return 0;

    var applied = 0;
    _db.execute('BEGIN;');
    try {
      for (final raw in page) {
        final id = raw['id'] as String;
        // El cambio local pendiente gana hasta que se suba.
        if (isDirty(id)) continue;
        apply(parse(raw));
        applied++;
      }
      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
    return applied;
  }

  CategoryModel _parseCategory(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc().toIso8601String();
    return CategoryModel.fromMap({
      ...row,
      'title': row['title'] as String? ?? '',
      'icon': row['icon'] as String? ?? '📂',
      'color': row['color'] as String? ?? '#000000ff',
      'is_default': row['is_default'] == true || row['is_default'] == 1
          ? 1
          : 0,
      'created_at': row['created_at'] as String? ?? now,
      'updated_at': row['updated_at'] as String? ?? now,
      'dirty': 0,
      'version': 0,
      'sync_error': null,
    });
  }

  LinkModel _parseLink(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc().toIso8601String();
    return LinkModel.fromMap({
      ...row,
      'title': row['title'] as String? ?? '',
      'url': row['url'] as String? ?? '',
      'category_id': row['category_id'] as String? ?? '',
      'status': row['status'] as String? ?? 'public',
      'created_at': row['created_at'] as String? ?? now,
      'updated_at': row['updated_at'] as String? ?? now,
      'dirty': 0,
      'version': 0,
      'sync_error': null,
    });
  }

  // ─── CLASIFICACIÓN DE ERRORES ─────────────────────────────────────────────

  /// Código Postgres: `23*` (restricciones) o `42501` (RLS).
  static bool isDefinitiveError(Object error) {
    final code = postgresCode(error);
    if (code == null) return false;
    return code.startsWith('23') || code == '42501';
  }

  static bool isAuthError(Object error) {
    if (error is SyncAuthException) return true;
    final code = postgresCode(error);
    if (code == 'PGRST301' || code == '401') return true;
    final name = error.runtimeType.toString();
    return name.contains('AuthException') || name.contains('AuthRetryable');
  }

  static bool isNetworkError(Object error) {
    if (error is SyncNetworkException) return true;
    if (error is TimeoutException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('failed host') ||
        text.contains('connection') ||
        text.contains('network') ||
        text.contains('clientexception');
  }

  static String? postgresCode(Object error) {
    try {
      // ignore: avoid_dynamic_calls
      final dynamic code = (error as dynamic).code;
      if (code is String) return code;
    } catch (_) {}
    return null;
  }
}
