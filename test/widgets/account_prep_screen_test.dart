import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/organisms/account_prep_screen.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  final sync = SyncService.instance;

  setUp(() {
    db = sqlite3.openInMemory();
    DatabaseHelper.upgrade(db);
    helper = DatabaseHelper.forTest(db);
    // Inactivo: runInitialSync en initState no debe tocar red/Supabase.
    sync.debugSetState(active: false, phase: SyncPhase.idle);
  });

  tearDown(() {
    sync.debugSetState(active: false, phase: SyncPhase.idle);
    helper.close();
  });

  Future<void> pumpPrep(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AccountPrepScreen()),
    );
    await tester.pump();
  }

  group('AccountPrepScreen', () {
    testWidgets('sin sync inicial → «Preparando tu cuenta…»', (tester) async {
      await pumpPrep(tester);

      expect(find.text('Preparando tu cuenta…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text(
          'La primera sincronización cargará tus datos en este dispositivo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('offline → aviso de conexión + Reintentar', (tester) async {
      sync.debugSetState(active: false, phase: SyncPhase.offline);
      await pumpPrep(tester);

      expect(
        find.text(
          'Necesitas conexión para preparar tu cuenta por primera vez.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
      expect(find.text('Preparando tu cuenta…'), findsNothing);
    });

    testWidgets('fallo → «No se pudo preparar tu cuenta» + Reintentar', (
      tester,
    ) async {
      sync.debugSetState(active: false, phase: SyncPhase.error);
      await pumpPrep(tester);

      expect(find.text('No se pudo preparar tu cuenta'), findsOneWidget);
      expect(find.text('Revisa tu conexión e inténtalo de nuevo.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
      expect(find.text('Preparando tu cuenta…'), findsNothing);
    });

    testWidgets('needsLogin → aviso de sesión + Iniciar sesión', (tester) async {
      sync.debugSetState(active: false, phase: SyncPhase.needsLogin);
      await pumpPrep(tester);

      expect(
        find.text('Tu sesión expiró. Inicia sesión para continuar.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Iniciar sesión'),
        findsOneWidget,
      );
    });

    testWidgets('syncing → estado de preparación', (tester) async {
      sync.debugSetState(active: false, phase: SyncPhase.syncing);
      await pumpPrep(tester);

      expect(find.text('Preparando tu cuenta…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
