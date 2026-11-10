import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/providers/login_provider.dart';
import 'package:link_chest/widgets/pages/login_page.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildLoginApp() {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: const MaterialApp(home: LoginPage()),
    );
  }

  /// WelcomeHero anima en bucle infinito: pumpAndSettle nunca termina.
  Future<void> pumpTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Los bloques se muestran/ocultan con opacidad; la visibilidad real está
  /// en su FadeTransition. Cada finder debe ser único por bloque.
  double blockOpacity(WidgetTester tester, Finder text) {
    final FadeTransition fade = tester.widget<FadeTransition>(
      find.ancestor(of: text, matching: find.byType(FadeTransition)).first,
    );
    return fade.opacity.value;
  }

  final Finder welcome = find.textContaining(
    'tu cofre de links',
    findRichText: true,
  );
  final Finder choiceBlock = find.text('Inicia Sesión');
  final Finder loginBlock = find.text('Iniciar sesión con Google');
  final Finder signUpBlock = find.text('Crear cuenta con Google');

  testWidgets('muestra la bienvenida y las acciones iniciales',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginApp());
    await pumpTransition(tester);

    expect(welcome, findsOneWidget);
    expect(blockOpacity(tester, welcome), 1.0);
    expect(choiceBlock, findsOneWidget);
    expect(blockOpacity(tester, choiceBlock), 1.0);

    // Los formularios están montados pero ocultos hasta que se navega.
    expect(blockOpacity(tester, loginBlock), 0.0);
    expect(blockOpacity(tester, signUpBlock), 0.0);
  });

  testWidgets('navega al formulario de login y vuelve con "Volver"',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginApp());
    await pumpTransition(tester);

    await tester.tap(choiceBlock);
    await pumpTransition(tester);

    expect(loginBlock, findsOneWidget);
    expect(blockOpacity(tester, loginBlock), 1.0);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(blockOpacity(tester, choiceBlock), 0.0);
    expect(blockOpacity(tester, signUpBlock), 0.0);

    await tester.tap(find.text('Volver'));
    await pumpTransition(tester);

    expect(blockOpacity(tester, welcome), 1.0);
    expect(blockOpacity(tester, loginBlock), 0.0);
    expect(blockOpacity(tester, choiceBlock), 1.0);
  });

  testWidgets('navega al formulario de registro',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginApp());
    await pumpTransition(tester);

    await tester.tap(find.text('Crea una cuenta'));
    await pumpTransition(tester);

    expect(signUpBlock, findsOneWidget);
    expect(blockOpacity(tester, signUpBlock), 1.0);
    expect(find.text('Confirmar contraseña'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(blockOpacity(tester, choiceBlock), 0.0);
    expect(blockOpacity(tester, loginBlock), 0.0);
  });
}
