import 'package:flutter/material.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:provider/provider.dart';

class AddLinkSheet extends StatefulWidget {
  final CategoryModel initialCategory;
  const AddLinkSheet({super.key, required this.initialCategory});

  static void show(BuildContext context, CategoryModel initialCategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddLinkSheet(initialCategory: initialCategory),
    );
  }

  @override
  State<AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends State<AddLinkSheet> {
  LinkStatus status = LinkStatus.public;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );
    final List<CategoryModel> categorys = categoryProvider.categories;
    CategoryModel selectedCategory = widget.initialCategory;

    void handlerSubmit() {
      final Map<String, dynamic> linkMap = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'url': _urlController.text,
        'category_id': selectedCategory.id,
        'status': status.value,
      };

      final newLink = LinkModel.fromMap(linkMap);

      linkProvider.add(newLink);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ───────────────────────────────────────
            Text('Add Link', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 18),

            // ── Link title field ────────────────────────────
            Text('Title', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Figma board'),
            ),

            const SizedBox(height: 16),

            // ── Description field ───────────────────────────
            Text(
              'Description (optional)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What is this link about?',
              ),
            ),

            const SizedBox(height: 16),

            // ── URL field ───────────────────────────────────
            Text('URL', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://',
                prefixIcon: Icon(Icons.link, color: cs.tertiary, size: 18),
              ),
            ),

            const SizedBox(height: 16),

            // ── Category selector ───────────────────────────
            Text('Category', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            DropdownButtonFormField<CategoryModel>(
              initialValue: selectedCategory,
              hint: Text(widget.initialCategory.title),
              items: categorys
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Row(spacing: 10,children: [Text(e.icon), Text(e.title)]),
                    ),
                  )
                  .toList(),
              onChanged: (item) => setState(() => selectedCategory = item!),
            ),

            const SizedBox(height: 16),

            // ── Visibility toggle ───────────────────────────
            Text('Visibility', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            _VisibilitySwitch(
              status: status,
              onChanged: (v) => setState(() => status = v),
            ),

            const SizedBox(height: 20),

            // ── Save button ─────────────────────────────────
            ElevatedButton(
              onPressed: () => {handlerSubmit(), Navigator.pop(context)},
              child: const Text('Save Link'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Visibility switch ────────────────────────────────────────
class _VisibilitySwitch extends StatelessWidget {
  final LinkStatus status;
  final ValueChanged<LinkStatus> onChanged;

  const _VisibilitySwitch({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = status == LinkStatus.private
        ? cs.tertiaryContainer
        : cs.tertiary;

    return GestureDetector(
      onTap: () => onChanged(
        status == LinkStatus.public ? LinkStatus.private : LinkStatus.public,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        height: 48,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline),
        ),
        child: Stack(
          children: [
            // ── Labels ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Public',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == LinkStatus.public
                            ? Colors.white
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Private',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == LinkStatus.private
                            ? Colors.white
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Thumb ──────────────────────────────────────
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              alignment: status == LinkStatus.private
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == LinkStatus.private
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status == LinkStatus.private ? 'Private' : 'Public',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
