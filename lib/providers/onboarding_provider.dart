// providers/onboarding_provider.dart
import 'package:flutter/material.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const _prefsKey = 'onboarding_home_done';
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _homeOnboardingCompleted = false;
  bool get homeOnboardingCompleted => _homeOnboardingCompleted;

  // IDs centralizados: evita strings mágicos repartidos en la UI
  static const stepAddLink = 'step_add_link';
  static const stepAddCategory = 'step_add_category';
  static const stepVault = 'step_vault';

  static const homeSteps = [stepAddLink, stepAddCategory, stepVault];

  Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _homeOnboardingCompleted = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
  }

  Future<void> startHomeTourIfNeeded(BuildContext context) async {
    if (_homeOnboardingCompleted) return;

    // Espera a que el árbol termine de construirse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(context, homeSteps);
    });
  }

  Future<void> markHomeTourCompleted() async {
    _homeOnboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    notifyListeners();
  }
}