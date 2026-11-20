import 'package:flutter/material.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/organisms/auth_gate.dart';
import 'package:link_chest/widgets/templates/splash_template.dart';
import 'package:provider/provider.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/widgets/pages/category_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await DatabaseHelper().init();

      if (!mounted) return;
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final linkProvider = Provider.of<LinkProvider>(context, listen: false);
      final versionProvider = Provider.of<VersionProvider>(
        context,
        listen: false,
      );

      // La descarga del motor notifica a los Providers para recargar.
      SyncService.instance.onDataChanged = () {
        categoryProvider.loadAll();
        linkProvider.loadAll();
      };

      await categoryProvider.loadAll();
      await linkProvider.loadAll();
      await versionProvider.init();

      await Future.delayed(const Duration(milliseconds: 3000));

      if (!mounted) return;

      final categorySelectedProvider = Provider.of<CategorySelectedProvider>(
        context,
        listen: false,
      );
      await categorySelectedProvider.init();

      final String? selectedId = categorySelectedProvider.selectedId;
      final CategoryModel? initialCategory =
          (selectedId != null ? categoryProvider.getById(selectedId) : null) ??
          categoryProvider.defaultCategory ??
          categoryProvider.categories.firstOrNull;

      await AuthService.instance.authStateChanges.first;
      if (!mounted) return;

      // Sin categorías locales aún: AuthGate decide (login / espera de sync).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AuthGate(
            home: initialCategory != null
                ? CategoryPage(category: initialCategory)
                : const _WaitingSyncHome(),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error de inicialización: $e\n$st');
      if (mounted) {
        setState(() => _errorMessage = 'Error al iniciar la app: $e\n$st ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _errorMessage != null
          ? Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : SplashTemplate(),
    );
  }
}

/// Placeholder hasta que la primera sincronización traiga datos.
/// (La pantalla de preparación de cuenta queda fuera de este plan.)
class _WaitingSyncHome extends StatelessWidget {
  const _WaitingSyncHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparando tus datos…',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'La primera sincronización los cargará en este dispositivo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
