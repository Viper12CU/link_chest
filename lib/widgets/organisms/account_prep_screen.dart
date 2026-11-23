import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/organisms/auth_gate.dart';
import 'package:link_chest/widgets/pages/category_page.dart';
import 'package:provider/provider.dart';

/// Preparación de cuenta tras el primer login: espera la primera sync.
/// Éxito → pantalla principal. Fallo → reintento. Sin red → aviso.
class AccountPrepScreen extends StatefulWidget {
  const AccountPrepScreen({super.key});

  @override
  State<AccountPrepScreen> createState() => _AccountPrepScreenState();
}

class _AccountPrepScreenState extends State<AccountPrepScreen> {
  late final SyncService _sync;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _sync = SyncService.instance;
    _sync.addListener(_onSyncChanged);
    if (!_sync.initialSyncDone) {
      _sync.runInitialSync();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHomeIfReady());
    }
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted || _navigated) return;
    setState(() {});
    if (_sync.initialSyncDone) {
      _goHomeIfReady();
    }
  }

  void _retry() {
    _sync.runInitialSync();
  }

  void _goHomeIfReady() {
    if (_navigated || !mounted) return;

    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final selectedProvider = Provider.of<CategorySelectedProvider>(
      context,
      listen: false,
    );

    final String? selectedId = selectedProvider.selectedId;
    final CategoryModel? category =
        (selectedId != null ? categoryProvider.getById(selectedId) : null) ??
        categoryProvider.defaultCategory ??
        categoryProvider.categories.firstOrNull;

    if (category == null) return;

    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AuthGate(home: CategoryPage(category: category)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final phase = _sync.phase;
    final bool offline = phase == SyncPhase.offline;
    final bool failed = phase == SyncPhase.error;
    final bool needsLogin = phase == SyncPhase.needsLogin;
    final bool preparing = phase == SyncPhase.syncing ||
        (!offline && !failed && !needsLogin && !_sync.initialSyncDone);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preparing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Preparando tu cuenta…',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'La primera sincronización cargará tus datos en este dispositivo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (offline) ...[
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Necesitas conexión para preparar tu cuenta por primera vez.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ] else if (needsLogin) ...[
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu sesión expiró. Inicia sesión para continuar.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AuthGate(
                          home: SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Iniciar sesión'),
                ),
              ] else if (failed) ...[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo preparar tu cuenta',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu conexión e inténtalo de nuevo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
