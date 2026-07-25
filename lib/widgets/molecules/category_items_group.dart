import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/widgets/atoms/category_drawer_item.dart';
import 'package:provider/provider.dart';

class CategoryItemsGroup extends StatefulWidget {
  const CategoryItemsGroup({super.key});

  @override
  State<CategoryItemsGroup> createState() => _CategoryItemsGroupState();
}

class _CategoryItemsGroupState extends State<CategoryItemsGroup> {
  
  
  
  @override
  Widget build(BuildContext context) {
    final CategorySelectedProvider provider = Provider.of<CategorySelectedProvider>(context);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context);
    final List<CategoryModel> categorys = categoryProvider.categories;

  

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: categorys.length,
      itemBuilder: (context, index) => CategoryDrawerItem(
        category: categorys[index],
        isSelected: provider.selectedIndex == categorys[index].id!,
        onSelected: () {
          provider.select(categorys[index].id!);
        },
      ),
    );
  }
}
