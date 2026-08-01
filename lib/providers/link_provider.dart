import 'package:flutter/foundation.dart';
import '../database/database.dart';

class LinkProvider extends ChangeNotifier {
  final LinkDao _dao = LinkDao(DatabaseHelper());

  List<LinkModel> _links = [];
  bool _isLoading = false;
  String? _error;

  List<LinkModel> get links => _links;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<LinkModel> get publicLinks =>
      _links.where((l) => l.status == LinkStatus.public).toList();

  List<LinkModel> get privateLinks =>
      _links.where((l) => l.status == LinkStatus.private).toList();

  List<LinkModel> byCategory(int categoryId) =>
      _links.where((l) => l.categoryId == categoryId && l.status == LinkStatus.public).toList();

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _links = _dao.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(LinkModel link) async {
    try {
      final id = _dao.insert(link);
      _links.add(link.copyWith(id: id));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(LinkModel link) async {
    try {
      _dao.update(link);
      final index = _links.indexWhere((l) => l.id == link.id);
      if (index != -1) {
        _links[index] = link;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleStatus(LinkModel link) async {
    final newStatus = link.status == LinkStatus.public
        ? LinkStatus.private
        : LinkStatus.public;
    await update(link.copyWith(status: newStatus));
  }

  Future<void> delete(int? linkId) async {
    try {
      _dao.delete(linkId!);
      _links.removeWhere((l) => l.id == linkId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteVault() async {
    try {
      _dao.deletePrivateLinks();
      _links.removeWhere((l) => l.status == LinkStatus.private);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Llamar después de que CategoryProvider elimine una categoría con reasignación
  void reassignToDefault(int categoryId) {
    _links = _links.map((l) {
      if (l.categoryId == categoryId) {
        return l.copyWith(categoryId: DatabaseHelper.defaultCategoryId);
      }
      return l;
    }).toList();
    notifyListeners();
  }

  /// Llamar después de que CategoryProvider elimine categoría con todos sus links
  void removeByCategory(int categoryId) {
    _links.removeWhere((l) => l.categoryId == categoryId);
    notifyListeners();
  }

  ///Cambiar de categoria un link
  Future<void> changeCategory(int? linkId, int? newCategoryId) async {
    final index = _links.indexWhere((l) => l.id == linkId);
    if (index == -1) return;

    final updated = _links[index].copyWith(categoryId: newCategoryId);
    await update(updated);
  }
}

