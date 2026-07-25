import 'dart:io';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseHelper {
  static const _dbName = 'linkvault.db';
  static const _dbVersion = 1;

  // Nombres de tablas
  static const tableCategories = 'categories';
  static const tableLinks = 'links';

  // Columnas - categories
  static const colCatId = 'id';
  static const colCatTitle = 'title';
  static const colCatIcon = 'icon';
  static const colCatColor = 'color';

  // Columnas - links
  static const colLinkId = 'id';
  static const colLinkTitle = 'title';
  static const colLinkDescription = 'description';
  static const colLinkUrl = 'url';
  static const colLinkCategory = 'category_id';
  static const colLinkStatus = 'status'; // 'public' | 'private'

  // ID fijo para la categoría "Ninguna"
  static const defaultCategoryId = 1;

  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Database get db {
    if (_db == null) throw StateError('Database not initialized. Call init() first.');
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDir.path, _dbName);

    _db = sqlite3.open(dbPath);
    _db!.execute('PRAGMA foreign_keys = ON;');
    _onCreate(_db!);
  }

  void _onCreate(Database db) {
    // Tabla categorías
    db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCategories (
        $colCatId    INTEGER PRIMARY KEY AUTOINCREMENT,
        $colCatTitle TEXT    NOT NULL,
        $colCatIcon  TEXT    NOT NULL,
        $colCatColor TEXT    NOT NULL
      );
    ''');

    // Tabla links — FK a categories con SET DEFAULT al eliminar
    // SQLite no soporta ON DELETE SET DEFAULT, se maneja en el DAO
    db.execute('''
      CREATE TABLE IF NOT EXISTS $tableLinks (
        $colLinkId          INTEGER PRIMARY KEY AUTOINCREMENT,
        $colLinkTitle       TEXT    NOT NULL,
        $colLinkDescription TEXT,
        $colLinkUrl         TEXT    NOT NULL,
        $colLinkCategory    INTEGER NOT NULL DEFAULT $defaultCategoryId,
        $colLinkStatus      TEXT    NOT NULL DEFAULT 'public'
                            CHECK($colLinkStatus IN ('public', 'private')),
        FOREIGN KEY ($colLinkCategory)
          REFERENCES $tableCategories($colCatId)
          ON DELETE SET DEFAULT
      );
    ''');

    // Insertar categoría "Ninguna" si no existe
    final existing = db.select(
      'SELECT id FROM $tableCategories WHERE id = ?',
      [defaultCategoryId],
    );
    if (existing.isEmpty) {
      db.execute('''
        INSERT INTO $tableCategories ($colCatId, $colCatTitle, $colCatIcon, $colCatColor)
        VALUES (?, ?, ?, ?);
      ''', [defaultCategoryId, 'Default', '📂', '$ColorParse().toColorString(Colors.redAccent)']);
    }
  }

  void close() {
    _db?.close();
    _db = null;
  }
}
