import 'package:flutter/material.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/utils/shared/link_menu_handlers.dart';
import 'package:link_chest/widgets/atoms/empty_state.dart';
import 'package:link_chest/widgets/organisms/link_card.dart';
import 'package:provider/provider.dart';

class VaultTemplate extends StatefulWidget {
  const VaultTemplate({super.key});

  @override
  State<VaultTemplate> createState() => _VaultTemplateState();
}

class _VaultTemplateState extends State<VaultTemplate> {
  @override
  Widget build(BuildContext context) {
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context);

    final List<LinkModel> links = linkProvider.privateLinks;
    
    final LinkMenuHandlers menuHandlers = LinkMenuHandlers(context: context);

    if (links.isEmpty) {
      return const EmptyState();
    }




     return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final LinkModel link = links[index];

        return LinkCard(
          key: ValueKey(link.url),
          title: link.title,
          description: link.description,
          url: link.url,
          categoryId: link.categoryId,
          isLocked: link.status.value == "private",
          onOpen: () => menuHandlers.handleOpen(link.url),
          onCopy: () => menuHandlers.handleCopy(link.url),
          onShare: () => menuHandlers.handleShare(link),
          onLock: () => menuHandlers.handleLock(link),
          onDelete: () => menuHandlers.handleDelete(link.id),
          onMoveTo: (category) => menuHandlers.handleMoveTo(link.id, category),
          onEdit: () => menuHandlers.handleEdit(link, categoryProvider.getById(link.categoryId)!),
        );
      },
    );
  }
}