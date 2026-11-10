// lib/services/auth_service.dart
//
// Servicio de autenticación para Link Chest.
// Cubre: email/contraseña, Google, recuperación de contraseña,
// verificación de email, cierre de sesión y eliminación de cuenta.
//
// Dependencias (pubspec.yaml):
//   firebase_core, firebase_auth, google_sign_in (v7.x)
//
// Uso:
//   await AuthService.instance.init();   // una vez, en main(), tras Firebase.initializeApp
//   await AuthService.instance.signInWithEmail(email: '...', password: '...');

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Excepción con mensaje listo para mostrar al usuario (en español).
class AuthFailure implements Exception {
  final String message;
  final String code;
  const AuthFailure(this.message, {this.code = 'unknown'});

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  // ---------------------------------------------------------------------------
  // Inicialización
  // ---------------------------------------------------------------------------

  /// Llamar una sola vez al arrancar la app.
  ///
  /// [serverClientId] es el "Web client ID" de OAuth (Google Cloud Console >
  /// Credenciales, o en Firebase: Authentication > Google > Web SDK
  /// configuration). En Android normalmente se detecta solo desde
  /// google-services.json; pásalo solo si Google Sign-In te da error.
  Future<void> init({String? serverClientId}) async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _googleInitialized = true;
  }

  // ---------------------------------------------------------------------------
  // Estado del usuario
  // ---------------------------------------------------------------------------

  /// Usuario actual (null si no hay sesión).
  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Stream que emite cada vez que el usuario inicia o cierra sesión.
  /// Ideal para un StreamBuilder que decida qué pantalla mostrar.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Igual que authStateChanges pero también emite si cambian datos del
  /// usuario (por ejemplo, tras verificar el email o actualizar el perfil).
  Stream<User?> get userChanges => _auth.userChanges();

  // ---------------------------------------------------------------------------
  // Email y contraseña
  // ---------------------------------------------------------------------------

  /// Crea una cuenta nueva con email y contraseña.
  /// Si [displayName] se indica, se guarda en el perfil.
  /// Si [sendVerification] es true, envía el correo de verificación.
  Future<User> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
    bool sendVerification = true,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      if (sendVerification) {
        await user.sendEmailVerification();
      }
      await user.reload();
      return _auth.currentUser!;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  /// Reenvía el correo de verificación al usuario actual.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('No hay una sesión activa.', code: 'no-user');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  /// Recarga el usuario desde Firebase y devuelve si ya verificó el email.
  /// Útil en una pantalla de "revisa tu correo" con un botón "Ya verifiqué".
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  /// Cambia la contraseña del usuario actual.
  /// Requiere reautenticación reciente: se pide la contraseña actual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthFailure('No hay una sesión activa.', code: 'no-user');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  /// Inicia sesión (o crea la cuenta) con Google.
  /// Devuelve null si el usuario cancela el selector de cuentas.
  Future<User?> signInWithGoogle() async {
    try {
      if (!_googleInitialized) await init();

      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Google no devolvió un token válido. Intenta de nuevo.',
          code: 'no-id-token',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return cred.user;
    } on GoogleSignInException catch (e) {
      // El usuario cerró el selector de cuentas: no es un error real.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure(
        'No se pudo iniciar sesión con Google (${e.code.name}).',
        code: 'google-${e.code.name}',
      );
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw _unexpected(e);
    }

    // ALTERNATIVA sin el paquete google_sign_in (flujo web en Custom Tab):
    //   final cred = await _auth.signInWithProvider(GoogleAuthProvider());
    //   return cred.user;
  }

  // ---------------------------------------------------------------------------
  // Sesión y cuenta
  // ---------------------------------------------------------------------------

  /// Cierra la sesión en Firebase y en Google.
  Future<void> signOut() async {
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  /// Elimina la cuenta del usuario actual.
  /// Si Firebase pide login reciente, lanza AuthFailure con code
  /// 'requires-recent-login': pide al usuario que vuelva a iniciar sesión
  /// y reintenta.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('No hay una sesión activa.', code: 'no-user');
    }
    try {
      await user.delete();
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw _unexpected(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Errores
  // ---------------------------------------------------------------------------

  AuthFailure _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthFailure('El correo no es válido.', code: e.code);
      case 'user-disabled':
        return AuthFailure('Esta cuenta ha sido deshabilitada.', code: e.code);
      case 'user-not-found':
        return AuthFailure('No existe una cuenta con ese correo.', code: e.code);
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return AuthFailure('Correo o contraseña incorrectos.', code: e.code);
      case 'email-already-in-use':
        return AuthFailure('Ya existe una cuenta con ese correo.', code: e.code);
      case 'weak-password':
        return AuthFailure(
          'La contraseña es muy débil. Usa al menos 6 caracteres.',
          code: e.code,
        );
      case 'operation-not-allowed':
        return AuthFailure(
          'Este método de acceso no está habilitado en Firebase.',
          code: e.code,
        );
      case 'account-exists-with-different-credential':
        return AuthFailure(
          'Ya existe una cuenta con ese correo usando otro método de acceso.',
          code: e.code,
        );
      case 'too-many-requests':
        return AuthFailure(
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
          code: e.code,
        );
      case 'network-request-failed':
        return AuthFailure(
          'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
          code: e.code,
        );
      case 'requires-recent-login':
        return AuthFailure(
          'Por seguridad, vuelve a iniciar sesión para continuar.',
          code: e.code,
        );
      case 'credential-already-in-use':
        return AuthFailure(
          'Esa credencial ya está vinculada a otra cuenta.',
          code: e.code,
        );
      default:
        return AuthFailure(
          e.message ?? 'Ocurrió un error de autenticación.',
          code: e.code,
        );
    }
  }

  AuthFailure _unexpected(Object e) =>
      AuthFailure('Ocurrió un error inesperado: $e');
}
