// lib/services/auth_service.dart
//
// Servicio de autenticación de Link Chest sobre Supabase Auth.
//
// Métodos soportados:
//   - Email + contraseña (Supabase Auth / GoTrue)
//   - Google nativo (paquete `google_sign_in` + `signInWithIdToken`)
//
// La UI consume una API estable (`AppUser`, `AuthFailure`, `currentUser`,
// `userChanges`, ...) por eso este servicio envuelve el cliente de Supabase y
// traduce los errores a mensajes en español.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:link_chest/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Excepción con mensaje listo para mostrar al usuario (en español).
class AuthFailure implements Exception {
  final String message;
  final String code;
  const AuthFailure(this.message, {this.code = 'unknown'});

  @override
  String toString() => message;
}

/// Vista de la sesión de Supabase que consume la UI.
class AppUser {
  final String id;
  final String? displayName;
  final String? email;
  final bool emailVerified;
  final bool hasPasswordProvider;

  const AppUser({
    this.id = '',
    this.displayName,
    this.email,
    this.emailVerified = false,
    this.hasPasswordProvider = false,
  });

  /// Traduce un [User] de Supabase al modelo de la app.
  factory AppUser.fromUser(User user) {
    final Map<String, dynamic> meta = user.userMetadata ?? const {};
    final String? email = user.email;

    String? name = _metaString(meta, 'display_name');
    name ??= _metaString(meta, 'full_name');
    name ??= _metaString(meta, 'name');
    if (name == null && email != null && email.contains('@')) {
      name = email.split('@').first;
    }

    return AppUser(
      id: user.id,
      displayName: name,
      email: email,
      emailVerified: user.emailConfirmedAt != null,
      hasPasswordProvider:
          (user.identities ?? const <UserIdentity>[]).any(
            (UserIdentity identity) => identity.provider == 'email',
          ),
    );
  }

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    bool? emailVerified,
    bool? hasPasswordProvider,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      hasPasswordProvider: hasPasswordProvider ?? this.hasPasswordProvider,
    );
  }

  static String? _metaString(Map<String, dynamic> meta, String key) {
    final dynamic value = meta[key];
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  AppUser? _currentUser;

  /// Usuario recién registrado que aún no confirmó su correo. Supabase no
  /// entrega sesión en ese caso, así que se guarda aparte para que la UI
  /// pueda mostrar la pantalla de verificación.
  AppUser? _pendingUser;
  String? _pendingPassword;

  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();
  final StreamController<AppUser?> _pendingController =
      StreamController<AppUser?>.broadcast();

  StreamSubscription<AuthState>? _authSubscription;
  bool _googleInitialized = false;
  String _googleServerClientId = '';

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Inicialización
  // ---------------------------------------------------------------------------

  /// Llamar una sola vez al arrancar la app.
  ///
  /// [serverClientId] es el client ID de Google tipo Web. Si se omite se usa
  /// `AppConfig.googleServerClientId`.
  Future<void> init({String? serverClientId}) async {
    _googleServerClientId = (serverClientId ?? '').trim().isNotEmpty
        ? serverClientId!.trim()
        : AppConfig.googleServerClientId.trim();

    // Google puede no estar configurado: no debe tumbar el arranque de la app.
    try {
      await _initGoogleSignIn();
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In no inicializado: $e');
    }

    _authSubscription = _client.auth.onAuthStateChange.listen(
      _handleAuthState,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[AuthService] onAuthStateChange error: $error');
      },
    );

    final User? user = _client.auth.currentUser;
    _setUser(user == null ? null : AppUser.fromUser(user));
  }

  Future<void> _initGoogleSignIn() async {
    if (_googleInitialized) return;

    final String iosClientId = AppConfig.googleClientId.trim();
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      clientId: iosClientId.isEmpty ? null : iosClientId,
    );
    _googleInitialized = true;
  }

  void _handleAuthState(AuthState state) {
    final Session? session = state.session;
    if (session == null) {
      _setUser(null);
      return;
    }
    _setUser(AppUser.fromUser(session.user));
  }

  // ---------------------------------------------------------------------------
  // Estado del usuario
  // ---------------------------------------------------------------------------

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  bool get hasPasswordProvider => _currentUser?.hasPasswordProvider ?? false;

  /// Usuario registrado a la espera de confirmar el correo, si lo hay.
  AppUser? get pendingUser => _pendingUser;

  /// Emite el estado actual y luego cada cambio de sesión.
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  /// Emite el estado actual y luego cada cambio del usuario.
  Stream<AppUser?> get userChanges async* {
    yield _currentUser;
    yield* _userController.stream;
  }

  /// Emite el usuario pendiente de confirmación y cada cambio.
  Stream<AppUser?> get pendingUserChanges async* {
    yield _pendingUser;
    yield* _pendingController.stream;
  }

  // ---------------------------------------------------------------------------
  // Email y contraseña
  // ---------------------------------------------------------------------------

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
    bool sendVerification = true,
  }) async {
    final String mail = email.trim();
    final String name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : 'Usuario';

    debugPrint(
      '[AuthService] registerWithEmail(email: $mail, displayName: $name, '
      'sendVerification: $sendVerification)',
    );

    final AuthResponse response = await _guard(
      () => _client.auth.signUp(
        email: mail,
        password: password,
        data: <String, dynamic>{'display_name': name},
      ),
    );

    final User? user = response.user;
    if (user == null) {
      throw const AuthFailure(
        'No pudimos crear la cuenta. Inténtalo de nuevo.',
        code: 'signup_failed',
      );
    }

    // Sin sesión: el proyecto exige confirmar el correo antes de entrar.
    if (response.session == null) {
      final AppUser pending = AppUser(
        id: user.id,
        displayName: name,
        email: mail,
        emailVerified: user.emailConfirmedAt != null,
        hasPasswordProvider: true,
      );
      _setPendingUser(pending, password: password);
      return pending;
    }

    _clearPending();
    final AppUser appUser = AppUser.fromUser(user);
    _setUser(appUser);
    return appUser;
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final String mail = email.trim();
    debugPrint('[AuthService] signInWithEmail(email: $mail)');

    final AuthResponse response = await _guard(
      () => _client.auth.signInWithPassword(email: mail, password: password),
    );

    final User? user = response.user;
    if (user == null) {
      throw const AuthFailure(
        'No pudimos iniciar sesión. Inténtalo de nuevo.',
        code: 'signin_failed',
      );
    }

    _clearPending();
    final AppUser appUser = AppUser.fromUser(user);
    _setUser(appUser);
    return appUser;
  }

  Future<void> sendPasswordReset(String email) async {
    debugPrint('[AuthService] sendPasswordReset(email: ${email.trim()})');
    await _guard(() => _client.auth.resetPasswordForEmail(email.trim()));
  }

  Future<void> sendEmailVerification() async {
    final String? mail = _currentUser?.email ?? _pendingUser?.email;
    if (mail == null || mail.isEmpty) {
      throw const AuthFailure(
        'No hay ninguna cuenta a verificar.',
        code: 'no_user',
      );
    }

    debugPrint('[AuthService] sendEmailVerification(email: $mail)');
    await _guard(
      () => _client.auth.resend(type: OtpType.signup, email: mail),
    );
  }

  Future<bool> refreshEmailVerified() async {
    final User? sessionUser = _client.auth.currentUser;

    // Sesión activa: refrescamos token + usuario contra el servidor.
    if (sessionUser != null) {
      await _guard(() => _client.auth.refreshSession());
      final User? refreshed = _client.auth.currentUser;
      if (refreshed == null) return false;
      _setUser(AppUser.fromUser(refreshed));
      return refreshed.emailConfirmedAt != null;
    }

    // Registro pendiente: reintentamos el login para materializar la sesión.
    final AppUser? pending = _pendingUser;
    final String? password = _pendingPassword;
    if (pending == null || pending.email == null || password == null) {
      return false;
    }

    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: pending.email!,
        password: password,
      );
      final User? user = response.user;
      if (user == null) return false;

      _clearPending();
      _setUser(AppUser.fromUser(user));
      return user.emailConfirmedAt != null;
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') return false;
      throw AuthFailure(_messageFor(e), code: e.code ?? 'unknown');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final AppUser? user = _currentUser;
    final String? mail = user?.email;
    if (mail == null) {
      throw const AuthFailure(
        'No hay ninguna sesión activa.',
        code: 'no_session',
      );
    }

    debugPrint('[AuthService] changePassword(email: $mail)');

    // Reautenticación: valida la contraseña actual antes de cambiarla.
    await _guard(
      () => _client.auth.signInWithPassword(
        email: mail,
        password: currentPassword,
      ),
    );

    await _guard(
      () => _client.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  Future<AppUser?> signInWithGoogle() async {
    debugPrint('[AuthService] signInWithGoogle()');

    if (_googleServerClientId.isEmpty) {
      throw const AuthFailure(
        'Google no está configurado. Define GOOGLE_SERVER_CLIENT_ID.',
        code: 'google_not_configured',
      );
    }

    await _initGoogleSignIn();
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    final GoogleSignInAccount account;
    try {
      account = await googleSignIn.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure(
        _googleMessageFor(e),
        code: 'google_${e.code.name}',
      );
    }

    final String? idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure(
        'No pudimos obtener el token de Google.',
        code: 'google_no_id_token',
      );
    }

    // El access token es opcional para Supabase; si el usuario no lo autoriza
    // seguimos con el id token.
    String? accessToken;
    try {
      final GoogleSignInClientAuthorization? authorization = await account
          .authorizationClient
          .authorizationForScopes(const <String>['email', 'profile']);
      accessToken = authorization?.accessToken;
    } catch (e) {
      debugPrint('[AuthService] no se pudo obtener access token de Google: $e');
    }

    final AuthResponse response = await _guard(
      () => _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      ),
    );

    final User? user = response.user;
    if (user == null) {
      throw const AuthFailure(
        'No pudimos iniciar sesión con Google.',
        code: 'google_signin_failed',
      );
    }

    _clearPending();
    final AppUser appUser = AppUser.fromUser(user);
    _setUser(appUser);
    return appUser;
  }

  // ---------------------------------------------------------------------------
  // Sesión y cuenta
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    debugPrint('[AuthService] signOut()');

    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] error al cerrar sesión en Supabase: $e');
    }

    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('[AuthService] error al cerrar sesión de Google: $e');
    }

    _clearPending();
    _setUser(null);
  }

  Future<void> deleteAccount({String? currentPassword}) async {
    final AppUser? user = _currentUser;
    if (user == null) {
      throw const AuthFailure(
        'No hay ninguna sesión activa.',
        code: 'no_session',
      );
    }

    debugPrint('[AuthService] deleteAccount(id: ${user.id})');

    // Reautenticación para probar que el titular es quien pide el borrado.
    if (currentPassword != null &&
        currentPassword.isNotEmpty &&
        user.hasPasswordProvider &&
        user.email != null) {
      await _guard(
        () => _client.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        ),
      );
    }

    final FunctionResponse response = await _guard(
      () => _client.functions.invoke('delete-account'),
    );

    if (response.status < 200 || response.status >= 300) {
      throw AuthFailure(
        _messageFromFunctionStatus(response.status),
        code: 'delete_account_failed',
      );
    }

    await signOut();
  }

  // ---------------------------------------------------------------------------
  // Estado interno
  // ---------------------------------------------------------------------------

  void _setUser(AppUser? user) {
    _currentUser = user;
    _authController.add(user);
    _userController.add(user);
  }

  void _setPendingUser(AppUser? user, {String? password}) {
    _pendingUser = user;
    if (password != null) _pendingPassword = password;
    _pendingController.add(user);
  }

  void _clearPending() {
    _pendingUser = null;
    _pendingPassword = null;
    _pendingController.add(null);
  }

  // ---------------------------------------------------------------------------
  // Errores
  // ---------------------------------------------------------------------------

  /// Ejecuta una llamada de Supabase traduciendo excepciones a [AuthFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw AuthFailure(_messageFor(e), code: e.code ?? 'unknown');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] error inesperado: $e');
      throw const AuthFailure(
        'No pudimos completar la operación. Inténtalo de nuevo.',
        code: 'unexpected',
      );
    }
  }

  String _messageFor(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'email_not_confirmed':
        return 'Confirma tu correo electrónico antes de continuar.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Ese correo ya está registrado. Intenta iniciar sesión.';
      case 'email_address_invalid':
        return 'El correo electrónico no es válido.';
      case 'weak_password':
        return 'La contraseña es demasiado débil.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
      case 'over_sms_send_rate_limit':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'password_reauthentication_failed':
      case 'invalid_password':
        return 'La contraseña actual no es correcta.';
      case 'same_password':
        return 'La nueva contraseña debe ser distinta de la actual.';
      case 'session_not_found':
      case 'session_missing':
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
      case 'provider_disabled':
        return 'Ese método de acceso no está disponible.';
      case 'access_denied':
        return 'No autorizado para realizar esta acción.';
      default:
        return 'No pudimos completar la operación. Inténtalo de nuevo.';
    }
  }

  String _googleMessageFor(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Iniciamos sesión cancelada.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google no está bien configurado en esta app.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google no está disponible en este dispositivo.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'No pudimos abrir el selector de cuentas de Google.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Hay otra cuenta de Google activa en este dispositivo.';
      default:
        return 'No pudimos iniciar sesión con Google.';
    }
  }

  String _messageFromFunctionStatus(int status) {
    switch (status) {
      case 401:
      case 403:
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
      case 404:
        return 'No encontramos la cuenta que intentas eliminar.';
      default:
        return 'No pudimos eliminar la cuenta. Inténtalo de nuevo.';
    }
  }

  /// Cierra la suscripción a Supabase y los streams internos.
  /// La app no lo llama (el servicio es un singleton), pero existe para tests.
  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    await _authController.close();
    await _userController.close();
    await _pendingController.close();
  }
}
