import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Maneja el guardado, carga y verificación segura del PIN
/// usando flutter_secure_storage (Keystore/Keychain nativo).
class PinManager {
  PinManager._();
  static final PinManager instance = PinManager._();

  final _storage = const FlutterSecureStorage();

  static const _keyPinHash = 'pin_hash';
  static const _keyPinSalt = 'pin_salt';

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    // Salt simple basado en timestamp; se puede reforzar con Random.secure()
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// Guarda un nuevo PIN (hash + salt), sobrescribe el anterior si existe.
  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hashedPin = _hashPin(pin, salt);

    await _storage.write(key: _keyPinHash, value: hashedPin);
    await _storage.write(key: _keyPinSalt, value: salt);
  }

  /// Verifica si el PIN ingresado coincide con el guardado.
  Future<bool> verifyPin(String inputPin) async {
    final storedHash = await _storage.read(key: _keyPinHash);
    final salt = await _storage.read(key: _keyPinSalt);

    if (storedHash == null || salt == null) return false;

    return _hashPin(inputPin, salt) == storedHash;
  }

  /// Carga si ya existe un PIN configurado (útil para saber si mostrar
  /// pantalla de "crear PIN" o "ingresar PIN").
  Future<bool> hasPin() async {
    final storedHash = await _storage.read(key: _keyPinHash);
    return storedHash != null;
  }

  /// Elimina el PIN guardado (ej. al resetear la app o cambiar el PIN).
  Future<void> deletePin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
  }
}