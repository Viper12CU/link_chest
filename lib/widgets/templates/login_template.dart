import 'package:flutter/material.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/providers/login_provider.dart';
import 'package:link_chest/widgets/pages/category_page.dart';
import 'package:provider/provider.dart';

class LoginTemplate extends StatelessWidget {

  const LoginTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginProvider loginProvider = Provider.of<LoginProvider>(
      context,
      listen: false,
    );
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

    return Center(
      child: ElevatedButton(
        onPressed: () {
          loginProvider.signIn();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => (CategoryPage(category: initialCategory,))),
          );
        },
        child: Text("Iniciar"),
      ),
    );
  }
}
