import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/widgets/atoms/confirm_dialog.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastify_flutter/toastify_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkMenuHandlers {
  LinkMenuHandlers({required this.context})
    : linkProvider = Provider.of<LinkProvider>(context, listen: false);

  final BuildContext context;
  final LinkProvider linkProvider;

  void handleCopy(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ToastifyFlutter.success(
      context,
      message: 'Link copiado al portapapeles',
      duration: 3,
      style: ToastStyle.flat,
    );
  }

  void handleShare(LinkModel link) async {
    final params = ShareParams(
      uri: Uri.parse(link.url),
      subject: link.description,
    );
    final result = await SharePlus.instance.share(params);
    debugPrint('Resultado de compartir: $result');
  }

  void handleLock(LinkModel link) async {
    await linkProvider.toggleStatus(link);
  }

  void handleDelete(int? linkId) async {
    ConfirmDialog.show(
      context: context,
      title: '¿Eliminar link?',
      description: 'Esta acción no se puede deshacer.',
      actions: [
        ConfirmAction(
          label: 'Eliminar',
          style: ConfirmActionStyle.destructive,
          onTap: () async => await linkProvider.delete(linkId),
        ),
      ],
    );
  }

  void handleMoveTo(int? link, int? newCategory) async {
    await linkProvider.changeCategory(link, newCategory);
  }

  void handleEdit(LinkModel linkToEdit, CategoryModel initialCategory) {
    AddLinkSheet.show(context, initialCategory, linkToEdit: linkToEdit, isEditing: true);

  }

  void handleOpen(String url) async {
    ConfirmDialog.show(
      context: context,
      title: '¿Abrir link?',
      description: 'Se abrirá el link en el navegador externo',
      actions: [
        ConfirmAction(
          label: 'Abrir',
          style: ConfirmActionStyle.primary,
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ToastifyFlutter.error(
                  context,
                  message: 'No se pudo abrir el link',
                  duration: 3,
                  style: ToastStyle.simple,
                );
              }
            }
          },
        ),
      ],
    );
  }
}
