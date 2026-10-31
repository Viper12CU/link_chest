import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  bool _isSession = false;

  bool get isSession => _isSession;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSession = prefs.getBool('isSession') ?? false;
    notifyListeners();
  }

  Future<void> signIn() => _setSession(true);

  Future<void> signUp() => _setSession(true);

  Future<void> signInWithGoogle() => _setSession(true);

  Future<void> signUpWithGoogle() => _setSession(true);

  Future<void> signOut() => _setSession(false);

  Future<void> _setSession(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isSession = value;
    await prefs.setBool('isSession', value);
    notifyListeners();
  }
}
