import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../database_helper.dart';
import '../models/link_model.dart';
import 'category_dao.dart' show DefaultCategoryNotReadyException;

class LinkDao {
  final DatabaseHelper _helper;
  final Uuid _uuid = const Uuid();

  LinkDao(this._helper);

  Database get _db => _helper.db;

  static String _now() => DateTime.now().toUtc().toIso8601String();

  // ─── CREATE ───────────────────────────────────────────────────────────────

  String insert(LinkModel link) {
    final String? defaultId = _helper.getDefaultCategoryId();
    if (defaultId == null) {
      throw DefaultCategoryNotReadyException();
    }

    final String id = link.id ?? _uuid.v4();
    final String now = _now();
    final String categoryId =
        link.categoryId.isEmpty ? defaultId : link.categoryId;

    _db.execute(
      '''
      INSERT INTO ${DatabaseHelper.tableLinks}
        (id, user_id, category_id, status, title, description, url,
         created_at, updated_at, dirty, version, sync_error)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1, NULL);
    ''',
      [
        id,
        link.userId,
        categoryId,
        link.status.value,
        link.title,
        link.description,
        link.url,
        link.createdAt.isEmpty ? now : link.createdAt,
        now,
      ],
    );

    return id;
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  List<LinkModel> getAll() {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} '
      'WHERE deleted_at IS NULL ORDER BY id;',
    );
    return rows.map(_rowToModel).toList();
  }

  LinkModel? getById(String id) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} '
      'WHERE id = ? AND deleted_at IS NULL;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  /// Incluye filas borradas lógicamente (necesario para sync/down).
  LinkModel? getByIdIncludingDeleted(String id) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  List<LinkModel> getByCategory(String categoryId) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} '
      'WHERE category_id = ? AND deleted_at IS NULL ORDER BY id;',
      [categoryId],
    );
    return rows.map(_rowToModel).toList();
  }

  List<LinkModel> getByStatus(LinkStatus status) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} '
      'WHERE status = ? AND deleted_at IS NULL ORDER BY id;',
      [status.value],
    );
    return rows.map(_rowToModel).toList();
  }

  List<LinkModel> getByCategoryAndStatus(
    String categoryId,
    LinkStatus status,
  ) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} '
      'WHERE category_id = ? AND status = ? AND deleted_at IS NULL '
      'ORDER BY id;',
      [categoryId, status.value],
    );
    return rows.map(_rowToModel).toList();
  }

  List<LinkModel> getDirty({int limit = 100, bool publicOnly = false}) {
    final String statusFilter = publicOnly ? " AND status = 'public'" : '';
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} '
      'WHERE dirty = 1 AND sync_error IS NULL$statusFilter '
      'ORDER BY updated_at, id LIMIT ?;',
      [limit],
    );
    return rows.map(_rowToModel).toList();
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  void update(LinkModel link) {
    final String id = link.id!;
    final String now = _now();
    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableLinks}
      SET title = ?, description = ?, url = ?, category_id = ?, status = ?,
          dirty = 1, version = version + 1,
          updated_at = ?, sync_error = NULL
      WHERE id = ? AND deleted_at IS NULL;
    ''',
      [
        link.title,
        link.description,
        link.url,
        link.categoryId,
        link.status.value,
        now,
        id,
      ],
    );
  }

  void updateStatus(String linkId, LinkStatus status) {
    final String now = _now();
    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableLinks}
      SET status = ?, dirty = 1, version = version + 1,
          updated_at = ?, sync_error = NULL
      WHERE id = ? AND deleted_at IS NULL;
    ''',
      [status.value, now, linkId],
    );
  }

  void updateFromServer(LinkModel link) {
    final String now = _now();
    _db.execute(
      '''
      INSERT INTO ${DatabaseHelper.tableLinks}
        (id, user_id, category_id, status, title, description, url,
         created_at, updated_at, deleted_at, dirty, version, sync_error)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, NULL)
      ON CONFLICT(id) DO UPDATE SET
        user_id = excluded.user_id,
        category_id = excluded.category_id,
        status = excluded.status,
        title = excluded.title,
        description = excluded.description,
        url = excluded.url,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at,
        dirty = 0,
        version = excluded.version,
        sync_error = NULL;
    ''',
      [
        link.id,
        link.userId,
        link.categoryId,
        link.status.value,
        link.title,
        link.description,
        link.url,
        link.createdAt,
        link.updatedAt.isEmpty ? now : link.updatedAt,
        link.deletedAt,
        link.version,
      ],
    );
  }

  void markSynced(String id, int expectedVersion) {
    _db.execute(
      'UPDATE ${DatabaseHelper.tableLinks} '
      'SET dirty = 0, sync_error = NULL '
      'WHERE id = ? AND version = ? AND dirty = 1;',
      [id, expectedVersion],
    );
  }

  void setSyncError(String id, String error) {
    _db.execute(
      'UPDATE ${DatabaseHelper.tableLinks} SET sync_error = ? WHERE id = ?;',
      [error, id],
    );
  }

  // ─── DELETE (lógico) ──────────────────────────────────────────────────────

  void delete(String linkId) {
    final String now = _now();
    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableLinks}
      SET deleted_at = ?, dirty = 1, version = version + 1,
          updated_at = ?, sync_error = NULL
      WHERE id = ? AND deleted_at IS NULL;
    ''',
      [now, now, linkId],
    );
  }

  void deleteByCategory(String categoryId) {
    final String now = _now();
    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableLinks}
      SET deleted_at = ?, dirty = 1, version = version + 1,
          updated_at = ?, sync_error = NULL
      WHERE category_id = ? AND deleted_at IS NULL;
    ''',
      [now, now, categoryId],
    );
  }

  void deletePrivateLinks() {
    final String now = _now();
    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableLinks}
      SET deleted_at = ?, dirty = 1, version = version + 1,
          updated_at = ?, sync_error = NULL
      WHERE status = ? AND deleted_at IS NULL;
    ''',
      [now, now, LinkStatus.private.value],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  LinkModel _rowToModel(Row row) => LinkModel.fromMap({
    'id': row['id'],
    'user_id': row['user_id'],
    'title': row['title'],
    'description': row['description'],
    'url': row['url'],
    'category_id': row['category_id'],
    'status': row['status'],
    'created_at': row['created_at'],
    'updated_at': row['updated_at'],
    'deleted_at': row['deleted_at'],
    'dirty': row['dirty'],
    'version': row['version'],
    'sync_error': row['sync_error'],
  });
}
