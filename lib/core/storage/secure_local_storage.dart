import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persiste la sesión de Supabase en el almacenamiento seguro del dispositivo.
///
/// `supabase_flutter` usa `SharedPreferences` por defecto, que guarda la
/// sesión (incluido el refresh token) en texto plano. Este adaptador usa
/// `flutter_secure_storage`: Keychain en iOS/macOS, cifrado con AES-GCM en
/// Android.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final String? value = await _storage.read(key: persistSessionKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
