import 'package:flutter/material.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';


 void _logSharedFlow(String message) {
    debugPrint('📱 [receive_sharing_intent] $message');
  }

void handleShared(List<SharedMediaFile> files, BuildContext context, GlobalKey<NavigatorState> navigatorKey) async {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.loadAll();
    }

    _logSharedFlow('Procesando ${files.length} archivo(s) compartido(s)');

    if (files.isEmpty) return;

    final text = files
        .where((f) => f.type == SharedMediaType.text)
        .map((f) => f.path)
        .join();

    _logSharedFlow(
      'Contenido de texto detectado: ${text.isEmpty ? "vacío" : text}',
    );

    if (text.isEmpty) return;

    final urlMatch = RegExp(r'https?://\S+').firstMatch(text);
    final url = urlMatch?.group(0) ?? text;

    _logSharedFlow('URL resuelta: $url');

    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      _logSharedFlow(
        'navigatorKey.currentContext es null; no se puede abrir AddLinkSheet',
      );
      return;
    }

    final defaultCategory = categoryProvider.categories.firstWhere(
      (c) => c.id == DatabaseHelper.defaultCategoryId,
      orElse: () => categoryProvider.categories.first,
    );

    final linkToAdd = LinkModel(
      id: null,
      title: '',
      url: url,
      categoryId: defaultCategory.id!,
    );

    _logSharedFlow(
      'Abriendo AddLinkSheet para la categoría ${defaultCategory.id}',
    );


    if (context.mounted) {
      AddLinkSheet.show(ctx, defaultCategory, linkToEdit: linkToAdd, isEditing: true, isShared: true);
    }
  }
