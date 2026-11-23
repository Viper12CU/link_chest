import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/dao/category_dao.dart';
import 'package:link_chest/database/dao/link_dao.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/molecules/sync_error_sheet.dart';
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
    String title = 'Docs',
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
    sync.debugSetState(active: true, phase: SyncPhase.idle);
  });

  tearDown(() {
    sync.debugSetState(active: false, phase: SyncPhase.idle);
    helper.close();
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SyncErrorSheet())),
    );
    await tester.pump();
  }

  group('SyncErrorSheet', () {
    testWidgets('lista vacía muestra mensaje y Reintentar deshabilitado', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('Errores de sincronización'), findsOneWidget);
      expect(find.text('No hay cambios con error.'), findsOneWidget);
      expect(find.text('Reintentar todo'), findsOneWidget);
      expect(find.text('Descartar'), findsNothing);

      final retry = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Reintentar todo'),
      );
      expect(retry.onPressed, isNull);
    });

    testWidgets('lista errores con tipo y motivo traducido', (tester) async {
      final linkId = links.insert(link(title: 'Docs'));
      links.setSyncError(
        linkId,
        'PostgrestException(message: dup, code: 23505, details: null, hint: null)',
      );
      categories.setSyncError(
        defaultCatId,
        'PostgrestException(message: rls, code: 42501, details: null, hint: null)',
      );

      await pumpSheet(tester);

      expect(find.text('Sin categoría'), findsOneWidget);
      expect(find.text('Docs'), findsOneWidget);
      expect(
        find.textContaining(
          'Categoría · No tienes permiso para este cambio',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Link · El servidor rechazó este cambio porque no cumple las reglas de datos',
        ),
        findsOneWidget,
      );
      expect(find.text('Reintentar todo'), findsOneWidget);
      expect(find.text('Descartar'), findsOneWidget);
    });

    testWidgets('Descartar (todo) limpia errores y dirty', (tester) async {
      final id = links.insert(link());
      links.setSyncError(id, 'boom');
      categories.setSyncError(defaultCatId, 'boom-cat');

      await pumpSheet(tester);
      expect(sync.errorCount, 2);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Descartar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sync.errorCount, 0);
      expect(links.getById(id)!.syncError, isNull);
      expect(links.getById(id)!.isPendingSync, isFalse);
      expect(categories.getById(defaultCatId)!.syncError, isNull);
      expect(categories.getById(defaultCatId)!.isPendingSync, isFalse);
    });

    testWidgets('descartar individual solo toca esa fila', (tester) async {
      final a = links.insert(link(url: 'https://a.com', title: 'A'));
      final b = links.insert(link(url: 'https://b.com', title: 'B'));
      links.setSyncError(a, 'err-a');
      links.setSyncError(b, 'err-b');

      await pumpSheet(tester);
      expect(sync.errorCount, 2);

      // Primera fila de la lista = A (orden por updated_at, id).
      final tooltips = find.byTooltip('Descartar');
      expect(tooltips, findsNWidgets(2));
      await tester.tap(tooltips.first);
      await tester.pump();

      expect(links.getById(a)!.syncError, isNull);
      expect(links.getById(a)!.isPendingSync, isFalse);
      expect(links.getById(b)!.syncError, 'err-b');
      expect(sync.errorCount, 1);
      // La hoja no se cierra al descartar uno.
      expect(find.text('Errores de sincronización'), findsOneWidget);
    });

    testWidgets('Reintentar todo limpia errores y deja dirty = 1', (
      tester,
    ) async {
      final id = links.insert(link());
      links.setSyncError(id, 'boom');

      await pumpSheet(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar todo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sync.errorCount, 0);
      expect(links.getById(id)!.syncError, isNull);
      expect(links.getById(id)!.isPendingSync, isTrue);

      // retryErrored → requestSync deja un debounce de 2 s: apaga y cancela.
      sync.debugSetState(active: false, phase: SyncPhase.idle);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
