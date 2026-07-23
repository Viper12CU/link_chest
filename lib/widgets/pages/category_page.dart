import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/atoms/custom_appbar.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:link_chest/widgets/organisms/category_drawer.dart';
import 'package:link_chest/widgets/templates/category_template.dart';

class CategoryPage extends StatefulWidget {
  final CategoryModel category;
  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  Color _getContrastColor(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  final SystemUiOverlayStyle _drawerOpen = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFF5A5F),
    statusBarIconBrightness: Brightness.light,
  );

  final SystemUiOverlayStyle _initial = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFF0F2F8),
    statusBarIconBrightness: Brightness.dark,
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(_initial);
  }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = ColorParse().toColor(widget.category.color);

    return Scaffold(
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          SystemChrome.setSystemUIOverlayStyle(_drawerOpen);
        } else {
          SystemChrome.setSystemUIOverlayStyle(_initial);
        }
      },
      drawer: CategoryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppbar(category: widget.category),
            Expanded(child: CategoryTemplate(category: widget.category)),
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
          AddLinkSheet.show(context, widget.category);
        },
        tooltip: "Nuevo link",
        label: Text(
          "Nuevo link",
          style: TextStyle(color: _getContrastColor(categoryColor)),
        ),
        icon: Icon(
          Icons.add,
          size: 32.0,
          color: _getContrastColor(categoryColor),
        ),
      );
}
