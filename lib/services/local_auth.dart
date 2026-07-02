import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class LocalAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  // ── Verificación ──────────────────────────────────────────────────────────

  static Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  // ── Autenticación ─────────────────────────────────────────────────────────

  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool stickyAuth = false,
  }) async {
    try {
      final canAuth = await canAuthenticate();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticación requerida',
            cancelButton: 'Cancelar', 
          ),
        ],
      );
    } on PlatformException catch (e) {
      // e.code puede ser: notAvailable, notEnrolled, lockedOut, permanentlyLockedOut
      throw Exception('Error de autenticación [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  static Future<bool> authenticateWithBiometrics({required String reason}) =>
      authenticate(reason: reason, biometricOnly: true);

  static Future<bool> authenticateWithFallback({required String reason}) =>
      authenticate(reason: reason, biometricOnly: false);
}
