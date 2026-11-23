import 'package:flutter/material.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/utils/shared/sync_ui_helpers.dart';
import 'package:link_chest/widgets/atoms/confirm_dialog.dart';
import 'package:link_chest/widgets/atoms/sync_marker.dart';
import 'package:link_chest/widgets/organisms/add_category_sheet.dart';
import 'package:link_chest/widgets/organisms/auth_gate.dart';
import 'package:link_chest/widgets/pages/category_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final List<LinkModel> links = linkProvider.byCategory(category.id ?? '');

    void handleDeleteCategory(String? categoryId) {
      if (categoryId == null) return;
      ConfirmDialog.show(
        context: context,
        title: '¿Eliminar categoría?',
        description:
            'Elimina esta categoría y sus links o reasignalos a la categoría por defecto.',
        actions: [
          ConfirmAction(
            label: 'Eliminar y Reasignar',
            style: ConfirmActionStyle.destructive,
            onTap: () async {
              await categoryProvider.deleteAndReassign(categoryId);
              await linkProvider.reloadAfterCategoryChange();
              if (context.mounted) {
                await showOfflineSaveToastIfNeeded(context);
              }
            },
          ),
          ConfirmAction(
            label: 'Eliminar Completamente',
            style: ConfirmActionStyle.destructive,
            onTap: () async {
              await categoryProvider.deleteWithLinks(categoryId);
              await linkProvider.reloadAfterCategoryChange();
              if (context.mounted) {
                await showOfflineSaveToastIfNeeded(context);
              }
            },
          ),
        ],
      );
    }

    void handleEditCategory(CategoryModel category) {
      AddCategorySheet.show(context, categroyToEdit: category, isEditing: true);
    }

    final ThemeData theme = Theme.of(context);

    final List<SlidableAction> actions = [
      SlidableAction(
        backgroundColor: theme.scaffoldBackgroundColor,
        onPressed: (_) => handleDeleteCategory(category.id),
        icon: Icons.delete,
        label: "eliminar",
        foregroundColor: theme.colorScheme.error,
      ),
      SlidableAction(
        backgroundColor: theme.scaffoldBackgroundColor,
        onPressed: (_) => handleEditCategory(category),
        icon: Icons.edit,
        label: "editar",
        foregroundColor: theme.colorScheme.primary,
      ),
    ];

    Widget inkWellWidget() {
      return InkWell(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  spacing: 10,
                  children: [
                    Text(category.icon, style: TextStyle(fontSize: 22)),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: theme.textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (category.isPendingSync || category.hasSyncError)
                            SyncMarker(
                              isPending: category.isPendingSync,
                              hasError: category.hasSyncError,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                spacing: 12,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ColorParse().toColor(category.color),
                      shape: BoxShape.circle,
                    ),
                    height: 15,
                    width: 15,
                  ),
                  Text(links.length.toString()),
                ],
              ),
            ],
          ),
        ),
        onTap: () {
          onSelected?.call();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  AuthGate(home: CategoryPage(category: category)),
            ),
          );
        },
      );
    }

    // La categoría por defecto no se edita ni se borra.
    if (category.isDefault) {
      return inkWellWidget();
    }

    return Slidable(
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: actions,
      ),
      child: inkWellWidget(),
    );
  }
}
