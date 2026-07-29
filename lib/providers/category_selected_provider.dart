import 'package:flutter/material.dart';
import 'package:link_chest/database/database_helper.dart' show DatabaseHelper;
import 'package:shared_preferences/shared_preferences.dart';

class CategorySelectedProvider extends ChangeNotifier {
  int _selectedIndex = DatabaseHelper.defaultCategoryId;

  int get selectedIndex => _selectedIndex;

  Future<void> init() async {
    debugPrint("Iniciando provider");
    await SharedPreferences.getInstance().then((prefs) {
      _selectedIndex = prefs.getInt('selectedCategory') ?? DatabaseHelper.defaultCategoryId;
      notifyListeners();
    });
  }

  void select(int index) async {
  final prefs = await SharedPreferences.getInstance();

    if (_selectedIndex == index) return;

    _selectedIndex = index;
    prefs.setInt('selectedCategory', index);
    notifyListeners();
  }
}
