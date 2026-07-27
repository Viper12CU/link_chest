import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/services/local_auth.dart';
import 'package:link_chest/widgets/atoms/biometric_auth_button.dart';
import 'package:link_chest/widgets/pages/vault_page.dart';

class AuthTemplate extends StatefulWidget {
  const AuthTemplate({super.key}); 

  @override
  State<AuthTemplate> createState() => _AuthTemplateState();
}

class _AuthTemplateState extends State<AuthTemplate> {
  DotLottieViewController? _controller;

  void _handleCheck() async {
    final success = await LocalAuthService.authenticateWithFallback(
      reason: 'Confirma tu identidad para ver los links privados',
    );

    final avalible = await LocalAuthService.canAuthenticate();

    debugPrint("Awalible: ${avalible.toString()}");

    if (success) {
      // acceso concedido
      await _controller?.play();
    } else {
      // cancelado por el usuario
      debugPrint("Canselado");
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textStyle = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          animatedHero(context),
          SizedBox(
            width: 300,
            child: Column(
              spacing: 10.0,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Vault Privado para tus links",
                  style: textStyle.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Presiona el botón de abajo para activar la autenticación biometrica.",
                  style: textStyle.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          BiometricAuthButton(onCheck: () => _handleCheck()),
        ],
      ),
    );
  }

  Center animatedHero(BuildContext context) {
    return Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DotLottieView(
              sourceType: 'asset',
              source: 'Unlock.lottie',
              autoplay: false,
              loop: false,
              onViewCreated: (controller) {
                _controller = controller;
              },
              onLoad: () {
                // Do something
              },
              onComplete: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => VaultPage()),
                );
              },
            ),
          ),
        );
  }
}
