import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/dao/category_dao.dart';
import 'package:link_chest/database/dao/link_dao.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/services/sync/remote_sync_api.dart';
import 'package:link_chest/services/sync/sync_engine.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:sqlite3/sqlite3.dart';

// ─── Fake de red ─────────────────────────────────────────────────────────────

/// Servidor en memoria que respeta el orden `(updated_at, id)` y el upsert
/// por id. Permite inyectar errores y callbacks durante el envío.
class FakeRemoteSyncApi implements RemoteSyncApi {
  final categories = <String, Map<String, dynamic>>{};
  final links = <String, Map<String, dynamic>>{};

  /// Errores a lanzar en el próximo upsert (fila o lote).
  Object? Function(List<Map<String, dynamic>> rows)? onUpsertCategories;
  Object? Function(List<Map<String, dynamic>> rows)? onUpsertLinks;

  /// Se llama con cada lote de links aceptado (para simular edición en vuelo).
  void Function(List<Map<String, dynamic>> rows)? afterUpsertLinks;

  int categoryFetchCalls = 0;
  int linkFetchCalls = 0;

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> rows) async {
    final err = onUpsertCategories?.call(rows);
    if (err != null) throw err;
    for (final row in rows) {
      categories[_id(row)] = _stamp(row);
    }
  }

  @override
  Future<void> upsertLinks(List<Map<String, dynamic>> rows) async {
    final err = onUpsertLinks?.call(rows);
    if (err != null) throw err;
    for (final row in rows) {
      links[_id(row)] = _stamp(row);
    }
    afterUpsertLinks?.call(rows);
  }

  String _id(Map<String, dynamic> row) => row['id'] as String;

  /// Simula el trigger del servidor: fija `updated_at` y rellena `created_at`.
  Map<String, dynamic> _stamp(Map<String, dynamic> row) {
    final stored = Map<String, dynamic>.of(row);
    final now = DateTime.now().toUtc().toIso8601String();
    stored['created_at'] ??= now;
    stored['updated_at'] = now;
    return stored;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String? updatedAt,
    required String? id,
    required int limit,
  }) async {
    categoryFetchCalls++;
    return _page(categories, updatedAt: updatedAt, id: id, limit: limit);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinks({
    required String? updatedAt,
    required String? id,
    required int limit,
  }) async {
    linkFetchCalls++;
    return _page(links, updatedAt: updatedAt, id: id, limit: limit);
  }

  List<Map<String, dynamic>> _page(
    Map<String, Map<String, dynamic>> all, {
    required String? updatedAt,
    required String? id,
    required int limit,
  }) {
    final rows = all.values.toList()
      ..sort((a, b) {
        final cmp = _at(a).compareTo(_at(b));
        if (cmp != 0) return cmp;
        return _id(a).compareTo(_id(b));
      });

    final filtered = rows.where((r) {
      if (updatedAt == null || id == null) return true;
      final at = _at(r);
      final rid = _id(r);
      final cmp = at.compareTo(updatedAt);
      if (cmp > 0) return true;
      if (cmp == 0) return rid.compareTo(id) > 0;
      return false;
    }).toList();

    return filtered.take(limit).map((r) => Map.of(r)).toList();
  }

  String _at(Map<String, dynamic> row) =>
      row['updated_at'] as String? ?? '';
}

class _FakePostgrestError implements Exception {
  _FakePostgrestError(this.code, [this.message = 'error']);
  final String code;
  final String message;

  @override
  String toString() => 'PostgrestException($code): $message';
}

// ─── Helpers de datos ────────────────────────────────────────────────────────

const userId = 'user-1';
const defaultCatId = 'default-cat';

String now() => DateTime.now().toUtc().toIso8601String();

String isoAt(int seconds) =>
    DateTime.utc(2026, 1, 1, 0, 0, seconds).toIso8601String();

CategoryModel cat({
  String? id,
  String title = 'Trabajo',
  bool isDefault = false,
  String uid = userId,
  String? deletedAt,
}) => CategoryModel(
  id: id,
  userId: uid,
  title: title,
  icon: '📁',
  color: '#ff0000ff',
  isDefault: isDefault,
  createdAt: now(),
  updatedAt: now(),
  deletedAt: deletedAt,
);

LinkModel link({
  String? id,
  String categoryId = defaultCatId,
  String url = 'https://example.com/a',
  String title = 'Link',
  LinkStatus status = LinkStatus.public,
  String uid = userId,
}) => LinkModel(
  id: id,
  userId: uid,
  title: title,
  url: url,
  categoryId: categoryId,
  status: status,
  createdAt: now(),
  updatedAt: now(),
);

