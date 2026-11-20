/// Punto de entrada para pedir una sincronización tras una escritura local.
///
/// Fase 2/3: stub. El motor real llega en fase 4; por ahora solo deja el
/// hook listo para que cada write lo llame sin cambiar de nuevo después.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  bool _running = false;

  bool get isRunning => _running;

  /// Pide sincronizar. No lanza si ya hay una en curso.
  /// TODO(sync/fase-4): implementar upload de dirty + download por cursor.
  Future<void> requestSync() async {
    if (_running) return;
    _running = true;
    try {
      // Fase 4: SyncEngine.run()
    } finally {
      _running = false;
    }
  }

  /// Detiene el bucle de sync al cerrar sesión / cambiar de usuario.
  void stop() {
    _running = false;
  }
}
