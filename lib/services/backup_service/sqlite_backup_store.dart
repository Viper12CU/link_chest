// lib/services/sqlite_backup_store.dart
//
// Adaptador de BackupStore sobre DatabaseHelper (sqlite3, API síncrona).
// Esquema v2: IDs TEXT (UUID), borrado lógico, dirty=1 en cada escritura.

import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/services/backup_service/backup_service.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class SqliteBackupStore extends BackupStore {
  SqliteBackupStore(this._helper);

  final DatabaseHelper _helper;
  final Uuid _uuid = const Uuid();

  Database get _db => _helper.db;

  static const _cats = DatabaseHelper.tableCategories;
  static const _links = DatabaseHelper.tableLinks;

  static String _now() => DateTime.now().toUtc().toIso8601String();

  String _requireUserId() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('No hay sesión activa para importar datos.');
    }
    return userId;
  }

  @override
  String get defaultCategoryId {
    final id = _helper.getDefaultCategoryId();
    if (id == null) {
      throw StateError(
        'La categoría por defecto aún no está disponible. '
        'Espera a la primera sincronización.',
      );
    }
    return id;
  }

  @override
  Future<List<BackupCategory>> readCategories() async {
    final rows = _db.select(
      'SELECT id, title, icon, color, is_default FROM $_cats '
      'WHERE deleted_at IS NULL ORDER BY is_default DESC, title',
    );
    return rows
        .map((r) => BackupCategory(
              id: r['id'] as String,
              title: r['title'] as String,
              icon: r['icon'] as String,
              color: r['color'] as String,
              isDefault: (r['is_default'] as int? ?? 0) == 1,
            ))
        .toList();
  }

  @override
  Future<List<BackupLink>> readLinks() async {
    final rows = _db.select(
      'SELECT id, title, description, url, category_id, status '
      'FROM $_links WHERE deleted_at IS NULL ORDER BY id',
    );
    return rows
        .map((r) => BackupLink(
              id: r['id'] as String,
              categoryId: r['category_id'] as String,
              title: r['title'] as String,
              url: r['url'] as String,
              description: r['description'] as String?,
              isPrivate: r['status'] == 'private',
            ))
        .toList();
  }

  @override
  Future<String> insertCategory(BackupCategory category) async {
    final String userId = _requireUserId();
    final String id = _uuid.v4();
    final String now = _now();

    _db.execute(
      'INSERT INTO $_cats '
      '(id, user_id, title, icon, color, is_default, created_at, updated_at, '
      ' dirty, version, sync_error) '
      'VALUES (?, ?, ?, ?, ?, 0, ?, ?, 1, 1, NULL)',
      [id, userId, category.title, category.icon, category.color, now, now],
    );
    await SyncService.instance.requestSync();
    return id;
  }

  @override
  Future<void> insertLinks(List<BackupLink> links) async {
    final String userId = _requireUserId();
    final String now = _now();

    for (final l in links) {
      final String id = _uuid.v4();
      _db.execute(
        'INSERT INTO $_links '
        '(id, user_id, category_id, status, title, description, url, '
        ' created_at, updated_at, dirty, version, sync_error) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1, NULL)',
        [
          id,
          userId,
          l.categoryId,
          l.isPrivate ? 'private' : 'public',
          l.title,
          l.description,
          l.url,
          now,
          now,
        ],
      );
    }
    await SyncService.instance.requestSync();
  }

  @override
  Future<void> clearAll() async {
    final String now = _now();
    _db.execute('BEGIN;');
    try {
      // Borrado lógico de links; la default se conserva viva.
      _db.execute(
        'UPDATE $_links SET deleted_at = ?, dirty = 1, version = version + 1, '
        'updated_at = ?, sync_error = NULL WHERE deleted_at IS NULL;',
        [now, now],
      );
      _db.execute(
        'UPDATE $_cats SET deleted_at = ?, dirty = 1, version = version + 1, '
        'updated_at = ?, sync_error = NULL '
        'WHERE is_default = 0 AND deleted_at IS NULL;',
        [now, now],
      );
      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
    await SyncService.instance.requestSync();
  }

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    _db.execute('BEGIN');
    try {
      final result = await action();
      _db.execute('COMMIT');
      return result;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}
