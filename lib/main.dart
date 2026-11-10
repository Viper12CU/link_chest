import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/providers/onboarding_provider.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/utils/theme.dart';
import 'package:link_chest/widgets/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await DatabaseHelper().init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CategorySelectedProvider()..init(),
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => LinkProvider()),
        ChangeNotifierProvider(create: (_) => VersionProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: FeatureDiscovery(child: const App()),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

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
    );
  }
}
