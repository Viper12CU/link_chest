import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/dao/category_dao.dart';
import 'package:link_chest/database/dao/link_dao.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  late CategoryDao categories;
  late LinkDao links;

  const userId = 'user-1';
  const otherUser = 'user-2';

  String now() => DateTime.now().toUtc().toIso8601String();

  CategoryModel cat({
    String? id,
    String title = 'Trabajo',
    bool isDefault = false,
    String uid = userId,
  }) => CategoryModel(
    id: id,
    userId: uid,
    title: title,
    icon: '📁',
    color: '#ff0000ff',
    isDefault: isDefault,
    createdAt: now(),
    updatedAt: now(),
  );

  LinkModel link({
    String? id,
    String categoryId = '',
    String url = 'https://example.com/a',
    LinkStatus status = LinkStatus.public,
    String uid = userId,
  }) => LinkModel(
    id: id,
    userId: uid,
    title: 'Link',
    url: url,
    categoryId: categoryId,
    status: status,
    createdAt: now(),
    updatedAt: now(),
  );

  setUp(() {
    db = sqlite3.openInMemory();
    DatabaseHelper.upgrade(db);
    helper = DatabaseHelper.forTest(db);
    categories = CategoryDao(helper);
    links = LinkDao(helper);

    // Categoría por defecto remota (como llegaría del servidor).
    categories.updateFromServer(
      cat(
        id: 'default-cat',
        title: 'Sin categoría',
        isDefault: true,
      ),
    );
  });

  tearDown(() {
    helper.close();
  });

  group('esquema v2', () {
    test('user_version == 2 y existe sync_state', () {
      final v = db.select('PRAGMA user_version').first['user_version'];
      expect(v, 2);
      final tables = db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_state'",
          )
          .length;
      expect(tables, 1);
    });

    test('getDefaultCategoryId consulta viva (no id fijo)', () {
      expect(helper.getDefaultCategoryId(), 'default-cat');
    });
  });

  group('reglas de escritura local', () {
    test('insert marca dirty=1, version=1, updated_at UTC y limpia sync_error', () {
      final id = categories.insert(cat());
      final row = db.select('SELECT * FROM categories WHERE id = ?', [id]).first;

      expect(row['dirty'], 1);
      expect(row['version'], 1);
      expect(row['sync_error'], isNull);
      expect(row['deleted_at'], isNull);
      expect(DateTime.parse(row['updated_at'] as String).isUtc, isTrue);
    });

    test('update incrementa version, marca dirty y limpia sync_error', () {
      final id = categories.insert(cat());
      db.execute(
        'UPDATE categories SET dirty = 0, sync_error = ? WHERE id = ?',
        ['old-error', id],
      );

      final before = db
          .select('SELECT version FROM categories WHERE id = ?', [id])
          .first['version'] as int;
      categories.update(categories.getById(id)!.copyWith(title: 'Nuevo'));

      final row = db.select('SELECT * FROM categories WHERE id = ?', [id]).first;
      expect(row['dirty'], 1);
      expect(row['version'], before + 1);
      expect(row['sync_error'], isNull);
      expect(row['title'], 'Nuevo');
    });

    test('borrado lógico: deleted_at + dirty, fila sigue visible sin filtro', () {
      final id = categories.insert(cat());
      final linkId = links.insert(link(categoryId: id));

      // Borrar categoría con reasignación
      categories.deleteAndReassignLinks(id);

      final catRow = db
          .select('SELECT deleted_at, dirty FROM categories WHERE id = ?', [id])
          .first;
      expect(catRow['deleted_at'], isNotNull);
      expect(catRow['dirty'], 1);

      // link reasignado a default y marcado dirty
      final linkRow = db
          .select('SELECT category_id, dirty, deleted_at FROM links WHERE id = ?', [
            linkId,
          ])
          .first;
      expect(linkRow['category_id'], 'default-cat');
      expect(linkRow['dirty'], 1);
      expect(linkRow['deleted_at'], isNull);

      // lecturas filtran deleted_at
      expect(categories.getById(id), isNull);
      expect(categories.getAll().where((c) => c.id == id), isEmpty);
      // pero la fila existe para sync
      expect(categories.getByIdIncludingDeleted(id), isNotNull);
    });

    test('deleteWithAllLinks marca links y categoría como borrados', () {
      final id = categories.insert(cat());
      final linkId = links.insert(link(categoryId: id));

      categories.deleteWithAllLinks(id);

      final linkRow = db
          .select('SELECT deleted_at, dirty FROM links WHERE id = ?', [linkId])
          .first;
      expect(linkRow['deleted_at'], isNotNull);
      expect(linkRow['dirty'], 1);
      expect(links.getById(linkId), isNull);
      expect(categories.getById(id), isNull);
    });

    test('no se puede editar ni borrar la categoría por defecto', () {
      final def = categories.getDefault()!;
      expect(
        () => categories.update(def.copyWith(title: 'Hacked')),
        throwsStateError,
      );
      expect(() => categories.deleteAndReassignLinks(def.id!), throwsStateError);
      expect(() => categories.deleteWithAllLinks(def.id!), throwsStateError);
    });

    test('crear link sin default lanza DefaultCategoryNotReadyException', () {
      db.execute("UPDATE categories SET deleted_at = '2020-01-01' WHERE is_default = 1");
      expect(
        () => links.insert(link(categoryId: 'x')),
        throwsA(isA<DefaultCategoryNotReadyException>()),
      );
    });

    test('insert de link usa default si categoryId vacío', () {
      final id = links.insert(link(categoryId: ''));
      final row = db.select('SELECT category_id FROM links WHERE id = ?', [id]).first;
      expect(row['category_id'], 'default-cat');
    });
  });

  group('lecturas', () {
    test('getAll excluye borrados lógicos', () {
      final a = categories.insert(cat(title: 'A'));
      categories.insert(cat(title: 'B'));
      categories.deleteWithAllLinks(a);

      final titles = categories.getAll().map((c) => c.title).toList();
      expect(titles, isNot(contains('A')));
      expect(titles, contains('B'));
      expect(titles, contains('Sin categoría'));
    });

    test('getDirty limita y excluye sync_error', () {
      final a = categories.insert(cat(title: 'A'));
      final b = categories.insert(cat(title: 'B'));
      categories.setSyncError(b, 'RLS 42501');

      final dirty = categories.getDirty();
      expect(dirty.map((c) => c.id), contains(a));
      expect(dirty.map((c) => c.id), isNot(contains(b)));
    });

    test('links privados se listan por status', () {
      final c = categories.insert(cat());
      links.insert(link(categoryId: c, url: 'https://a.com', status: LinkStatus.private));
      links.insert(link(categoryId: c, url: 'https://b.com'));

      expect(links.getByStatus(LinkStatus.private).length, 1);
      expect(links.getByStatus(LinkStatus.public).length, 1);
    });
  });

  group('sync helpers', () {
    test('markSynced solo limpia si version coincide', () {
      final id = categories.insert(cat());
      final version = categories.getById(id)!.version;

      categories.markSynced(id, version + 99);
      expect(categories.getById(id)!.isPendingSync, isTrue);

      categories.markSynced(id, version);
      expect(categories.getById(id)!.isPendingSync, isFalse);
    });

    test('updateFromServer deja dirty=0 y permite default', () {
      categories.updateFromServer(
        cat(id: 'srv-1', title: 'Descargada', uid: otherUser),
      );
      final row = categories.getById('srv-1')!;
      expect(row.isPendingSync, isFalse);
      expect(row.userId, otherUser);
    });

    test('clearAllData vacía tablas y sync_state', () {
      categories.insert(cat());
      helper.setSyncState('last_synced_at', now());
      helper.clearAllData();

      expect(categories.getAll(), isEmpty);
      expect(helper.getSyncState('last_synced_at'), isNull);
    });
  });

  group('sync_state', () {
    test('set/get/delete', () {
      helper.setSyncState('k', 'v1');
      expect(helper.getSyncState('k'), 'v1');
      helper.setSyncState('k', 'v2');
      expect(helper.getSyncState('k'), 'v2');
      helper.deleteSyncState('k');
      expect(helper.getSyncState('k'), isNull);
    });
  });
}
