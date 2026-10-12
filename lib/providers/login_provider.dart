import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  bool _isSession = false;

  bool get isSession => _isSession;

  Future<void> init() async {
    await SharedPreferences.getInstance().then((prefs) {
      _isSession = prefs.getBool('isSession') ?? false;
      notifyListeners();
    });
  }

  Future<void> signIn() async {
    await SharedPreferences.getInstance().then((prefs) {
      _isSession = true;
      prefs.setBool('isSession', true);
      notifyListeners();
    });

  }

  Future<void> signUp() async {
    await SharedPreferences.getInstance().then((prefs) {
      _isSession = true;
      prefs.setBool('isSession', true);
      notifyListeners();
    });

  }


  Future<void> signOut() async {
    await SharedPreferences.getInstance().then((prefs) {
      _isSession = false;
      prefs.setBool('isSession', false);
      notifyListeners();
    });

  }
  
}