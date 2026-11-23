import 'package:flutter/foundation.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import '../database/database.dart';

class LinkProvider extends ChangeNotifier {
  final LinkRepository _repo = SqliteLinkRepository.withHelper(
    DatabaseHelper(),
  );

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

  List<LinkModel> byCategory(String categoryId) => _links
      .where((l) => l.categoryId == categoryId && l.status == LinkStatus.public)
      .toList();

  String _requireUserId() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('No hay sesión activa para guardar datos.');
    }
    return userId;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _links = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(LinkModel link) async {
    _error = null;
    try {
      final userId = _requireUserId();
      _repo.create(link.copyWith(userId: userId));
      await SyncService.instance.requestSync();
      await loadAll();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(LinkModel link) async {
    _error = null;
    try {
      _repo.update(link);
      await SyncService.instance.requestSync();
      final index = _links.indexWhere((l) => l.id == link.id);
      if (index != -1) {
        _links[index] = link.copyWith(isPendingSync: true);
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

  Future<void> delete(String? linkId) async {
    if (linkId == null) return;
    try {
      _repo.delete(linkId);
      await SyncService.instance.requestSync();
      _links.removeWhere((l) => l.id == linkId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteVault() async {
    try {
      _repo.deletePrivateLinks();
      await SyncService.instance.requestSync();
      _links.removeWhere((l) => l.status == LinkStatus.private);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresca la lista tras un borrado/reasignación de categoría.
  Future<void> reloadAfterCategoryChange() => loadAll();

  /// Cambiar de categoría un link
  Future<void> changeCategory(String? linkId, String? newCategoryId) async {
    if (linkId == null || newCategoryId == null) return;
    final index = _links.indexWhere((l) => l.id == linkId);
    if (index == -1) return;

    final updated = _links[index].copyWith(categoryId: newCategoryId);
    await update(updated);
  }
}
