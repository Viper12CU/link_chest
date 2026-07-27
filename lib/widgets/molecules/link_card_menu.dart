import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/services/local_auth.dart';
import 'package:provider/provider.dart';

enum MenuAction { copy, share, lock, move, delete, edit }

class CardMenu extends StatelessWidget {
  final bool isLocked;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onLock;
  final VoidCallback? onDelete;
  final ValueChanged<int?>? onMoveTo;
  final VoidCallback? onEdit;

  const CardMenu({
    super.key,
    required this.isLocked,
    this.onCopy,
    this.onShare,
    this.onLock,
    this.onDelete,
    this.onMoveTo,
    this.onEdit,
  });


  Future<bool> canAuth() async {
      final bool canAuth = await LocalAuthService.canAuthenticate();
      return canAuth;
    }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<MenuAction>(
      onSelected: (action) => _handleAction(context, action),
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      itemBuilder: (context) => [
        _buildItem(
          context: context,
          icon: Icons.copy_rounded,
          label: 'Copiar link',
          action: MenuAction.copy,
        ),
        _buildItem(
          context: context,
          icon: Icons.share_rounded,
          label: 'Compartir link',
          action: MenuAction.share,
        ),
        // ── Mover a categoría (nested submenu) ──────────
        PopupMenuItem<MenuAction>(
          value: MenuAction.move,
          child: Row(
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mover a categoría',
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),

        // ── Bloquear / Desbloquear ──────────────────────
        _buildItem(
          context: context,
          icon: isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
          label: isLocked ? 'Desbloquear' : 'Bloquear',
          action: MenuAction.lock,
        ),

        // ── Editar ──────────────────────
        _buildItem(
          context: context,
          icon: Icons.edit_outlined,
          label: 'Editar',
          action: MenuAction.edit,
        ),

        // ── Divider + Eliminar ──────────────────────────
        const PopupMenuDivider(height: 6),
        _buildItem(
          context: context,
          icon: Icons.delete_outline_rounded,
          label: 'Eliminar',
          action: MenuAction.delete,
          isDanger: true,
        ),
      ],
      child: IconButton(
        onPressed: null,
        icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      ),
    );
  }

  PopupMenuItem<MenuAction> _buildItem({
    required IconData icon,
    required String label,
    required MenuAction action,
    bool isDanger = false,
    required BuildContext context,
  }) {
    return PopupMenuItem<MenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDanger ? const Color(0xFFFF5A5F) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: isDanger ? Color(0xFFFF5A5F) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, MenuAction action) {
    switch (action) {
      case MenuAction.copy:
        onCopy?.call();
      case MenuAction.share:
        onShare?.call();
      case MenuAction.lock:
        onLock?.call();
      case MenuAction.delete:
        onDelete?.call();
      case MenuAction.move:
        _showMoveSubmenu(context);
      case MenuAction.edit:
        onEdit?.call();
    }
  }

  void _showMoveSubmenu(BuildContext context) {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    final List<CategoryModel> availableCategories = categoryProvider.categories;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Mover a categoría',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...availableCategories.map(
              (cat) => ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat.icon, style: TextStyle(fontSize: 18.0)),
                ),
                title: Text(cat.title),
                onTap: () {
                  Navigator.pop(context);
                  onMoveTo!.call(cat.id);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
