import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:link_chest/services/local_auth.dart';
import 'package:link_chest/services/pin_manager.dart';
import 'package:link_chest/widgets/pages/vault_page.dart';

class ScreenLockService {
  static final ScreenLockService _instance = ScreenLockService._internal();

  ScreenLockService._internal();

  static ScreenLockService get instance => _instance;

  ScreenLockConfig _configStyles(ThemeData theme) {
    return ScreenLockConfig(
      themeData: theme,
      titleTextStyle: theme.textTheme.headlineMedium,
      textStyle: theme.textTheme.bodyMedium,
    );
  }

  SecretsConfig _secretsConfigStyles(ThemeData theme) {
    return SecretsConfig(
      secretConfig: SecretConfig(
        borderColor: theme.colorScheme.primary,
        enabledColor: theme.colorScheme.primary,
      ),
    );
  }

  KeyPadConfig _keyPadConfigStyles() {
    return KeyPadConfig(
      actionButtonConfig: KeyPadButtonConfig(
        buttonStyle: OutlinedButton.styleFrom(
          padding: EdgeInsets.all(0),
          side: BorderSide.none
        )
      ),
      buttonConfig: KeyPadButtonConfig(
        backgroundColor: Colors.grey[350],
      )
    );
  }

  Future<void> _screenLockWidget(bool canAuth, BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return screenLock(
      context: context,
      config: _configStyles(theme),
      secretsConfig: _secretsConfigStyles(theme),
      keyPadConfig: _keyPadConfigStyles(),
      cancelButton: Icon(Icons.close_rounded, size: 35),
      maxRetries: 3,
      retryDelay: Duration(seconds: 10),
      title: Text("Introduzca su PIN"),
      correctString:
          'dumm', // No se usa, ya que onValidate se encarga de la verificación
      onUnlocked: () async {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => VaultPage()));
      },
      onValidate: (String input) async {
        return await PinManager.instance.verifyPin(input);
      },
      customizedButtonChild: canAuth
          ? const Icon(Icons.fingerprint, size: 35.0)
          : null,
      customizedButtonTap: () async {
        if (!canAuth) {
          debugPrint("Autenticación biométrica no disponible");
          return;
        }
        await LocalAuthService.authenticateWithBiometrics(
          reason: "Accede al vault privado",
        );
      },
      onOpened: () async {
        if (!canAuth) {
          debugPrint("Autenticación biométrica no disponible");
          return;
        }
        await LocalAuthService.authenticateWithBiometrics(
          reason: "Accede al vault privado",
        );
      },
      footer: TextButton(
        onPressed: () {
          PinManager.instance.deletePin();
          Navigator.pop(context);
        },
        child: Text("Eliminar PIN (debug)"),
      ),
    );
  }

  Future<void> _screenLockCreateWidget(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return screenLockCreate(
      title: Text("Introduzca su nuevo PIN"),
      confirmTitle: Text("Confirma su nuevo PIN"),
      config: _configStyles(theme),
      secretsConfig: _secretsConfigStyles(theme),
      keyPadConfig: _keyPadConfigStyles(),
      cancelButton: Icon(Icons.close_rounded, size: 35),
      context: context,
      onConfirmed: (value) {
        debugPrint("PIN creado: $value");
        PinManager.instance.savePin(value);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => VaultPage()));
      },
    );
  }

  void handleCheck(BuildContext context) async {
    final canAuth = await LocalAuthService.canAuthenticate();
    final tienePin = await PinManager.instance.hasPin();
    // cancelado por el usuario
    if (!context.mounted) return;
    tienePin
        ? _screenLockWidget(canAuth, context)
        : _screenLockCreateWidget(context);
  }
}
