import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategorySelectedProvider extends ChangeNotifier {
  static const _prefsKey = 'selectedCategory';

  String? _selectedId;

  /// ID de la categoría seleccionada; null = aún no hay (o no hay default).
  String? get selectedId => _selectedId;

  /// Compatibilidad con UIs que aún esperan un índice numérico no.
  String? get selectedIndex => _selectedId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // v1 guardaba int; v2 guarda String (UUID). Si es int viejo, se ignora.
    _selectedId = prefs.getString(_prefsKey);
    notifyListeners();
  }

  void select(String? categoryId) async {
    if (_selectedId == categoryId) return;

    _selectedId = categoryId;
    final prefs = await SharedPreferences.getInstance();
    if (categoryId == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, categoryId);
    }
    notifyListeners();
  }
}
