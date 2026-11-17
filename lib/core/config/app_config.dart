import 'package:flutenv/flutenv.dart';

/// Configuración global de la app resuelta desde el entorno.
///
/// Orden de resolución por clave:
///   1. `--dart-define=CLAVE=valor` — inyectado por `flutenv run|build` o por CI.
///   2. Archivo `.env` del directorio actual — solo útil en escritorio (dev).
///   3. Cadena vacía.
class AppConfig {
  AppConfig._();

  static const String _defineSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _defineSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _defineGoogleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const String _defineGoogleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  static Map<String, String> _dotEnv = const <String, String>{};

  /// Lee el `.env` del directorio de trabajo actual.
  ///
  /// En móvil el directorio actual no es el proyecto, así que no encuentra
  /// nada y queda todo en manos de los `--dart-define`.
  static void loadDotEnv() {
    try {
      _dotEnv = loadEnv() ?? const <String, String>{};
    } catch (_) {
      _dotEnv = const <String, String>{};
    }
  }

  static String _pick(String defined, String key) {
    if (defined.isNotEmpty) return defined;
    return _dotEnv[key] ?? '';
  }

  /// URL del proyecto de Supabase.
  static String get supabaseUrl => _pick(_defineSupabaseUrl, 'SUPABASE_URL');

  /// Clave publicable (`sb_publishable_...`) del proyecto de Supabase.
  static String get supabaseAnonKey =>
      _pick(_defineSupabaseAnonKey, 'SUPABASE_ANON_KEY');

  /// Client ID de Google tipo **Web**. Es el `serverClientId` que usa
  /// `google_sign_in` y el `aud` que Supabase valida al iniciar sesión.
  static String get googleServerClientId =>
      _pick(_defineGoogleServerClientId, 'GOOGLE_SERVER_CLIENT_ID');

  /// Client ID de Google tipo **iOS** (opcional, solo iOS).
  static String get googleClientId =>
      _pick(_defineGoogleClientId, 'GOOGLE_CLIENT_ID');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasGoogleConfig => googleServerClientId.isNotEmpty;

  /// Falla rápido y con un mensaje accionable si falta configuración.
  static void assertConfigured() {
    if (hasSupabaseConfig) return;
    throw StateError(
      'Falta la configuración de Supabase.\n'
      'Define SUPABASE_URL y SUPABASE_ANON_KEY, por ejemplo:\n'
      '  flutenv run\n'
      'o bien:\n'
      '  flutter run --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=...',
    );
  }
}
