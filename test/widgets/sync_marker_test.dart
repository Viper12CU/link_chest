import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/widgets/atoms/sync_marker.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('SyncMarker', () {
    testWidgets('oculto sin pendiente ni error', (tester) async {
      await tester.pumpWidget(wrap(const SyncMarker()));
      expect(find.byType(SyncMarker), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Pendiente'), findsNothing);
      expect(find.text('Error de sync'), findsNothing);
    });

    testWidgets('muestra «Pendiente» con etiqueta accesible', (tester) async {
      await tester.pumpWidget(wrap(const SyncMarker(isPending: true)));

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(SyncMarker));
      expect(semantics.label, 'Pendiente de sincronizar');
    });

    testWidgets('muestra «Error de sync» con etiqueta accesible', (tester) async {
      await tester.pumpWidget(wrap(const SyncMarker(hasError: true)));

      expect(find.text('Error de sync'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(SyncMarker));
      expect(semantics.label, 'No se pudo sincronizar');
    });

    testWidgets('el error tiene prioridad sobre pendiente', (tester) async {
      await tester.pumpWidget(
        wrap(const SyncMarker(isPending: true, hasError: true)),
      );

      expect(find.text('Error de sync'), findsOneWidget);
      expect(find.text('Pendiente'), findsNothing);

      final semantics = tester.getSemantics(find.byType(SyncMarker));
      expect(semantics.label, 'No se pudo sincronizar');
    });
  });
}
