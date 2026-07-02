import 'package:sqlite3/sqlite3.dart';
import '../database_helper.dart';
import '../models/category_model.dart';

class CategoryDao {
  final DatabaseHelper _helper;

  CategoryDao(this._helper);

  Database get _db => _helper.db;

  // ─── CREATE ───────────────────────────────────────────────────────────────

  int insert(CategoryModel category) {
    _db.execute(
      '''
      INSERT INTO ${DatabaseHelper.tableCategories}
        (title, icon, color)
      VALUES (?, ?, ?);
    ''',
      [category.title, category.icon, category.color],
    );

    return _db.lastInsertRowId;
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  List<CategoryModel> getAll() {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableCategories} ORDER BY id;',
    );
    return rows.map(_rowToModel).toList();
  }

  CategoryModel? getById(int id) {
    final rows = _db.select(
      'SELECT * FROM ${DatabaseHelper.tableCategories} WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  CategoryModel getDefault() {
    return getById(DatabaseHelper.defaultCategoryId)!;
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  void update(CategoryModel category) {
    assert(category.id != null, 'CategoryModel must have an id to update');
    assert(
      category.id != DatabaseHelper.defaultCategoryId,
      'Cannot modify the default category',
    );

    _db.execute(
      '''
      UPDATE ${DatabaseHelper.tableCategories}
      SET title = ?, icon = ?, color = ?
      WHERE id = ?;
    ''',
      [category.title, category.icon, category.color, category.id],
    );
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// Elimina la categoría y reasigna sus links a "Ninguna".
  void deleteAndReassignLinks(int categoryId) {
    _guardDefault(categoryId);

    // SQLite con ON DELETE SET DEFAULT no siempre es confiable entre versiones,
    // así que lo hacemos explícitamente en una transacción.
    _db.execute('BEGIN;');
    try {
      _db.execute(
        '''
        UPDATE ${DatabaseHelper.tableLinks}
        SET ${DatabaseHelper.colLinkCategory} = ?
        WHERE ${DatabaseHelper.colLinkCategory} = ?;
      ''',
        [DatabaseHelper.defaultCategoryId, categoryId],
      );

      _db.execute(
        'DELETE FROM ${DatabaseHelper.tableCategories} WHERE id = ?;',
        [categoryId],
      );

      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Elimina la categoría junto con TODOS sus links.
  void deleteWithAllLinks(int categoryId) {
    _guardDefault(categoryId);

    _db.execute('BEGIN;');
    try {
      _db.execute(
        '''
        DELETE FROM ${DatabaseHelper.tableLinks}
        WHERE ${DatabaseHelper.colLinkCategory} = ?;
      ''',
        [categoryId],
      );

      _db.execute(
        'DELETE FROM ${DatabaseHelper.tableCategories} WHERE id = ?;',
        [categoryId],
      );

      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  void updateDefault(CategoryModel category) {
    _db.execute(
      '''
    UPDATE ${DatabaseHelper.tableCategories}
    SET title = ?, icon = ?, color = ?
    WHERE id = ?;
  ''',
      [
        category.title,
        category.icon,
        category.color,
        DatabaseHelper.defaultCategoryId,
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  void _guardDefault(int categoryId) {
    if (categoryId == DatabaseHelper.defaultCategoryId) {
      throw StateError('Cannot delete the default category "Ninguna".');
    }
  }

  CategoryModel _rowToModel(Row row) => CategoryModel.fromMap({
    'id': row['id'],
    'title': row['title'],
    'icon': row['icon'],
    'color': row['color'],
  });
}
