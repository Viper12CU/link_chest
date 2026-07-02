import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/utils/shared/link_menu_handlers.dart';
import 'package:link_chest/widgets/atoms/connfirm_dialog.dart';
import 'package:link_chest/widgets/organisms/link_card.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastify_flutter/toastify_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoryTemplate extends StatefulWidget {
  final int? categoryId;
  const CategoryTemplate({super.key, this.categoryId});

  @override
  State<CategoryTemplate> createState() => _CategoryTemplateState();
}

class _CategoryTemplateState extends State<CategoryTemplate> {
  @override
  Widget build(BuildContext context) {
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final List<LinkModel> links = linkProvider.byCategory(widget.categoryId!);

    final LinkMenuHandlers menuHandlers = LinkMenuHandlers(context: context);

    // void handleCopy(String link) {
    //   Clipboard.setData(ClipboardData(text: link));
    //   ToastifyFlutter.success(
    //     context,
    //     message: 'Link copiado al portapapeles',
    //     duration: 3,
    //     style: ToastStyle.flat,
    //   );
    // }

    // void handleShare(LinkModel link) async {
    //   final params = ShareParams(
    //     uri: Uri.parse(link.url),
    //     subject: link.description,
    //   );
    //   final result = await SharePlus.instance.share(params);
    //   debugPrint('Resultado de compartir: $result');
    // }

    // void handleLock(LinkModel link) async {
    //   await linkProvider.toggleStatus(link);
    // }

    // void handleDelete(int? linkId) async {
    //   await linkProvider.delete(linkId);
    // }

    // void handleMoveTo(int? link, int? newCategory) async {
    //   await linkProvider.changeCategory(link, newCategory);
    // }

    

    // void handleOpen(String url) async {
    //   ConfirmDialog.show(
    //     context: context,
    //     title: '¿Abrir link?',
    //     description: 'Se abrirá el link en el navegador externo',
    //     actions: [
    //       ConfirmAction(
    //         label: 'Abrir',
    //         style: ConfirmActionStyle.primary,
    //         onTap: () async {
    //           final uri = Uri.parse(url);
    //           if (await canLaunchUrl(uri)) {
    //             await launchUrl(uri, mode: LaunchMode.externalApplication);
    //           } else {
    //             if (context.mounted) {
    //               ToastifyFlutter.error(
    //                 context,
    //                 message: 'No se pudo abrir el link',
    //                 duration: 3,
    //                 style: ToastStyle.flat,
    //               );
    //             }
    //           }
    //         },
    //       ),
    //     ],
    //   );
    // }

    if (links.isEmpty) {
      return const _EmptyState();
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: links.length,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final item = links.removeAt(oldIndex);
          links.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final LinkModel link = links[index];

        return LinkCard(
          key: ValueKey(link.url),
          title: link.title,
          description: link.description,
          url: link.url,
          categoryId: widget.categoryId,
          isLocked: link.status.value == "private",
          onOpen: () => menuHandlers.handleOpen(link.url),
          onCopy: () => menuHandlers.handleCopy(link.url),
          onShare: () => menuHandlers.handleShare(link),
          onLock: () => menuHandlers.handleLock(link),
          onDelete: () => menuHandlers.handleDelete(link.id),
          onMoveTo: (category) => menuHandlers.handleMoveTo(link.id, category),
        );
      },
    );
  }
}

// ── Empty state ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 14),
          Text(
            'Sin links todavía',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Toca + para agregar tu primer link',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Static data ─────────────────────────────────────────────
