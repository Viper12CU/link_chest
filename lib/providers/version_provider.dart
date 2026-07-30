import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pub_semver/pub_semver.dart';

// Configuración de GitHub (cámbiala por tu repositorio)
const String _githubOwner = 'Viper12CU';
const String _githubRepo = 'link_chest';
// Opcional: si usas token para aumentar límite de peticiones
// const String _githubToken = 'tu_token_personal';

class VersionProvider extends ChangeNotifier {
  // Estado interno
  String _currentVersion = '0.0.0';
  String _latestVersion = '0.0.0';
  String _latestReleaseDate = '';
  bool _hasUpdate = false;
  bool _isLoading = false;
  bool _isNotified = false; // si ya se mostró el diálogo para esta versión

  // Getters públicos
  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  String get latestReleaseDate => _latestReleaseDate;
  bool get hasUpdate => _hasUpdate;
  bool get isLoading => _isLoading;
  bool get isNotified => _isNotified;


  // Clave para SharedPreferences
  static const String _prefKey = 'last_notified_version';

  /// Inicializa el provider: obtiene versión local y de GitHub, y compara.
  Future<void> init() async {
    // Evita múltiples llamadas simultáneas
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Obtener versión local
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;


      // 2. Obtener última versión de GitHub
      final latest = await _fetchLatestGitHubVersion();
      if (latest != null) {
        _latestVersion = latest;
        // 3. Comparar
        _hasUpdate = _isNewVersionAvailable(_currentVersion, _latestVersion);
      } else {
        // Si falla la petición, asumimos que no hay actualización
        _hasUpdate = false;
      }



      // 4. Verificar si ya notificamos esta versión
      if (_hasUpdate) {
        final prefs = await SharedPreferences.getInstance();
        final lastNotified = prefs.getString(_prefKey) ?? '';
        _isNotified = (lastNotified == _latestVersion);
      } else {
        _isNotified = true; // No hay actualización, no notificar
      }
    } catch (e) {
      // En caso de error, no mostrar actualización
      _hasUpdate = false;
      _isNotified = true;
      debugPrint('Error en VersionProvider.init: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }


  }

  /// Obtiene el tag del último release desde la API de GitHub.
  Future<String?> _fetchLatestGitHubVersion() async {
    final url = Uri.https(
      'api.github.com',
      '/repos/$_githubOwner/$_githubRepo/releases/latest',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MiAppFlutter/1.0',
          // Si usas token: 'Authorization': 'token $_githubToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(data.toString());
        String tag = data['tag_name'] ?? '';
        // Limpia la 'v' inicial si existe
        _latestReleaseDate = DateFormat('dd MMM yyyy').format(DateTime.parse(data['published_at']));
        return tag.replaceFirst(RegExp(r'^v'), '');
      } else {
        debugPrint('Error GitHub: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción de red: $e');
      return null;
    }
  }

  /// Compara dos versiones usando pub_semver.
  bool _isNewVersionAvailable(String current, String latest) {
    try {
      final currentVer = Version.parse(current);
      final latestVer = Version.parse(latest);
      return latestVer > currentVer;
    } catch (e) {
      // Si falla el parseo, comparación simple como fallback
      return current.compareTo(latest) < 0;
    }
  }

  /// Marca la versión actual como notificada (se guarda en SharedPreferences).
  /// Debe llamarse cuando se muestra o se cierra el diálogo de actualización.
  Future<void> markAsNotified() async {
    if (_hasUpdate && !_isNotified) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _latestVersion);
      _isNotified = true;
      notifyListeners();
    }
  }

  /// Permite forzar una comprobación manual desde la UI.
  Future<void> checkForUpdateManually() async {
    // Limpiamos el estado de notificación para que pueda volver a mostrarse
    _isNotified = false;
    await init(); // Re-ejecuta toda la lógica
  }

  /// Resetea la notificación (útil para pruebas).
  Future<void> resetNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _isNotified = false;
    // Si hay actualización, se podrá mostrar de nuevo
    if (_hasUpdate) {
      _isNotified = false;
      notifyListeners();
    }
  }
}