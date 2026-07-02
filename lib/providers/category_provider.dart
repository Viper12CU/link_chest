import 'package:flutter/foundation.dart';
import '../database/database.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryDao _dao = CategoryDao(DatabaseHelper());

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Excluye "Ninguna" para mostrar en la UI de gestión
  List<CategoryModel> get manageable => _categories
      .where((c) => c.id != DatabaseHelper.defaultCategoryId)
      .toList();

  CategoryModel? getById(int categoryId) {
    try {
      return _dao.getById(categoryId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = _dao.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(CategoryModel category) async {
    try {
      final id = _dao.insert(category);
      _categories.add(category.copyWith(id: id));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(CategoryModel category) async {
    try {
      _dao.update(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }


  Future<void> updateDefault(CategoryModel category) async {
  try {
    _dao.updateDefault(category.copyWith(id: DatabaseHelper.defaultCategoryId));
    final index = _categories.indexWhere((c) => c.id == DatabaseHelper.defaultCategoryId);
    if (index != -1) {
      _categories[index] = category.copyWith(id: DatabaseHelper.defaultCategoryId);
      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}

  /// Elimina la categoría y mueve sus links a "Ninguna"
  Future<void> deleteAndReassign(int categoryId) async {
    try {
      _dao.deleteAndReassignLinks(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina la categoría junto con todos sus links
  Future<void> deleteWithLinks(int categoryId) async {
    try {
      _dao.deleteWithAllLinks(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
