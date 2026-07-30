import 'dart:async';
import 'package:link_chest/main.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/services/shared_with_me.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/atoms/custom_appbar.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:link_chest/widgets/organisms/category_drawer.dart';
import 'package:link_chest/widgets/templates/category_template.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class CategoryPage extends StatefulWidget {
  final CategoryModel category;
  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late StreamSubscription _intentSub;

  final SystemUiOverlayStyle _drawerOpen = SystemUiOverlayStyle(
    statusBarColor: Color(0xFF253745),
    statusBarIconBrightness: Brightness.light,
  );

  final SystemUiOverlayStyle _initial = SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 227, 228, 228),
    statusBarIconBrightness: Brightness.dark,
  );

  void _logSharedFlow(String message) {
    debugPrint('📱 [receive_sharing_intent] $message');
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(_initial);
    try {
      _logSharedFlow('Inicializando listeners de compartido');

      // App abierta en background y llega un share
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (value) {
          _logSharedFlow('getMediaStream recibió ${value.length} archivo(s)');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            handleShared(value, context, navigatorKey);
          });
        },
        onError: (err) {
          _logSharedFlow('getMediaStream error: $err');
        },
      );

      // App cerrada (cold start), se abre desde el share sheet
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((value) {
            _logSharedFlow(
              'getInitialMedia recibió ${value.length} archivo(s)',
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              handleShared(value, context, navigatorKey);
            });
            ReceiveSharingIntent.instance.reset();
            _logSharedFlow('reset ejecutado tras getInitialMedia');
          })
          .catchError((err) {
            _logSharedFlow('getInitialMedia error: $err');
          });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void dispose() {
    _logSharedFlow('Cancelando listener de compartido');
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = ColorParse().toColor(widget.category.color);
    final VersionProvider versionProvider = Provider.of<VersionProvider>(
      context,
    );

    return Scaffold(
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          SystemChrome.setSystemUIOverlayStyle(_drawerOpen);
        } else {
          SystemChrome.setSystemUIOverlayStyle(_initial);
          if (!versionProvider.isNotified) {
            versionProvider.markAsNotified();
          }
        }
      },
      drawer: CategoryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppbar(category: widget.category),
            Expanded(child: CategoryTemplate(category: widget.category)),
          ],
        ),
      ),
      floatingActionButton: addButton(context, categoryColor),
    );
  }

  FloatingActionButton addButton(BuildContext context, Color categoryColor) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Color getContrastColor(Color background) {
      final brightness = ThemeData.estimateBrightnessForColor(background);
      return brightness == Brightness.dark ? cs.onPrimary : cs.onSurface;
    }

    return FloatingActionButton.extended(
      elevation: 4.0,
      backgroundColor: categoryColor,
      onPressed: () {
        AddLinkSheet.show(context, widget.category);
      },
      tooltip: "Nuevo link",
      label: Text(
        "Nuevo link",
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: getContrastColor(categoryColor),
        ),
      ),
      icon: Icon(Icons.add, size: 30.0, color: getContrastColor(categoryColor)),
    );
  }
}
