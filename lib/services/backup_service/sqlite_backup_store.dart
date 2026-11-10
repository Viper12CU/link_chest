// lib/services/sqlite_backup_store.dart
//
// Adaptador de BackupStore sobre tu DatabaseHelper (paquete sqlite3, API
// síncrona). Ajusta las rutas de import a las de tu proyecto.

import 'package:link_chest/database/database_helper.dart'; // <- ajusta la ruta
import 'package:link_chest/services/backup_service/backup_service.dart'; // <- ajusta la ruta
import 'package:sqlite3/sqlite3.dart';

class SqliteBackupStore extends BackupStore {
  SqliteBackupStore(this._helper);

  final DatabaseHelper _helper;

  Database get _db => _helper.db;

  static const _cats = DatabaseHelper.tableCategories;
  static const _links = DatabaseHelper.tableLinks;

  @override
  String get defaultCategoryId => DatabaseHelper.defaultCategoryId.toString();

  @override
  Future<List<BackupCategory>> readCategories() async {
    final rows = _db.select(
      'SELECT id, title, icon, color FROM $_cats ORDER BY id',
    );
    return rows
        .map((r) => BackupCategory(
              id: (r['id'] as int).toString(),
              title: r['title'] as String,
              icon: r['icon'] as String,
              color: r['color'] as String,
              isDefault: r['id'] == DatabaseHelper.defaultCategoryId,
            ))
        .toList();
  }

  @override
  Future<List<BackupLink>> readLinks() async {
    final rows = _db.select(
      'SELECT id, title, description, url, category_id, status '
      'FROM $_links ORDER BY id',
    );
    return rows
        .map((r) => BackupLink(
              id: (r['id'] as int).toString(),
              categoryId: (r['category_id'] as int).toString(),
              title: r['title'] as String,
              url: r['url'] as String,
              description: r['description'] as String?,
              isPrivate: r['status'] == 'private',
            ))
        .toList();
  }

  @override
  Future<String> insertCategory(BackupCategory category) async {
    _db.execute(
      'INSERT INTO $_cats (title, icon, color) VALUES (?, ?, ?)',
      [category.title, category.icon, category.color],
    );
    return _db.lastInsertRowId.toString();
  }

  @override
  Future<void> insertLinks(List<BackupLink> links) async {
    for (final l in links) {
      _db.execute(
        'INSERT INTO $_links (title, description, url, category_id, status) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          l.title,
          l.description,
          l.url,
          int.parse(l.categoryId),
          l.isPrivate ? 'private' : 'public',
        ],
      );
    }
  }

  @override
  Future<void> clearAll() async {
    // Primero los links (por la clave foránea), luego las categorías.
    _db.execute('DELETE FROM $_links');
    _db.execute(
      'DELETE FROM $_cats WHERE id != ?',
      [DatabaseHelper.defaultCategoryId],
    );
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
