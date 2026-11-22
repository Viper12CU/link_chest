import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/database/repositories/repositories.dart';
import 'package:link_chest/database/repositories/sqlite_repositories.dart';
import 'package:link_chest/database/dao/category_dao.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  late CategoryRepository categories;
  late LinkRepository links;

  const userId = 'user-repo';

  String now() => DateTime.now().toUtc().toIso8601String();

  CategoryModel cat({
    String? id,
    String title = 'Trabajo',
    bool isDefault = false,
  }) => CategoryModel(
    id: id,
    userId: userId,
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
    String title = 'Link',
    LinkStatus status = LinkStatus.public,
  }) => LinkModel(
    id: id,
    userId: userId,
    title: title,
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
    categories = SqliteCategoryRepository.withHelper(helper);
    links = SqliteLinkRepository.withHelper(helper);

    categories.updateFromServer(
      cat(id: 'default-cat', title: 'Sin categoría', isDefault: true),
    );
  });

  tearDown(() {
    helper.close();
  });

  group('CategoryRepository', () {
    test('create genera UUID y deja dirty=1', () {
      final id = categories.create(cat());
      expect(id, isNotEmpty);
      final row = categories.getById(id)!;
      expect(row.isPendingSync, isTrue);
      expect(row.version, 1);
    });

    test('update marca dirty y limpia sync_error', () {
      final id = categories.create(cat());
      categories.setSyncError(id, 'boom');
      categories.update(categories.getById(id)!.copyWith(title: 'Nueva'));

      final row = categories.getById(id)!;
      expect(row.title, 'Nueva');
      expect(row.isPendingSync, isTrue);
      expect(row.syncError, isNull);
    });

    test('deleteAndReassign mueve links a default y borra lógicamente', () {
      final id = categories.create(cat());
      final linkId = links.create(link(categoryId: id));

      categories.deleteAndReassign(id);

      expect(categories.getById(id), isNull);
      final moved = links.getById(linkId)!;
      expect(moved.categoryId, 'default-cat');
      expect(moved.isPendingSync, isTrue);
    });

    test('deleteWithLinks borra categoría y links lógicamente', () {
      final id = categories.create(cat());
      final linkId = links.create(link(categoryId: id));

      categories.deleteWithLinks(id);

      expect(categories.getById(id), isNull);
      expect(links.getById(linkId), isNull);
      // filas vivas para sync
      expect(categories.getDirty().map((c) => c.id), contains(id));
    });

    test('default no se edita ni se borra', () {
      final def = categories.getDefault()!;
      expect(() => categories.update(def), throwsStateError);
      expect(() => categories.deleteAndReassign(def.id!), throwsStateError);
      expect(() => categories.deleteWithLinks(def.id!), throwsStateError);
    });

    test('getDirty excluye sync_error', () {
      final a = categories.create(cat(title: 'A'));
      final b = categories.create(cat(title: 'B'));
      categories.setSyncError(b, 'RLS');

      final dirty = categories.getDirty();
      expect(dirty.map((c) => c.id), contains(a));
      expect(dirty.map((c) => c.id), isNot(contains(b)));
    });

    test('markSynced solo limpia si version coincide', () {
      final id = categories.create(cat());
      final version = categories.getById(id)!.version;

      categories.markSynced(id, version + 1);
      expect(categories.getById(id)!.isPendingSync, isTrue);

      categories.markSynced(id, version);
      expect(categories.getById(id)!.isPendingSync, isFalse);
    });
  });

  group('LinkRepository', () {
    test('create sin default lanza DefaultCategoryNotReadyException', () {
      db.execute(
        "UPDATE categories SET deleted_at = '2020-01-01' WHERE is_default = 1",
      );
      expect(
        () => links.create(link(categoryId: 'x')),
        throwsA(isA<DefaultCategoryNotReadyException>()),
      );
    });

    test('create usa default si categoryId vacío', () {
      final id = links.create(link(categoryId: ''));
      expect(links.getById(id)!.categoryId, 'default-cat');
    });

    test('search filtra por title/url/description', () {
      final c = categories.create(cat());
      links.create(
        link(categoryId: c, url: 'https://flutter.dev', title: 'Flutter docs'),
      );
      links.create(
        link(categoryId: c, url: 'https://dart.dev', title: 'Dart site'),
      );

      expect(links.search('flutter').length, 1);
      expect(links.search('dart.dev').length, 1);
      expect(links.search('').length, 2);
    });

    test('move cambia de categoría y marca dirty', () {
      final a = categories.create(cat(title: 'A'));
      final b = categories.create(cat(title: 'B'));
      final linkId = links.create(link(categoryId: a));

      links.move(linkId, b);

      final row = links.getById(linkId)!;
      expect(row.categoryId, b);
      expect(row.isPendingSync, isTrue);
    });

    test('delete es lógico y sale de getAll', () {
      final c = categories.create(cat());
      final linkId = links.create(link(categoryId: c));

      links.delete(linkId);

      expect(links.getById(linkId), isNull);
      expect(links.getDirty().map((l) => l.id), contains(linkId));
    });

    test('deletePrivateLinks solo borra bóveda', () {
      final c = categories.create(cat());
      final pub = links.create(link(categoryId: c, url: 'https://a.com'));
      final priv = links.create(
        link(
          categoryId: c,
          url: 'https://b.com',
          status: LinkStatus.private,
        ),
      );

      links.deletePrivateLinks();

      expect(links.getById(pub), isNotNull);
      expect(links.getById(priv), isNull);
      expect(links.getByStatus(LinkStatus.private), isEmpty);
    });

    test('getDirty publicOnly excluye privados', () {
      final c = categories.create(cat());
      links.create(
        link(
          categoryId: c,
          url: 'https://priv.com',
          status: LinkStatus.private,
        ),
      );
      links.create(link(categoryId: c, url: 'https://pub.com'));

      final all = links.getDirty();
      final pubOnly = links.getDirty(publicOnly: true);

      expect(all.length, 2);
      expect(pubOnly.length, 1);
      expect(pubOnly.single.status, LinkStatus.public);
    });

    test('updateFromServer deja dirty=0', () {
      final c = categories.create(cat());
      links.updateFromServer(
        link(id: 'srv', categoryId: c, url: 'https://srv.com')
            .copyWith(version: 3),
      );

      final row = links.getById('srv')!;
      expect(row.isPendingSync, isFalse);
      expect(row.version, 3);
    });
  });
}
