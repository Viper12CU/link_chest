import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/dao/category_dao.dart';
import 'package:link_chest/database/dao/link_dao.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/molecules/sync_status_banner.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  late CategoryDao categories;
  late LinkDao links;
  final sync = SyncService.instance;

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
  }) => LinkModel(
    id: id,
    userId: userId,
    title: 'Link',
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

    // Estado base: activo e idle.
    sync.debugSetState(active: true, phase: SyncPhase.idle);
  });

  tearDown(() {
    sync.debugSetState(active: false, phase: SyncPhase.idle);
    helper.close();
  });

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SyncStatusBanner())),
    );
    await tester.pump();
  }

  group('SyncStatusBanner', () {
    testWidgets('inactivo → sin banner', (tester) async {
      sync.debugSetState(active: false, phase: SyncPhase.idle);
      await pumpBanner(tester);

      expect(find.byType(SyncStatusBanner), findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsNothing);
      expect(find.textContaining('Sincronizando'), findsNothing);
      expect(find.textContaining('sesión expiró'), findsNothing);
    });

    testWidgets('idle sin errores → sin banner', (tester) async {
      await pumpBanner(tester);

      expect(find.byType(Container), findsNothing);
      expect(find.textContaining('cambio'), findsNothing);
    });

    testWidgets('needsLogin prioriza sobre errores y offline', (tester) async {
      links.setSyncError(links.insert(link()), 'boom');
      sync.debugSetState(active: true, phase: SyncPhase.needsLogin);
      await pumpBanner(tester);

      expect(find.text('Tu sesión expiró. Inicia sesión para sincronizar'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.textContaining('no se pudo sincronizar'), findsNothing);
      expect(find.textContaining('Sin conexión'), findsNothing);
    });

    testWidgets('errores > offline', (tester) async {
      links.setSyncError(links.insert(link()), 'boom');
      sync.debugSetState(active: true, phase: SyncPhase.offline);
      await pumpBanner(tester);

      expect(find.text('1 cambio no se pudo sincronizar'), findsOneWidget);
      expect(find.text('Revisar'), findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsNothing);
    });

    testWidgets('plural en texto de errores', (tester) async {
      links.setSyncError(links.insert(link(url: 'https://a.com')), 'e1');
      links.setSyncError(links.insert(link(url: 'https://b.com')), 'e2');
      sync.debugSetState(active: true, phase: SyncPhase.idle);
      await pumpBanner(tester);

      expect(find.text('2 cambios no se pudieron sincronizar'), findsOneWidget);
    });

    testWidgets('offline con pendientes', (tester) async {
      links.insert(link());
      sync.debugSetState(active: true, phase: SyncPhase.offline);
      await pumpBanner(tester);

      expect(
        find.text('Sin conexión · 1 cambio pendiente de sincronizar'),
        findsOneWidget,
      );
    });

    testWidgets('offline sin pendientes (decisión B)', (tester) async {
      sync.debugSetState(active: true, phase: SyncPhase.offline);
      await pumpBanner(tester);

      expect(
        find.text('Sin conexión · sin cambios pendientes'),
        findsOneWidget,
      );
    });

    testWidgets('syncing no se muestra antes de 1 s', (tester) async {
      sync.debugSetState(active: true, phase: SyncPhase.syncing);
      await pumpBanner(tester);

      expect(find.text('Sincronizando…'), findsNothing);
    });

    testWidgets('syncing se muestra tras 1 s si sigue en esa fase', (
      tester,
    ) async {
      sync.debugSetState(active: true, phase: SyncPhase.syncing);
      await pumpBanner(tester);
      expect(find.text('Sincronizando…'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Sincronizando…'), findsOneWidget);
    });

    testWidgets('syncing que termina antes de 1 s no se muestra', (
      tester,
    ) async {
      sync.debugSetState(active: true, phase: SyncPhase.syncing);
      await pumpBanner(tester);

      await tester.pump(const Duration(milliseconds: 500));
      sync.debugSetState(active: true, phase: SyncPhase.idle);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Sincronizando…'), findsNothing);
    });
  });
}
