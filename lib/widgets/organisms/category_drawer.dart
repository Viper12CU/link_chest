import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/widgets/molecules/button_about_dialog.dart';
import 'package:link_chest/widgets/molecules/category_items_group.dart';
import 'package:link_chest/widgets/organisms/add_category_sheet.dart';

class CategoryDrawer extends StatefulWidget {
  const CategoryDrawer({super.key});

  @override
  State<CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<CategoryDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          header(),
          Expanded(child: CategoryItemsGroup()),
          ButtonAboutDialog(),
        ],
      ),
    );
  }

  Widget header() {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ClipPath(
      clipBehavior: Clip.hardEdge,
      clipper: DirectionalWaveClipper(
        horizontalPosition: HorizontalPosition.right,
      ),

      child: Container(
        padding: EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 6.0),
        height: 270.0,
        width: double.infinity,
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Link Chest",
              style: textTheme.displayMedium!.copyWith(color: Colors.white),
            ),
            Text(
              "Tú colección personal de links",
              style: textTheme.labelLarge!.copyWith(color: Colors.white),
            ),
            SizedBox(height: 20.0),
            addCategoryButton(),
          ],
        ),
      ),
    );
  }

  Widget addCategoryButton() {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white, width: 2),
      ),
      onPressed: () {
        AddCategorySheet.show(context);
      },
      child: Row(
        spacing: 10.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.white),

          Text(
            "Agregar categoría",
            style: textTheme.labelLarge!.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
