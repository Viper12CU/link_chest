import 'package:link_chest/database/dao/category_dao.dart';
import 'package:link_chest/database/dao/link_dao.dart';
import 'package:link_chest/database/database_helper.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';
import 'package:link_chest/database/repositories/repositories.dart';

class SqliteCategoryRepository implements CategoryRepository {
  SqliteCategoryRepository(this._dao);

  final CategoryDao _dao;

  factory SqliteCategoryRepository.withHelper(DatabaseHelper helper) =>
      SqliteCategoryRepository(CategoryDao(helper));

  @override
  List<CategoryModel> getAll() => _dao.getAll();

  @override
  CategoryModel? getById(String id) => _dao.getById(id);

  @override
  CategoryModel? getByIdIncludingDeleted(String id) =>
      _dao.getByIdIncludingDeleted(id);

  @override
  CategoryModel? getDefault() => _dao.getDefault();

  @override
  String? getDefaultCategoryId() => _dao.getDefaultCategoryId();

  @override
  String create(CategoryModel category) => _dao.insert(category);

  @override
  void update(CategoryModel category) => _dao.update(category);

  @override
  void deleteAndReassign(String categoryId) =>
      _dao.deleteAndReassignLinks(categoryId);

  @override
  void deleteWithLinks(String categoryId) => _dao.deleteWithAllLinks(categoryId);

  @override
  List<CategoryModel> getDirty({int limit = 100}) =>
      _dao.getDirty(limit: limit);

  @override
  void updateFromServer(CategoryModel category) =>
      _dao.updateFromServer(category);

  @override
  void markSynced(String id, int expectedVersion) =>
      _dao.markSynced(id, expectedVersion);

  @override
  void setSyncError(String id, String error) => _dao.setSyncError(id, error);
}

class SqliteLinkRepository implements LinkRepository {
  SqliteLinkRepository(this._dao);

  final LinkDao _dao;

  factory SqliteLinkRepository.withHelper(DatabaseHelper helper) =>
      SqliteLinkRepository(LinkDao(helper));

  @override
  List<LinkModel> getAll() => _dao.getAll();

  @override
  LinkModel? getById(String id) => _dao.getById(id);

  @override
  LinkModel? getByIdIncludingDeleted(String id) =>
      _dao.getByIdIncludingDeleted(id);

  @override
  List<LinkModel> getByCategory(String categoryId) =>
      _dao.getByCategory(categoryId);

  @override
  List<LinkModel> getByStatus(LinkStatus status) => _dao.getByStatus(status);

  /// Búsqueda en memoria con `contains` (case-insensitive).
  /// No hay `LIKE` en SQLite hoy; se conserva el mismo comportamiento de
  /// filtrado en la capa de repositorio.
  @override
  List<LinkModel> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return getAll().where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.url.toLowerCase().contains(q) ||
          (l.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  String create(LinkModel link) => _dao.insert(link);

  @override
  void update(LinkModel link) => _dao.update(link);

  @override
  void delete(String linkId) => _dao.delete(linkId);

  @override
  void move(String linkId, String newCategoryId) {
    final link = _dao.getById(linkId);
    if (link == null) return;
    _dao.update(link.copyWith(categoryId: newCategoryId));
  }

  @override
  void deletePrivateLinks() => _dao.deletePrivateLinks();

  @override
  List<LinkModel> getDirty({int limit = 100, bool publicOnly = false}) =>
      _dao.getDirty(limit: limit, publicOnly: publicOnly);

  @override
  void updateFromServer(LinkModel link) => _dao.updateFromServer(link);

  @override
  void markSynced(String id, int expectedVersion) =>
      _dao.markSynced(id, expectedVersion);

  @override
  void setSyncError(String id, String error) => _dao.setSyncError(id, error);
}
