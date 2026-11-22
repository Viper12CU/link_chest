import 'package:flutter/foundation.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import '../database/database.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repo = SqliteCategoryRepository.withHelper(
    DatabaseHelper(),
  );

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Excluye la categoría por defecto para la UI de gestión.
  List<CategoryModel> get manageable =>
      _categories.where((c) => !c.isDefault).toList();

  String? get defaultCategoryId => _repo.getDefaultCategoryId();

  CategoryModel? get defaultCategory {
    for (final c in _categories) {
      if (c.isDefault) return c;
    }
    return _repo.getDefault();
  }

  String _requireUserId() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('No hay sesión activa para guardar datos.');
    }
    return userId;
  }

  CategoryModel? getById(String categoryId) {
    try {
      return _repo.getById(categoryId);
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
      _categories = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(CategoryModel category) async {
    try {
      final userId = _requireUserId();
      final id = _repo.create(category.copyWith(userId: userId));
      await SyncService.instance.requestSync();
      await loadAll();
      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx != -1) notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(CategoryModel category) async {
    try {
      _repo.update(category);
      await SyncService.instance.requestSync();
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category.copyWith(
          isPendingSync: true,
          version: category.version + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina la categoría y mueve sus links a la por defecto
  Future<void> deleteAndReassign(String categoryId) async {
    try {
      _repo.deleteAndReassign(categoryId);
      await SyncService.instance.requestSync();
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina la categoría junto con todos sus links
  Future<void> deleteWithLinks(String categoryId) async {
    try {
      _repo.deleteWithLinks(categoryId);
      await SyncService.instance.requestSync();
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
