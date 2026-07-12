import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:link_chest/widgets/organisms/category_drawer.dart';
import 'package:link_chest/widgets/pages/auth_page.dart';
import 'package:link_chest/widgets/templates/category_template.dart';

class CategoryPage extends StatelessWidget {
  final CategoryModel category;
  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = ColorParse().toColor(category.color);

    return Scaffold(
      appBar: AppBar(
        
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AuthPage()),
            );
          },
          child: Row(
            spacing: 12.0,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(category.icon, style: TextStyle(fontSize: 18)),
              Text(category.title),
            ],
          ),
        ),
        backgroundColor: categoryColor ,
      ),
      drawer: CategoryDrawer(),
      body: CategoryTemplate(category: category,),
      floatingActionButton: addButton(context, categoryColor),
    );



    
  }

  FloatingActionButton addButton(BuildContext context, Color categoryColor) =>
      FloatingActionButton.extended(
        backgroundColor: categoryColor,
        onPressed: () {
          AddLinkSheet.show(context, category);
        },
        tooltip: "Nuevo link",
        label: Text("Nuevo link"),
        icon: Icon(Icons.add, size: 32.0),
      );
}
