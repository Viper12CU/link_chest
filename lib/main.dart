import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/utils/theme.dart';
import 'package:link_chest/widgets/organisms/add_link_sheet.dart';
import 'package:link_chest/widgets/pages/category_page.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategorySelectedProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => LinkProvider()..loadAll()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late StreamSubscription _intentSub;

  void _logSharedFlow(String message) {
    debugPrint('[receive_sharing_intent] $message');
  }

  

  @override
  void initState() {
    super.initState();


    _logSharedFlow('Inicializando listeners de compartido');

    // App abierta en background y llega un share
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        _logSharedFlow('getMediaStream recibió ${value.length} archivo(s)');
        _handleShared(value);
      },
      onError: (err) {
        _logSharedFlow('getMediaStream error: $err');
      },
    );

    // App cerrada (cold start), se abre desde el share sheet
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _logSharedFlow('getInitialMedia recibió ${value.length} archivo(s)');
      _handleShared(value);
      ReceiveSharingIntent.instance.reset();
      _logSharedFlow('reset ejecutado tras getInitialMedia');
    }).catchError((err) {
      _logSharedFlow('getInitialMedia error: $err');
    });
  }

  void _handleShared(List<SharedMediaFile> files) {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );

    _logSharedFlow('Procesando ${files.length} archivo(s) compartido(s)');

    if (files.isEmpty) return;

    final text = files
        .where((f) => f.type == SharedMediaType.text)
        .map((f) => f.path)
        .join();

    _logSharedFlow('Contenido de texto detectado: ${text.isEmpty ? "vacío" : text}');

    if (text.isEmpty) return;

    final urlMatch = RegExp(r'https?://\S+').firstMatch(text);
    final url = urlMatch?.group(0) ?? text;

    _logSharedFlow('URL resuelta: $url');

    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      _logSharedFlow('navigatorKey.currentContext es null; no se puede abrir AddLinkSheet');
      return;
    }

    final LinkModel linkToAdd = LinkModel(
      id: null,
      title: "",
      url: url,
      categoryId: categoryProvider.categories.first.id!,
    );

    _logSharedFlow('Abriendo AddLinkSheet para la categoría ${categoryProvider.categories.first.id}');

    AddLinkSheet.show(
      ctx,
      categoryProvider.categories.first,
      linkToEdit: linkToAdd,
    );
  }

  @override
  void dispose() {
    _logSharedFlow('Cancelando listener de compartido');
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );
    final CategoryModel initialCategory = categoryProvider.categories.first;
    

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Link Chest',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: CategoryPage(category: initialCategory),
    );
  }
}