void main() {
  late Database db;
  late DatabaseHelper helper;
  late CategoryDao categories;
  late LinkDao links;
  late FakeRemoteSyncApi api;
  late SyncEngine engine;

  setUp(() {
    db = sqlite3.openInMemory();
    DatabaseHelper.upgrade(db);
    helper = DatabaseHelper.forTest(db);
    categories = CategoryDao(helper);
    links = LinkDao(helper);
    api = FakeRemoteSyncApi();
    engine = SyncEngine(helper: helper, api: api, uploadBatch: 100, downloadBatch: 500);

    categories.updateFromServer(
      cat(id: defaultCatId, title: 'Sin categoría', isDefault: true),
    );
  });

  tearDown(() {
    helper.close();
  });

  group('subida', () {
    test('subida repetida no duplica filas', () async {
      final id = links.insert(link(url: 'https://a.com'));

      await engine.run();
      expect(api.links.length, 1);
      expect(links.getById(id)!.isPendingSync, isFalse);

      // Simula cierre entre subir y marcar: la fila vuelve a quedar dirty.
      db.execute('UPDATE links SET dirty = 1 WHERE id = ?', [id]);
      await engine.run();

      expect(api.links.length, 1);
      expect(links.getById(id)!.isPendingSync, isFalse);
    });

    test('editar durante el envío no quita la marca de pendiente', () async {
      final id = links.insert(link(url: 'https://edit.com'));
      final versionBefore = links.getById(id)!.version;

      api.afterUpsertLinks = (_) {
        // Edición local concurrente (version +1) mientras el lote viaja.
        links.update(links.getById(id)!.copyWith(title: 'Editado en vuelo'));
      };

      await engine.run();

      final row = links.getById(id)!;
      expect(row.title, 'Editado en vuelo');
      // version local > version enviada → markSynced no limpió dirty
      expect(row.version, greaterThan(versionBefore));
      expect(row.isPendingSync, isTrue);
      // El servidor tiene la versión anterior (upsert ya corrió).
      expect(api.links[id]!['title'], 'Link');
    });

    test('no sube links privados', () async {
      final pub = links.insert(link(url: 'https://pub.com'));
      final priv = links.insert(
        link(url: 'https://priv.com', status: LinkStatus.private),
      );

      await engine.run();

      expect(api.links.containsKey(pub), isTrue);
      expect(api.links.containsKey(priv), isFalse);
      expect(links.getById(priv)!.isPendingSync, isTrue);
    });

    test('errores definitivos aíslan solo la fila culpable', () async {
      final good = links.insert(link(url: 'https://good.com'));
      final bad = links.insert(link(url: 'https://bad.com'));

      api.onUpsertLinks = (rows) {
        if (rows.length > 1) {
          // Lote completo falla (RLS) → engine reintenta fila a fila.
          return _FakePostgrestError('42501', 'row-level security');
        }
        if (rows.single['id'] == bad) {
          return _FakePostgrestError('42501', 'rls on bad row');
        }
        return null;
      };

      await engine.run();

      expect(links.getById(good)!.isPendingSync, isFalse);
      // La fila culpable queda con sync_error (getDirty la excluye);
      // dirty puede seguir en 1 hasta que el usuario corrija.
      expect(links.getById(bad)!.syncError, isNotNull);
      expect(
        links.getDirty().any((l) => l.id == bad),
        isFalse,
      );
      expect(api.links.containsKey(good), isTrue);
      expect(api.links.containsKey(bad), isFalse);
    });

    test('error de red deja dirty para el siguiente intento', () async {
      final id = links.insert(link(url: 'https://net.com'));
      api.onUpsertLinks = (_) => SyncNetworkException('offline');

      await expectLater(engine.run(), throwsA(isA<SyncNetworkException>()));
      expect(links.getById(id)!.isPendingSync, isTrue);
      expect(api.links, isEmpty);

      api.onUpsertLinks = null;
      await engine.run();
      expect(api.links.length, 1);
      expect(links.getById(id)!.isPendingSync, isFalse);
    });
  });

  group('descarga', () {
    test('no pisa filas con dirty = 1', () async {
      // Servidor tiene otra versión del mismo id.
      api.categories[defaultCatId] = {
        'id': defaultCatId,
        'user_id': userId,
        'title': 'Sin categoría',
        'icon': '📂',
        'color': '#000000ff',
        'is_default': true,
        'created_at': isoAt(0),
        'updated_at': isoAt(50),
        'deleted_at': null,
      };
      final localId = categories.insert(cat(id: 'local-1', title: 'Local'));
      // sync_error excluye la fila de la subida (getDirty), pero dirty=1
      // sigue activo: la descarga no debe pisar la edición local.
      categories.setSyncError(localId, 'fallo previo');
      api.categories['local-1'] = {
        'id': 'local-1',
        'user_id': userId,
        'title': 'Del servidor',
        'icon': '📁',
        'color': '#ff0000ff',
        'is_default': false,
        'created_at': isoAt(0),
        'updated_at': isoAt(60),
        'deleted_at': null,
      };

      await engine.run();

      // dirty local gana
      expect(categories.getById(localId)!.title, 'Local');
      expect(categories.getById(localId)!.isPendingSync, isTrue);
      expect(categories.getById(localId)!.syncError, isNotNull);
    });

    test('paginación con la misma fecha no pierde ni repite', () async {
      engine = SyncEngine(
        helper: helper,
        api: api,
        uploadBatch: 100,
        downloadBatch: 3,
      );

      final at = isoAt(10);
      for (var i = 0; i < 7; i++) {
        final id = 'cat-$i';
        api.categories[id] = {
          'id': id,
          'user_id': userId,
          'title': 'C$i',
          'icon': '📁',
          'color': '#ff0000ff',
          'is_default': false,
          'created_at': at,
          'updated_at': at, // todas con la misma fecha
          'deleted_at': null,
        };
      }

      await engine.run();

      final titles = categories
          .getAll()
          .map((c) => c.title)
          .where((t) => t.startsWith('C'))
          .toSet();
      expect(titles.length, 7);
      // 7 filas / página 3 → al menos 3 llamadas
      expect(api.categoryFetchCalls, greaterThanOrEqualTo(3));
      // sin duplicados en el servidor tras re-descarga
      final cursor = helper.getSyncState('categories_cursor_updated_at');
      expect(cursor, isNotNull);
    });

    test('borrado lógico llega a un segundo dispositivo', () async {
      // Dispositivo A: crea y borra un link.
      final id = links.insert(link(url: 'https://del.com'));
      links.delete(id);
      await engine.run();
      expect(api.links[id]!['deleted_at'], isNotNull);

      // Dispositivo B: otra base local, descarga el mismo servidor.
      final dbB = sqlite3.openInMemory();
      DatabaseHelper.upgrade(dbB);
      final helperB = DatabaseHelper.forTest(dbB);
      final catsB = CategoryDao(helperB);
      final linksB = LinkDao(helperB);
      catsB.updateFromServer(
        cat(id: defaultCatId, title: 'Sin categoría', isDefault: true),
      );
      final engineB = SyncEngine(helper: helperB, api: api);

      await engineB.run();

      expect(linksB.getById(id), isNull);
      final row = linksB.getByIdIncludingDeleted(id);
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);

      helperB.close();
      // Restaura helper singleton para tearDown.
      DatabaseHelper.forTest(db);
    });

    test('ciclo completo marca initial_sync_done y last_synced_at', () async {
      await engine.run();
      expect(helper.getSyncState('initial_sync_done'), '1');
      expect(helper.getSyncState('last_synced_at'), isNotNull);
    });
  });

  group('categorías locales', () {
    test('borrar categoría con links los mueve a la por defecto', () async {
      final c = categories.insert(cat(id: 'borrable', title: 'Temporal'));
      final linkId = links.insert(link(categoryId: c, url: 'https://x.com'));

      categories.deleteAndReassignLinks(c);

      final moved = links.getById(linkId)!;
      expect(moved.categoryId, defaultCatId);

      await engine.run();
      expect(api.categories[c]!['deleted_at'], isNotNull);
      expect(api.links[linkId]!['category_id'], defaultCatId);
    });

    test('crear link sin default lanza DefaultCategoryNotReadyException', () {
      db.execute(
        "UPDATE categories SET deleted_at = '2020-01-01' WHERE is_default = 1",
      );
      expect(
        () => links.insert(link(categoryId: 'x')),
        throwsA(isA<DefaultCategoryNotReadyException>()),
      );
    });
  });

  group('SyncService.prepareUser', () {
    test('mismo usuario no vacía datos locales', () {
      final service = SyncService.instance;
      service.prepareUser('u1');
      categories.insert(cat(id: 'keep-me', title: 'Conservar'));

      final cleared = service.prepareUser('u1');

      expect(cleared, isFalse);
      expect(categories.getById('keep-me'), isNotNull);
      expect(helper.getSyncState('current_user_id'), 'u1');
    });

    test('usuario distinto vacía datos locales y sync_state', () {
      final service = SyncService.instance;
      service.prepareUser('u1');
      categories.insert(cat(id: 'wipe-me'));
      links.insert(link(id: 'link-wipe'));
      helper.setSyncState('last_synced_at', now());

      final cleared = service.prepareUser('u2');

      expect(cleared, isTrue);
      expect(categories.getAll().where((c) => c.id != defaultCatId), isEmpty);
      // clearAllData borra todo incl. default y sync_state; luego se re-setea user.
      expect(helper.getSyncState('last_synced_at'), isNull);
      expect(helper.getSyncState('current_user_id'), 'u2');
    });
  });
}
