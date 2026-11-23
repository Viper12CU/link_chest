import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/dao/category_dao.dart';
import 'package:link_chest/database/dao/link_dao.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  late CategoryDao categories;
  late LinkDao links;

  const userId = 'user-1';
  const defaultCatId = 'default-cat';

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
    String categoryId = defaultCatId,
    String url = 'https://example.com/a',
    String title = 'Link',
  }) => LinkModel(
    id: id,
    userId: userId,
    title: title,
    url: url,
    categoryId: categoryId,
    createdAt: now(),
    updatedAt: now(),
  );

  setUp(() {
    db = sqlite3.openInMemory();
    DatabaseHelper.upgrade(db);
    helper = DatabaseHelper.forTest(db);
    categories = CategoryDao(helper);
    links = LinkDao(helper);

    categories.updateFromServer(
      cat(id: defaultCatId, title: 'Sin categoría', isDefault: true),
    );
  });

  tearDown(() {
    helper.close();
  });

  group('hasSyncError', () {
    test('es true cuando syncError no es nulo', () {
      final withError = link().copyWith(syncError: 'PostgrestException');
      final ok = link();

      expect(withError.hasSyncError, isTrue);
      expect(ok.hasSyncError, isFalse);
      expect(cat().copyWith(syncError: 'x').hasSyncError, isTrue);
      expect(cat().hasSyncError, isFalse);
    });
  });

  group('SyncService.errorItems', () {
    test('lista links y categorías con sync_error', () {
      final linkId = links.insert(link(title: 'Docs'));
      links.setSyncError(linkId, 'PostgrestException(code: 23505)');
      categories.setSyncError(defaultCatId, 'PostgrestException(code: 42501)');

      final items = SyncService.instance.errorItems;

      expect(items, hasLength(2));

      final catItem = items.singleWhere((i) => i.type == SyncErrorType.category);
      expect(catItem.id, defaultCatId);
      expect(catItem.title, 'Sin categoría');
      expect(catItem.error, contains('42501'));

      final linkItem = items.singleWhere((i) => i.type == SyncErrorType.link);
      expect(linkItem.id, linkId);
      expect(linkItem.title, 'Docs');
      expect(linkItem.error, contains('23505'));
    });

    test('ignora filas sin sync_error', () {
      links.insert(link());
      categories.setSyncError(defaultCatId, 'err');

      final items = SyncService.instance.errorItems;
      expect(items, hasLength(1));
      expect(items.single.type, SyncErrorType.category);
    });

    test('errorCount coincide con errorItems', () {
      final a = links.insert(link(url: 'https://a.com'));
      links.setSyncError(a, 'e1');
      categories.setSyncError(defaultCatId, 'e2');

      expect(SyncService.instance.errorCount, SyncService.instance.errorItems.length);
      expect(SyncService.instance.errorCount, 2);
    });
  });

  group('SyncService.retryErrored', () {
    test('limpia sync_error y deja dirty = 1', () async {
      final id = links.insert(link());
      links.setSyncError(id, 'PostgrestException(code: 23503)');
      categories.setSyncError(defaultCatId, 'PostgrestException(code: 42501)');

      // dirty puede ser 0 tras un intento fallido aislado: retry lo reactiva.
      db.execute('UPDATE links SET dirty = 0 WHERE id = ?;', [id]);

      await SyncService.instance.retryErrored();

      expect(SyncService.instance.errorCount, 0);
      expect(SyncService.instance.errorItems, isEmpty);

      final linkRow = links.getById(id)!;
      expect(linkRow.syncError, isNull);
      expect(linkRow.isPendingSync, isTrue);

      final catRow = categories.getById(defaultCatId)!;
      expect(catRow.syncError, isNull);
      expect(catRow.isPendingSync, isTrue);
    });

    test('no toca filas sin error', () async {
      final okId = links.insert(link(url: 'https://ok.com'));
      final badId = links.insert(link(url: 'https://bad.com'));
      links.setSyncError(badId, 'boom');

      await SyncService.instance.retryErrored();

      expect(links.getById(okId)!.syncError, isNull);
      expect(links.getById(okId)!.isPendingSync, isTrue);
      expect(links.getById(badId)!.syncError, isNull);
      expect(links.getById(badId)!.isPendingSync, isTrue);
    });
  });

  group('pendingCount / hasPendingChanges', () {
    test('cuenta dirty sin sync_error; no cuenta errores', () {
      final pending = links.insert(link(url: 'https://pending.com'));
      final errored = links.insert(link(url: 'https://errored.com'));
      links.setSyncError(errored, 'boom');

      expect(SyncService.instance.pendingCount, 1);
      expect(SyncService.instance.hasPendingChanges(), isTrue);
      expect(pending, isNotEmpty);
    });
  });
}
