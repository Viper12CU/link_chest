import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseHelper {
  static const _dbName = 'linkvault.db';
  static const _dbVersion = 2;

  static const tableCategories = 'categories';
  static const tableLinks = 'links';
  static const tableSyncState = 'sync_state';

  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Inyecta una base de datos para tests (p. ej. `sqlite3.openInMemory()`).
  static DatabaseHelper forTest(Database db) {
    final helper = DatabaseHelper._internal();
    _db = db;
    _instance = helper;
    return helper;
  }

  Database get db {
    if (_db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDir.path, _dbName);

    _db = sqlite3.open(dbPath);
    upgrade(_db!);
  }

  /// Aplica el esquema v2. Si `user_version` < 2, recrea las tablas.
  static void upgrade(Database db) {
    final Row versionRow = db.select('PRAGMA user_version').first;
    final int version = (versionRow['user_version'] as int?) ?? 0;

    if (version >= _dbVersion) return;

    db.execute('BEGIN;');
    try {
      db.execute('DROP TABLE IF EXISTS links;');
      db.execute('DROP TABLE IF EXISTS categories;');
      db.execute('DROP TABLE IF EXISTS sync_state;');
      createSchema(db);
      db.execute('PRAGMA user_version = $_dbVersion;');
      db.execute('COMMIT;');
    } catch (e) {
      db.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Esquema v2 preparado para sincronización (sin FKs locales).
  static void createSchema(Database db) {
    db.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL,
        title       TEXT NOT NULL,
        icon        TEXT NOT NULL,
        color       TEXT NOT NULL,
        is_default  INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT,
        dirty       INTEGER NOT NULL DEFAULT 0,
        version     INTEGER NOT NULL DEFAULT 0,
        sync_error  TEXT
      );
    ''');

    db.execute('''
      CREATE TABLE links (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL,
        category_id TEXT NOT NULL,
        status      TEXT NOT NULL DEFAULT 'public' CHECK (status IN ('public', 'private')),
        title       TEXT NOT NULL,
        description TEXT,
        url         TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT,
        dirty       INTEGER NOT NULL DEFAULT 0,
        version     INTEGER NOT NULL DEFAULT 0,
        sync_error  TEXT
      );
    ''');

    db.execute('CREATE INDEX links_category_idx ON links (category_id);');
    db.execute(
      'CREATE INDEX links_dirty_idx ON links (dirty) WHERE dirty = 1;',
    );
    db.execute(
      'CREATE INDEX categories_dirty_idx ON categories (dirty) WHERE dirty = 1;',
    );

    db.execute('''
      CREATE TABLE sync_state (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  /// ID de la categoría por defecto viva, o null si aún no existe.
  String? getDefaultCategoryId() {
    final rows = db.select(
      "SELECT id FROM $tableCategories "
      'WHERE is_default = 1 AND deleted_at IS NULL LIMIT 1;',
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String;
  }

  String? getSyncState(String key) {
    final rows = db.select(
      'SELECT value FROM $tableSyncState WHERE key = ?;',
      [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  void setSyncState(String key, String value) {
    db.execute(
      'INSERT INTO $tableSyncState (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value;',
      [key, value],
    );
  }

  void deleteSyncState(String key) {
    db.execute('DELETE FROM $tableSyncState WHERE key = ?;', [key]);
  }

  void clearSyncState() {
    db.execute('DELETE FROM $tableSyncState;');
  }

  /// Vuelca datos locales y estado de sync (cambio de usuario).
  void clearAllData() {
    db.execute('BEGIN;');
    try {
      db.execute('DELETE FROM links;');
      db.execute('DELETE FROM categories;');
      db.execute('DELETE FROM $tableSyncState;');
      db.execute('COMMIT;');
    } catch (e) {
      db.execute('ROLLBACK;');
      rethrow;
    }
  }

  void close() {
    _db?.close();
    _db = null;
    _instance = null;
  }
}
