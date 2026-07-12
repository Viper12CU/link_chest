import 'package:flutter/material.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/widgets/atoms/visibility_switch.dart';
import 'package:provider/provider.dart';

class AddLinkSheet extends StatefulWidget {
  final LinkModel? linkToEdit;
  final bool isEditing;
  final CategoryModel initialCategory;
  const AddLinkSheet({
    super.key,
    required this.initialCategory,
    this.linkToEdit,
    this.isEditing = false,
  });

  static void show(
    BuildContext context,
    CategoryModel initialCategory, {
    LinkModel? linkToEdit,
    bool isEditing = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddLinkSheet(
        initialCategory: initialCategory,
        linkToEdit: linkToEdit,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends State<AddLinkSheet> {
  LinkStatus status = LinkStatus.public;
  int? _selectedCategoryId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategory.id;
    if (widget.linkToEdit != null && widget.isEditing) {
      setState(() {
        status = widget.linkToEdit!.status;
        _titleController.text = widget.linkToEdit!.title;
        _descriptionController.text = widget.linkToEdit!.description ?? "";
        _urlController.text = widget.linkToEdit!.url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );
    final List<CategoryModel> categorys = categoryProvider.categories;
    final CategoryModel selectedCategory = categorys.firstWhere(
      (category) => category.id == _selectedCategoryId,
      orElse: () => widget.initialCategory,
    );

    void handlerSubmit() async {
      final newLink = LinkModel(
        id: widget.linkToEdit?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        url: _urlController.text,
        categoryId: _selectedCategoryId ?? selectedCategory.id!,
        status: status,
      );

      if (widget.isEditing) {
        await linkProvider.update(newLink);
      } else {
        await linkProvider.add(newLink);
      }
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
            DropdownButtonFormField<int>(
              initialValue: _selectedCategoryId,
              hint: Text(widget.initialCategory.title),
              items: categorys
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Row(
                        spacing: 10,
                        children: [Text(e.icon), Text(e.title)],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (item) => setState(() => _selectedCategoryId = item),
            ),

            const SizedBox(height: 16),

            // ── Visibility toggle ───────────────────────────
            Text('Visibility', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            VisibilitySwitch(
              status: status,
              onChanged: (v) => setState(() => status = v),
            ),

            const SizedBox(height: 20),

            // ── Save button ─────────────────────────────────
            ElevatedButton(
              onPressed: () => {handlerSubmit(), Navigator.pop(context)},
              child: Text(widget.isEditing ? 'Guardar Cambios' : 'Agregar Link'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Visibility switch ────────────────────────────────────────
