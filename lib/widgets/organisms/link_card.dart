import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/widgets/atoms/category_badge.dart';
import 'package:provider/provider.dart';

import '../molecules/link_card_menu.dart';

class LinkCard extends StatefulWidget {
  final String title;
  final String? description;
  final String url;
  final int? categoryId;
  final bool isLocked;
  final VoidCallback? onOpen;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onLock;
  final VoidCallback? onDelete;
  final ValueChanged<int?>? onMoveTo;
  final VoidCallback? onEdit;

  const LinkCard({
    super.key,
    required this.title,
    required this.description,
    required this.url,
    this.categoryId,
    this.isLocked = false,
    this.onOpen,
    this.onCopy,
    this.onShare,
    this.onLock,
    this.onDelete,
    this.onMoveTo,
    this.onEdit

  });

  @override
  State<LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends State<LinkCard> {
  late CategoryModel category;

  void _loadCategory() {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    category = categoryProvider.getById(widget.categoryId!)!;
  }



@override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _loadCategory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Head ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isLocked) ...[const SizedBox(width: 8)],
                    ],
                  ),
                ),
                CardMenu(
                  isLocked: widget.isLocked,
                  onCopy: widget.onCopy,
                  onShare: widget.onShare,
                  onLock: widget.onLock,
                  onDelete: widget.onDelete,
                  onMoveTo: widget.onMoveTo,
                  onEdit: widget.onEdit,
                ),
              ],
            ),

            const SizedBox(height: 5),

            // ── Description ──────────────────────────────
            Text(
              widget.description!.isNotEmpty ? widget.description! : 'Sin descripción',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),

            // ── Bottom row ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onOpen,
                    icon: const Icon(Icons.open_in_new, size: 13),
                    label: Text(
                      widget.url,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.isLocked)
                CategoryBadge(category: category)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

