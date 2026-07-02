import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/atoms/connfirm_dialog.dart';
import 'package:link_chest/widgets/pages/category_page.dart';
import 'package:provider/provider.dart';

class CategoryDrawerItem extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback? onSelected;

  const CategoryDrawerItem({
    super.key,

    this.isSelected = false,
    this.onSelected,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );

    void handleDeleteCategory(int? categoryId) {
      ConfirmDialog.show(
        context: context,
        title: '¿Eliminar categoría?',
        description: 'Esta acción no se puede deshacer.',
        actions: [
          ConfirmAction(
            label: 'Eliminar',
            style: ConfirmActionStyle.destructive,
            onTap: () async =>
                await categoryProvider.deleteWithLinks(categoryId!),
          ),
        ],
      );
    }

    final List<SlidableAction> actions = [
      SlidableAction(
        onPressed: (_) => handleDeleteCategory(category.id),
        icon: Icons.delete,
        label: "delete",
      ),
      SlidableAction(
        onPressed: (_) {
          // Implement edit functionality here
        },
        icon: Icons.edit,
        label: "edit",
      ),
    ];

    Widget inkWellWidget() {
      return InkWell(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Text(category.icon, style: TextStyle(fontSize: 22)),
                  Text(
                    category.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: ColorParse().toColor(category.color),
                  shape: BoxShape.circle,
                ),
                height: 15,
                width: 15,
              ),
            ],
          ),
        ),
        onTap: () {
          onSelected?.call();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CategoryPage(category: category),
            ),
          );
        },
      );
    }

    return category.id == DatabaseHelper.defaultCategoryId
        ? inkWellWidget()
        : Slidable(
            startActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: category.id == DatabaseHelper.defaultCategoryId
                  ? []
                  : actions,
            ),
            child: inkWellWidget(),
          );
  }
}
