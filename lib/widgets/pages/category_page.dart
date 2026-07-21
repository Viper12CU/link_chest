import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/atoms/custom_appbar.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:link_chest/widgets/organisms/category_drawer.dart';
import 'package:link_chest/widgets/templates/category_template.dart';

class CategoryPage extends StatelessWidget {
  final CategoryModel category;
  const CategoryPage({super.key, required this.category});

  Color _getContrastColor(Color background) {
      final brightness = ThemeData.estimateBrightnessForColor(background);
      return brightness == Brightness.dark ? Colors.white : Colors.black;
    }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = ColorParse().toColor(category.color);

    

    return Scaffold(
    
      drawer: CategoryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppbar(category: category),
            Expanded(child: CategoryTemplate(category: category)),
          ],
        ),
      ),
      floatingActionButton: addButton(context, categoryColor),
    );
  }

  FloatingActionButton addButton(BuildContext context, Color categoryColor) =>
      FloatingActionButton.extended(
        elevation: 4.0,
        backgroundColor: categoryColor,
        onPressed: () {
          AddLinkSheet.show(context, category);
        },
        tooltip: "Nuevo link",
        label: Text("Nuevo link", style: TextStyle(color: _getContrastColor(categoryColor))),
        icon: Icon(Icons.add, size: 32.0, color: _getContrastColor(categoryColor),),
      );
}
