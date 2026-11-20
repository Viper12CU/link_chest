import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/widgets/pages/category_page.dart';
import 'package:provider/provider.dart';

void navigateBeforeLogin(BuildContext context) {
  final categorySelectedProvider = Provider.of<CategorySelectedProvider>(
    context,
    listen: false,
  );
  final categoryProvider = Provider.of<CategoryProvider>(
    context,
    listen: false,
  );

  final String? selectedId = categorySelectedProvider.selectedId;

  final CategoryModel? initialCategory =
      (selectedId != null ? categoryProvider.getById(selectedId) : null) ??
      categoryProvider.defaultCategory ??
      categoryProvider.categories.firstOrNull;

  if (initialCategory == null) {
    // Sin datos locales aún (primera sincronización no terminó).
    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => CategoryPage(category: initialCategory),
    ),
  );
}
