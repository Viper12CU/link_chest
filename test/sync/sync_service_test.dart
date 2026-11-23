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

  group('SyncService.discardErrored', () {
    test('limpia sync_error y deja dirty = 0 (no se vuelve a subir)', () {
      final id = links.insert(link());
      links.setSyncError(id, 'PostgrestException(code: 23503)');
      categories.setSyncError(defaultCatId, 'PostgrestException(code: 42501)');

      SyncService.instance.discardErrored();

      expect(SyncService.instance.errorCount, 0);
      expect(SyncService.instance.errorItems, isEmpty);

      final linkRow = links.getById(id)!;
      expect(linkRow.syncError, isNull);
      expect(linkRow.isPendingSync, isFalse);

      final catRow = categories.getById(defaultCatId)!;
      expect(catRow.syncError, isNull);
      expect(catRow.isPendingSync, isFalse);
    });

    test('no toca filas sin error ni pendientes limpios', () {
      final okId = links.insert(link(url: 'https://ok.com'));
      final pendingId = links.insert(link(url: 'https://pending.com'));
      final badId = links.insert(link(url: 'https://bad.com'));
      links.setSyncError(badId, 'boom');

      SyncService.instance.discardErrored();

      expect(links.getById(okId)!.syncError, isNull);
      expect(links.getById(okId)!.isPendingSync, isTrue);
      expect(links.getById(pendingId)!.isPendingSync, isTrue);
      expect(links.getById(badId)!.syncError, isNull);
      expect(links.getById(badId)!.isPendingSync, isFalse);
    });

    test('notifica a los listeners', () {
      final id = links.insert(link());
      links.setSyncError(id, 'err');

      var notified = 0;
      SyncService.instance.addListener(() => notified++);
      SyncService.instance.discardErrored();

      expect(notified, 1);
      SyncService.instance.removeListener(() {});
    });
  });

  group('SyncService.discardError (individual)', () {
    test('descarta solo la fila indicada', () {
      final a = links.insert(link(url: 'https://a.com'));
      final b = links.insert(link(url: 'https://b.com'));
      links.setSyncError(a, 'err-a');
      links.setSyncError(b, 'err-b');
      categories.setSyncError(defaultCatId, 'err-cat');

      final itemA = SyncService.instance.errorItems.singleWhere(
        (i) => i.id == a,
      );
      SyncService.instance.discardError(itemA);

      expect(links.getById(a)!.syncError, isNull);
      expect(links.getById(a)!.isPendingSync, isFalse);
      expect(links.getById(b)!.syncError, 'err-b');
      expect(categories.getById(defaultCatId)!.syncError, 'err-cat');
      expect(SyncService.instance.errorCount, 2);
    });

    test('descarta una categoría individual', () {
      final id = links.insert(link());
      links.setSyncError(id, 'err-link');
      categories.setSyncError(defaultCatId, 'err-cat');

      final catItem = SyncService.instance.errorItems.singleWhere(
        (i) => i.type == SyncErrorType.category,
      );
      SyncService.instance.discardError(catItem);

      expect(categories.getById(defaultCatId)!.syncError, isNull);
      expect(categories.getById(defaultCatId)!.isPendingSync, isFalse);
      expect(links.getById(id)!.syncError, 'err-link');
      expect(SyncService.instance.errorCount, 1);
    });
  });

  group('initialSyncDone / lastSyncedAt', () {
    test('leé valores de sync_state', () {
      expect(SyncService.instance.initialSyncDone, isFalse);
      expect(SyncService.instance.lastSyncedAt, isNull);

      helper.setSyncState('initial_sync_done', '1');
      helper.setSyncState('last_synced_at', '2026-01-01T00:00:00.000Z');

      expect(SyncService.instance.initialSyncDone, isTrue);
      expect(SyncService.instance.lastSyncedAt, '2026-01-01T00:00:00.000Z');
    });
  });

  group('isOnline', () {
    test('devuelve un bool sin lanzar (fallback online en tests)', () async {
      final online = await SyncService.instance.isOnline();
      expect(online, isA<bool>());
      // Sin plugin de conectividad en tests: fallback true.
      expect(online, isTrue);
    });
  });

  group('DefaultCategoryNotReadyException (mensaje UI)', () {
    test('mensaje en español para el usuario', () {
      expect(
        DefaultCategoryNotReadyException().toString(),
        'Tu cuenta aún se está preparando. Inténtalo en unos segundos.',
      );
    });
  });
}
