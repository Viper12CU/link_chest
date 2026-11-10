import 'package:flutter/material.dart';
import 'package:link_chest/database/database_helper.dart';
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

  final int initialIndex = categorySelectedProvider.selectedIndex;

  final initialCategory =
      categoryProvider.getById(initialIndex) ??
      categoryProvider.getById(DatabaseHelper.defaultCategoryId)!;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => (CategoryPage(category: initialCategory)),
    ),
  );
}
