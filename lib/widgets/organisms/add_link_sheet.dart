import 'package:flutter/material.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/services/local_auth.dart';
import 'package:link_chest/widgets/atoms/visibility_switch.dart';
import 'package:provider/provider.dart';

class AddLinkSheet extends StatefulWidget {
  final LinkModel? linkToEdit;
  final bool isEditing;
  final bool isShared;

  final CategoryModel initialCategory;

  const AddLinkSheet({
    super.key,
    required this.initialCategory,
    this.linkToEdit,
    this.isEditing = false,
    this.isShared = false,
  });

  static void show(
    BuildContext context,
    CategoryModel initialCategory, {
    LinkModel? linkToEdit,
    bool isEditing = false,
    bool isShared = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddLinkSheet(
        initialCategory: initialCategory,
        linkToEdit: linkToEdit,
        isEditing: isEditing,
        isShared: isShared,
      ),
    );
  }

  @override
  State<AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends State<AddLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  LinkStatus status = LinkStatus.public;
  int? _selectedCategoryId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _canAuth = false;

  Future<void> _init() async {
    final canAuth = await LocalAuthService.canAuthenticate();
    if (!mounted) return;
    setState(() {
      _canAuth = canAuth;
    });
  }

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
    _init();
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

      if (widget.isEditing && !widget.isShared) {
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ───────────────────────────────────────
              Text(
                'Agregar Link',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 18),

              // ── Link title field ────────────────────────────
              Text('Título', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Tutorial práctico',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Description field ───────────────────────────
              Text(
                'Descripción (opcional)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '¿De qué trata este enlace?',
                ),
              ),

              const SizedBox(height: 16),

              // ── URL field ───────────────────────────────────
              Text('URL', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://',
                  prefixIcon: Icon(Icons.link, color: cs.tertiary, size: 21),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Se requiere una url';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Category selector ───────────────────────────
              Text('Categoría', style: Theme.of(context).textTheme.labelSmall),
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
              
                Text(
                  'Visibilidad',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                VisibilitySwitch(
                  status: status,
                  onChanged: (v) => setState(() => status = v),
                ),

                const SizedBox(height: 20),
              // ── Save button ─────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    handlerSubmit();
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  widget.isEditing ? 'Guardar Cambios' : 'Agregar Link',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Visibility switch ────────────────────────────────────────
