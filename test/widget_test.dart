import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/utils/validators.dart';
import 'package:link_chest/widgets/atoms/profile_password_field.dart';

void main() {
  group('ProfilePasswordField', () {
    testWidgets('oculta la contraseña y permite mostrarla', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePasswordField(
              label: 'Contraseña',
              hintText: 'Ingresa tu contraseña',
              controller: controller,
            ),
          ),
        ),
      );

      EditableText editable() =>
          tester.widget<EditableText>(find.byType(EditableText));

      expect(editable().obscureText, isTrue);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();

      expect(editable().obscureText, isFalse);

      await tester.tap(find.byTooltip('Ocultar contraseña'));
      await tester.pump();

      expect(editable().obscureText, isTrue);

      controller.dispose();
    });
  });

  group('validators', () {
    test('validatePassword exige mínimo 6 caracteres', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });

    test('validateConfirmPassword exige coincidencia', () {
      expect(validateConfirmPassword('abc123', 'abc123'), isNull);
      expect(validateConfirmPassword('otra', 'abc123'), isNotNull);
    });
  });
}
