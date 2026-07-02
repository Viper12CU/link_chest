import 'package:sqlite3/sqlite3.dart';
import '../database_helper.dart';
import '../models/link_model.dart';

class LinkDao {
  final DatabaseHelper _helper;

  LinkDao(this._helper);

  Database get _db => _helper.db;

  // ─── CREATE ───────────────────────────────────────────────────────────────

  int insert(LinkModel link) {
    _db.execute('''
      INSERT INTO ${DatabaseHelper.tableLinks}
        (title, description, url, category_id, status)
      VALUES (?, ?, ?, ?, ?);
    ''', [
      link.title,
      link.description,
      link.url,
      link.categoryId,
      link.status.value,
    ]);

    return _db.lastInsertRowId;
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  List<LinkModel> getAll() {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} ORDER BY id;',
    );
    return rows.map(_rowToModel).toList();
  }

  LinkModel? getById(int id) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  List<LinkModel> getByCategory(int categoryId) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} WHERE category_id = ? ORDER BY id;',
      [categoryId],
    );
    return rows.map(_rowToModel).toList();
  }

  List<LinkModel> getByStatus(LinkStatus status) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableLinks} WHERE status = ? ORDER BY id;',
      [status.value],
    );
    return rows.map(_rowToModel).toList();
  }

  List<LinkModel> getByCategoryAndStatus(int categoryId, LinkStatus status) {
    final rows = _db.select(
      '''
      SELECT * FROM ${DatabaseHelper.tableLinks}
      WHERE category_id = ? AND status = ?
      ORDER BY id;
      ''',
      [categoryId, status.value],
    );
    return rows.map(_rowToModel).toList();
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  void update(LinkModel link) {
    assert(link.id != null, 'LinkModel must have an id to update');

    _db.execute('''
      UPDATE ${DatabaseHelper.tableLinks}
      SET title = ?, description = ?, url = ?, category_id = ?, status = ?
      WHERE id = ?;
    ''', [
      link.title,
      link.description,
      link.url,
      link.categoryId,
      link.status.value,
      link.id,
    ]);
  }

  void updateStatus(int linkId, LinkStatus status) {
    _db.execute('''
      UPDATE ${DatabaseHelper.tableLinks}
      SET status = ?
      WHERE id = ?;
    ''', [status.value, linkId]);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  void delete(int linkId) {
    _db.execute(
      'DELETE FROM ${DatabaseHelper.tableLinks} WHERE id = ?;',
      [linkId],
    );
  }

  void deleteByCategory(int categoryId) {
    _db.execute(
      'DELETE FROM ${DatabaseHelper.tableLinks} WHERE category_id = ?;',
      [categoryId],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  LinkModel _rowToModel(Row row) => LinkModel.fromMap({
        'id': row['id'],
        'title': row['title'],
        'description': row['description'],
        'url': row['url'],
        'category_id': row['category_id'],
        'status': row['status'],
      });
}
