import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/services/sync/supabase_remote_sync_api.dart';
import 'package:link_chest/services/sync/sync_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fase de la sincronización para la interfaz (fuera de este plan en v1 UI).
enum SyncPhase { idle, syncing, offline, error, needsLogin }

/// Servicio de sincronización: disparadores, ejecución única, reintentos y
/// estado. Los Providers solo lo usan vía `requestSync()` tras cada escritura.
class SyncService extends ChangeNotifier {
  SyncService._();

  static final SyncService instance = SyncService._();

  /// Backoff ante errores de red: 5 s, 15 s, 60 s, 5 min.
  static const List<Duration> retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  static const Duration writeDebounce = Duration(seconds: 2);
  static const Duration periodicInterval = Duration(minutes: 5);

  DatabaseHelper get _helper => DatabaseHelper();

  SyncPhase _phase = SyncPhase.idle;
  bool _active = false;
  bool _running = false;
  bool _rerunRequested = false;
  int _retryIndex = 0;
  String? _userId;

  Timer? _debounce;
  Timer? _retry;
  Timer? _periodic;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Se emite cuando la descarga aplicó filas locales (recargar Providers).
  final StreamController<void> dataChanged = StreamController<void>.broadcast();

  /// Callback directo alternativo para recargar Providers.
  void Function()? onDataChanged;

  SyncPhase get phase => _phase;
  bool get isActive => _active;
  bool get isRunning => _running;
  String? get userId => _userId;

  bool get initialSyncDone =>
      _helper.getSyncState('initial_sync_done') == '1';

  String? get lastSyncedAt => _helper.getSyncState('last_synced_at');

  /// Filas con `dirty = 1` y sin `sync_error`.
  int get pendingCount {
    final c = _helper.db.select(
      'SELECT COUNT(*) AS n FROM ${DatabaseHelper.tableCategories} '
      'WHERE dirty = 1 AND sync_error IS NULL;',
    ).first['n'] as int;
    final l = _helper.db.select(
      'SELECT COUNT(*) AS n FROM ${DatabaseHelper.tableLinks} '
      'WHERE dirty = 1 AND sync_error IS NULL;',
    ).first['n'] as int;
    return c + l;
  }

  /// Filas con `sync_error` (fallo definitivo).
  int get errorCount {
    final c = _helper.db.select(
      'SELECT COUNT(*) AS n FROM ${DatabaseHelper.tableCategories} '
      'WHERE sync_error IS NOT NULL;',
    ).first['n'] as int;
    final l = _helper.db.select(
      'SELECT COUNT(*) AS n FROM ${DatabaseHelper.tableLinks} '
      'WHERE sync_error IS NOT NULL;',
    ).first['n'] as int;
    return c + l;
  }

  bool hasPendingChanges() => pendingCount > 0;

  // ─── CICLO DE VIDA ────────────────────────────────────────────────────────

  /// Llama el AuthGate al detectar sesión verificada.
  Future<void> start(String userId) async {
    final previous = _helper.getSyncState('current_user_id');
    if (previous != null && previous != userId) {
      // Usuario distinto: vacía tablas locales y estado de sync.
      _helper.clearAllData();
      dataChanged.add(null);
      onDataChanged?.call();
    }

    final firstActivation = !_active;
    _userId = userId;
    _helper.setSyncState('current_user_id', userId);
    _active = true;
    _retryIndex = 0;

    _watchConnectivity();
    _startPeriodic();

    if (firstActivation) {
      notifyListeners();
    }
    await syncNow();
  }

  /// Cierre de sesión: NO borra datos locales (se conservan para el mismo
  /// usuario). Se vacían solo al entrar un usuario distinto en `start`.
  void stop() {
    _active = false;
    _userId = null;
    _phase = SyncPhase.idle;
    _retryIndex = 0;
    _debounce?.cancel();
    _retry?.cancel();
    _periodic?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    notifyListeners();
  }

  // ─── DISPARADORES ─────────────────────────────────────────────────────────

  /// Tras cada escritura local (antirrebote de 2 s). No bloquea al llamador.
  Future<void> requestSync() async {
    if (!_active) return;
    _debounce?.cancel();
    _debounce = Timer(writeDebounce, () {
      unawaited(syncNow());
    });
  }

  /// Ejecución inmediata (botón futuro, sesión, foreground, conectividad).
  Future<void> syncNow() async {
    if (!_active) return;
    if (_running) {
      _rerunRequested = true;
      return;
    }

    _running = true;
    _setPhase(SyncPhase.syncing);

    try {
      if (!await _hasConnectivity()) {
        _setPhase(SyncPhase.offline);
        _scheduleRetry();
        return;
      }

      final engine = SyncEngine(
        helper: _helper,
        api: SupabaseRemoteSyncApi(Supabase.instance.client),
      );
      final result = await engine.run();
      _retryIndex = 0;
      _setPhase(SyncPhase.idle);
      if (result.downloadedTotal > 0) {
        dataChanged.add(null);
        onDataChanged?.call();
      }
    } on SyncAuthException {
      final renewed = await _tryRenewSession();
      if (!renewed) {
        _setPhase(SyncPhase.needsLogin);
        return;
      }
      _running = false;
      _rerunRequested = false;
      await syncNow();
      return;
    } catch (e, st) {
      debugPrint('[SyncService] error: $e\n$st');
      if (SyncEngine.isAuthError(e)) {
        final renewed = await _tryRenewSession();
        if (!renewed) {
          _setPhase(SyncPhase.needsLogin);
          return;
        }
        _running = false;
        _rerunRequested = false;
        await syncNow();
        return;
      }
      if (SyncEngine.isNetworkError(e)) {
        _setPhase(SyncPhase.offline);
        _scheduleRetry();
        return;
      }
      _setPhase(SyncPhase.error);
      _scheduleRetry();
      return;
    } finally {
      _running = false;
      if (_rerunRequested && _active && _phase != SyncPhase.needsLogin) {
        _rerunRequested = false;
        unawaited(syncNow());
      } else {
        _rerunRequested = false;
        notifyListeners();
      }
    }
  }

  /// Para la interfaz: fuerza una ronda completa.
  Future<void> runInitialSync() => syncNow();

  // ─── INTERNOS ─────────────────────────────────────────────────────────────

  void _setPhase(SyncPhase next) {
    if (_phase == next) return;
    _phase = next;
    notifyListeners();
  }

  void _scheduleRetry() {
    if (!_active) return;
    _retry?.cancel();
    final delay = retryDelays[
        _retryIndex < retryDelays.length ? _retryIndex : retryDelays.length - 1];
    _retryIndex++;
    _retry = Timer(delay, () {
      unawaited(syncNow());
    });
  }

  void _resetRetryBackoff() {
    _retryIndex = 0;
    _retry?.cancel();
  }

  void _startPeriodic() {
    _periodic?.cancel();
    _periodic = Timer.periodic(periodicInterval, (_) {
      if (_active) unawaited(syncNow());
    });
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (online && _active) {
        _resetRetryBackoff();
        unawaited(syncNow());
      }
    });
  }

  Future<bool> _hasConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Si falla el check, intenta de todas formas (puede seguir online).
      return true;
    }
  }

  Future<bool> _tryRenewSession() async {
    try {
      final client = Supabase.instance.client;
      final res = await client.auth.refreshSession();
      return res.session != null;
    } catch (e) {
      debugPrint('[SyncService] renew failed: $e');
      return false;
    }
  }
}
