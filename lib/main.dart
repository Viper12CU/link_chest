import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/services/shared_with_me.dart';
import 'package:link_chest/utils/theme.dart';
import 'package:link_chest/widgets/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CategorySelectedProvider()..init(),
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => LinkProvider()),
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
    debugPrint('📱 [receive_sharing_intent] $message');
  }

  @override
  void initState() {
    super.initState();

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
   

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Link Chest',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: SplashPage(),
      color: const Color.fromARGB(255, 245, 73, 73),
    );
  }
}
