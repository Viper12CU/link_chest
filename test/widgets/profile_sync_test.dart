import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/molecules/profile_sync.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  final sync = SyncService.instance;

  setUp(() {
    db = sqlite3.openInMemory();
    DatabaseHelper.upgrade(db);
    helper = DatabaseHelper.forTest(db);
    sync.debugSetState(active: true, phase: SyncPhase.idle);
  });

  tearDown(() {
    sync.debugSetState(active: false, phase: SyncPhase.idle);
    helper.close();
  });

  Future<void> pumpProfileSync(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileSync())),
    );
    await tester.pump();
  }

  group('ProfileSync', () {
    testWidgets('muestra sección, última sync y botón', (tester) async {
      await pumpProfileSync(tester);

      expect(find.text('SINCRONIZACIÓN'), findsOneWidget);
      expect(find.text('Última sincronización'), findsOneWidget);
      expect(find.text('Aún no se ha sincronizado'), findsOneWidget);
      expect(find.text('Sincronizar ahora'), findsOneWidget);
      expect(find.text('Sincronizar'), findsOneWidget);
      expect(find.byTooltip('Sincronizar ahora'), findsOneWidget);
    });

    testWidgets('muestra lastSyncedAt relativo cuando existe', (tester) async {
      helper.setSyncState(
        'last_synced_at',
        DateTime.now()
            .subtract(const Duration(minutes: 12))
            .toUtc()
            .toIso8601String(),
      );

      await pumpProfileSync(tester);

      expect(find.text('Hace 12 min'), findsOneWidget);
    });

    testWidgets('estado running: deshabilita botón y muestra progreso', (
      tester,
    ) async {
      sync.debugSetState(active: true, phase: SyncPhase.syncing);
      sync.debugSetRunning(true);
      await pumpProfileSync(tester);

      expect(find.text('Sincronizando…'), findsOneWidget);
      expect(find.text('Espera un momento'), findsOneWidget);
      expect(find.text('En curso…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'En curso…'),
      );
      expect(button.onPressed, isNull);

      sync.debugSetRunning(false);
      sync.debugSetState(active: false, phase: SyncPhase.idle);
      await tester.pump();
    });
  });
}
