import 'package:flutter/material.dart';
import 'package:link_chest/services/local_auth.dart';

class AuthTemplate extends StatelessWidget {
  const AuthTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    void handleCheck() async {
      final success = await LocalAuthService.authenticateWithFallback(
        reason: 'Confirma tu identidad para ver los links privados',
      );

      if (success) {
        // acceso concedido
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Acceso concedido')));
        }
      } else {
        // cancelado por el usuario
      }
    }

    return Center(
      child: ElevatedButton(
        onPressed: () => handleCheck(),
        child: Text("AUHT PAGE"),
      ),
    );
  }
}
