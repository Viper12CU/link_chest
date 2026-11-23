import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_chest/core/config/app_config.dart';
import 'package:link_chest/core/storage/secure_local_storage.dart';
import 'package:link_chest/database/database.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/category_selected_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/providers/onboarding_provider.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/utils/theme.dart';
import 'package:link_chest/widgets/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Config: `--dart-define` (flutenv / CI) con fallback al `.env` local.
  AppConfig.loadDotEnv();
  AppConfig.assertConfigured();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      // No usamos redirect por navegador: el login de Google es nativo y la
      // verificación de email se resuelve dentro de la app.
      detectSessionInUri: false,
      autoRefreshToken: true,
      persistSession: true,
      // La sesión (refresh token) no debe vivir en texto plano.
      localStorage: SecureLocalStorage(
        persistSessionKey:
            'sb-${Uri.parse(AppConfig.supabaseUrl).host.split('.').first}'
            '-auth-token',
      ),
    ),
  );

  await DatabaseHelper().init();
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
        ChangeNotifierProvider.value(value: SyncService.instance),
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
