import 'package:flutter/material.dart';
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

      // Cargar los datos iniciales
      final categoryProvider = context.read<CategoryProvider>();
      final linkProvider = context.read<LinkProvider>();

      await categoryProvider.loadAll();
      await linkProvider.loadAll();

      // Delay mínimo para que el splash no "parpadee" si la carga es muy rápida
      await Future.delayed(const Duration(milliseconds: 3500));

      if (!mounted) return;

      final int initialIndex =
          context.read<CategorySelectedProvider>().selectedIndex;
      final initialCategory = categoryProvider.getById(initialIndex) ??
          categoryProvider.getById(DatabaseHelper.defaultCategoryId)!;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CategoryPage(category: initialCategory),
        ),
      );
    } catch (e, st) {
      debugPrint('Error de inicialización: $e\n$st');
      if (mounted) {
        setState(() => _errorMessage = 'Error al iniciar la app');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SplashTemplate()
    );
  }
}