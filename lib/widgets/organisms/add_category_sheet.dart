import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:provider/provider.dart';

class AddCategorySheet extends StatefulWidget {
  final CategoryModel? categroyToEdit;
  final bool isEditing;
  const AddCategorySheet({
    super.key,
    this.categroyToEdit,
    this.isEditing = false,
  });

  static void show(
    BuildContext context, {
    CategoryModel? categroyToEdit,
    bool isEditing = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddCategorySheet(
        categroyToEdit: categroyToEdit,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedEmoji = '📁';
  Color _selectedColor = const Color(0xFFFF3B30);
  bool _pickerColor = false;

  // emoji picker
  bool _emojiShowing = false;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const List<Color> _colors = [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF007AFF),
    Color(0xFFAF52DE),
    Color(0xFFA2845E),
    Color(0xFFFF5A5F),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categroyToEdit != null && widget.isEditing) {
      setState(() {
        _titleController.text = widget.categroyToEdit!.title;
        _selectedEmoji = widget.categroyToEdit!.icon;
        _selectedColor = ColorParse().toColor(widget.categroyToEdit!.color);
        _pickerColor = !_colors.contains(
          ColorParse().toColor(widget.categroyToEdit!.color),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );

    Widget colorPickerDialog() {
      return AlertDialog(
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: EdgeInsets.zero,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            label: Text("Guardar"),
            icon: Icon(Icons.save_as_rounded),
          ),
        ],
        insetPadding: EdgeInsets.zero,
        scrollable: true,
        contentPadding: EdgeInsets.all(0),
        content: ColorPicker(
          color: _selectedColor,
          pickersEnabled: {
            ColorPickerType.both: false,
            ColorPickerType.primary: false,
            ColorPickerType.accent: false,
            ColorPickerType.bw: false,
            ColorPickerType.custom: false,
            ColorPickerType.customSecondary: false,
            ColorPickerType.wheel: true,
          },
          width: 50,
          enableShadesSelection: false,
          enableTonalPalette: true,
          enableOpacity: true,
          opacityTrackWidth: 300,
          opacityTrackHeight: 10,
          columnSpacing: 20,
          wheelDiameter: 100,
          wheelSquarePadding: 10,
          wheelWidth: 50,

          onColorChanged: (color) => setState(() {
            _pickerColor = true;
            _selectedColor = color;
          }),
        ),
      );
    }

    EmojiPicker emojiPicker(
      void Function(String emoji) handlerEmojiSelected,
      BuildContext context,
    ) {
      final Color bgColor = Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest;

      return EmojiPicker(
        textEditingController: _controller,
        scrollController: _scrollController,
        onEmojiSelected: (category, emoji) => handlerEmojiSelected(emoji.emoji),
        onBackspacePressed: () => setState(() {
          _emojiShowing = false;
        }),
        config: Config(
          locale: const Locale('es'),
          height: 256,
          checkPlatformCompatibility: true,
          viewOrderConfig: const ViewOrderConfig(),
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: bgColor,
            emojiSizeMax:
                28 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.2
                    : 1.0),
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: CategoryViewConfig(backgroundColor: bgColor),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: bgColor,
            buttonColor: Colors.transparent,
            buttonIconColor: Theme.of(context).iconTheme.color!,
          ),
          searchViewConfig: const SearchViewConfig(),
        ),
      );
    }

    void handlerEmojiSelected(String emoji) {
      setState(() {
        _selectedEmoji = emoji;
      });
    }

    void handlerSubmit() async {
      final colorStr =
          '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0')}';
      final category = CategoryModel(
        id: widget.categroyToEdit?.id,
        title: _titleController.text,
        icon: _selectedEmoji,
        color: colorStr,
      );

      if (widget.isEditing) {
        await categoryProvider.update(category);
      } else {
        await categoryProvider.add(category);
      }

      debugPrint("Error ${categoryProvider.error}");
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
            Text('New Category', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 18),

            // ── Name field ──────────────────────────────────
            Text('Title', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Reading list'),
            ),

            const SizedBox(height: 16),

            // ── Emoji picker ────────────────────────────────
            Text('Icon', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Row(
              spacing: 15.0,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _emojiShowing ? 348 : 54,
                  height: _emojiShowing ? 320 : 52,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  alignment: Alignment.center,
                  child: Column(
                    spacing: 5.0,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _emojiShowing = !_emojiShowing;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      if (_emojiShowing)
                        FutureBuilder(
                          future: Future.delayed(
                            const Duration(milliseconds: 250),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return emojiPicker(handlerEmojiSelected, context);
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                    ],
                  ),
                ),
                if (!_emojiShowing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seleciona un símbolo",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        "El emoji representará esta categoría",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 16),

            // ── Color picker ────────────────────────────────
            Text('Color', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._colors.map((entry) {
                  final isSelected = entry == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedColor = entry;
                      _pickerColor = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: entry,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: entry.withValues(alpha: 0.5),
                                  blurRadius: 0,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                    ),
                  );
                }),

                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: colorPickerDialog(),
                          ),
                        );
                      },
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: [
                          Colors.blue,
                          Colors.yellow,
                          Colors.red,
                          Colors.blue,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: _pickerColor
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: _pickerColor
                          ? [
                              BoxShadow(
                                color: _selectedColor.withValues(alpha: 0.5),
                                blurRadius: 0,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Create button ───────────────────────────────
            ElevatedButton(
              onPressed: () {
                handlerSubmit();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Text(
                widget.isEditing ? 'Guardar Cambios' : 'Crear Categoría',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
