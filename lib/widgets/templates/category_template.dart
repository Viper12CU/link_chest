import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/utils/shared/link_menu_handlers.dart';
import 'package:link_chest/widgets/atoms/empty_state.dart';
import 'package:link_chest/widgets/organisms/link_card.dart';
import 'package:provider/provider.dart';

class CategoryTemplate extends StatefulWidget {
  final CategoryModel category;
  const CategoryTemplate({super.key, required this.category});

  @override
  State<CategoryTemplate> createState() => _CategoryTemplateState();
}

class _CategoryTemplateState extends State<CategoryTemplate> {
  @override
  Widget build(BuildContext context) {
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final List<LinkModel> links = linkProvider.byCategory(widget.category.id!);
    final bool isLarge = MediaQuery.of(context).size.width >= 600;

    final LinkMenuHandlers menuHandlers = LinkMenuHandlers(context: context);

    if (links.isEmpty) {
      return const EmptyState();
    }

    return MasonryGridView.count(
      crossAxisCount: 1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final LinkModel link = links[index];

        return LinkCard(
          key: ValueKey(link.url),
          title: link.title,
          description: link.description,
          url: link.url,
          categoryId: widget.category.id,
          isLocked: link.status.value == "private",
          onOpen: () => menuHandlers.handleOpen(link.url),
          onCopy: () => menuHandlers.handleCopy(link.url),
          onShare: () => menuHandlers.handleShare(link),
          onLock: () => menuHandlers.handleLock(link),
          onDelete: () => menuHandlers.handleDelete(link.id),
          onMoveTo: (category) => menuHandlers.handleMoveTo(link.id, category),
          onEdit: () => menuHandlers.handleEdit(link, widget.category),
        );
      },
    );
  }
}
