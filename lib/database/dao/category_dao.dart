import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../database_helper.dart';
import '../models/category_model.dart';

class DefaultCategoryNotReadyException implements Exception {
  @override
  String toString() =>
      'Tu cuenta aún se está preparando. Inténtalo en unos segundos.';
}

class CategoryDao {
  final DatabaseHelper _helper;
  final Uuid _uuid = const Uuid();

  CategoryDao(this._helper);

  Database get _db => _helper.db;

  static String _now() => DateTime.now().toUtc().toIso8601String();

  // ─── CREATE ───────────────────────────────────────────────────────────────

  String insert(CategoryModel category) {
    final String id = category.id ?? _uuid.v4();
    final String now = _now();

    _db.execute(
      '''
      INSERT INTO ${DatabaseHelper.tableCategories}
        (id, user_id, title, icon, color, is_default,
         created_at, updated_at, dirty, version, sync_error)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1, NULL);
    ''',
      [
        id,
        category.userId,
        category.title,
        category.icon,
        category.color,
        category.isDefault ? 1 : 0,
        category.createdAt.isEmpty ? now : category.createdAt,
        now,
      ],
    );

    return id;
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  List<CategoryModel> getAll() {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableCategories} '
      'WHERE deleted_at IS NULL ORDER BY is_default DESC, title;',
    );
    return rows.map(_rowToModel).toList();
  }

  CategoryModel? getById(String id) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableCategories} '
      'WHERE id = ? AND deleted_at IS NULL;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  /// Incluye filas borradas lógicamente (necesario para sync/down).
  CategoryModel? getByIdIncludingDeleted(String id) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableCategories} WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  String? getDefaultCategoryId() => _helper.getDefaultCategoryId();

  CategoryModel? getDefault() {
    final id = _helper.getDefaultCategoryId();
    if (id == null) return null;
    return getById(id);
  }

  List<CategoryModel> getDirty({int limit = 100}) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableCategories} '
      'WHERE dirty = 1 AND sync_error IS NULL '
      'ORDER BY updated_at, id LIMIT ?;',
      [limit],
    );
    return rows.map(_rowToModel).toList();
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  void update(CategoryModel category) {
    final String id = category.id!;
    _assertNotDefault(id);

    final String now = _now();
    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableCategories}
      SET title = ?, icon = ?, color = ?,
          dirty = 1, version = version + 1,
          updated_at = ?, sync_error = NULL
      WHERE id = ? AND deleted_at IS NULL;
    ''',
      [category.title, category.icon, category.color, now, id],
    );
  }

  /// Solo la sincronización (descarga) puede tocar la categoría por defecto.
  void updateFromServer(CategoryModel category) {
    final String now = _now();
    final String id = category.id!;
    _db.execute(
      '''
      INSERT INTO ${DatabaseHelper.tableCategories}
        (id, user_id, title, icon, color, is_default,
         created_at, updated_at, deleted_at, dirty, version, sync_error)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, NULL)
      ON CONFLICT(id) DO UPDATE SET
        user_id = excluded.user_id,
        title = excluded.title,
        icon = excluded.icon,
        color = excluded.color,
        is_default = excluded.is_default,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at,
        dirty = 0,
        version = excluded.version,
        sync_error = NULL;
    ''',
      [
        id,
        category.userId,
        category.title,
        category.icon,
        category.color,
        category.isDefault ? 1 : 0,
        category.createdAt,
        category.updatedAt.isEmpty ? now : category.updatedAt,
        category.deletedAt,
        category.version,
      ],
    );
  }

  void markSynced(String id, int expectedVersion) {
    _db.execute(
      'UPDATE ${DatabaseHelper.tableCategories} '
      'SET dirty = 0, sync_error = NULL '
      'WHERE id = ? AND version = ? AND dirty = 1;',
      [id, expectedVersion],
    );
  }

  void setSyncError(String id, String error) {
    _db.execute(
      'UPDATE ${DatabaseHelper.tableCategories} SET sync_error = ? WHERE id = ?;',
      [error, id],
    );
  }

  // ─── DELETE (lógico) ──────────────────────────────────────────────────────

  /// Borra la categoría y reasigna sus links a la por defecto (una transacción).
  void deleteAndReassignLinks(String categoryId) {
    _assertNotDefault(categoryId);

    final String? defaultId = _helper.getDefaultCategoryId();
    if (defaultId == null) {
      throw DefaultCategoryNotReadyException();
    }
    if (defaultId == categoryId) {
      throw StateError('Cannot reassign into the deleted category.');
    }

    final String now = _now();
    _db.execute('BEGIN;');
    try {
      _db.execute(
        '''
        UPDATE ${DatabaseHelper.tableLinks}
        SET category_id = ?,
            dirty = 1, version = version + 1,
            updated_at = ?, sync_error = NULL
        WHERE category_id = ? AND deleted_at IS NULL;
      ''',
        [defaultId, now, categoryId],
      );

      _db.execute(
        '''
        UPDATE ${DatabaseHelper.tableCategories}
        SET deleted_at = ?, dirty = 1, version = version + 1,
            updated_at = ?, sync_error = NULL
        WHERE id = ? AND deleted_at IS NULL;
      ''',
        [now, now, categoryId],
      );

      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Borra la categoría y todos sus links (lógico, una transacción).
  void deleteWithAllLinks(String categoryId) {
    _assertNotDefault(categoryId);

    final String now = _now();
    _db.execute('BEGIN;');
    try {
      _db.execute(
        '''
        UPDATE ${DatabaseHelper.tableLinks}
        SET deleted_at = ?, dirty = 1, version = version + 1,
            updated_at = ?, sync_error = NULL
        WHERE category_id = ? AND deleted_at IS NULL;
      ''',
        [now, now, categoryId],
      );

      _db.execute(
        '''
        UPDATE ${DatabaseHelper.tableCategories}
        SET deleted_at = ?, dirty = 1, version = version + 1,
            updated_at = ?, sync_error = NULL
        WHERE id = ? AND deleted_at IS NULL;
      ''',
        [now, now, categoryId],
      );

      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  void _assertNotDefault(String categoryId) {
    final rows = _db.select(
      'SELECT is_default FROM ${DatabaseHelper.tableCategories} WHERE id = ?;',
      [categoryId],
    );
    if (rows.isEmpty) {
      throw StateError('Category not found: $categoryId');
    }
    if ((rows.first['is_default'] as int? ?? 0) == 1) {
      throw StateError('Cannot modify the default category.');
    }
  }

  CategoryModel _rowToModel(Row row) => CategoryModel.fromMap({
    'id': row['id'],
    'user_id': row['user_id'],
    'title': row['title'],
    'icon': row['icon'],
    'color': row['color'],
    'is_default': row['is_default'],
    'created_at': row['created_at'],
    'updated_at': row['updated_at'],
    'deleted_at': row['deleted_at'],
    'dirty': row['dirty'],
    'version': row['version'],
    'sync_error': row['sync_error'],
  });
}
