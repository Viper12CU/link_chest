import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/database/models/link_model.dart';

/// Contrato de lectura/escritura de categorías. La UI y el motor de sync
/// dependen de esta interfaz, no del DAO ni de SQLite.
abstract class CategoryRepository {
  List<CategoryModel> getAll();
  CategoryModel? getById(String id);

  /// Incluye borradas lógicamente; `isPendingSync` indica dirty local.
  CategoryModel? getByIdIncludingDeleted(String id);

  CategoryModel? getDefault();
  String? getDefaultCategoryId();

  /// Crea una categoría (UUID generado) y la marca pendiente de sincronizar.
  String create(CategoryModel category);

  void update(CategoryModel category);

  /// Borra lógicamente y reasigna sus links a la categoría por defecto.
  void deleteAndReassign(String categoryId);

  /// Borra lógicamente la categoría y todos sus links.
  void deleteWithLinks(String categoryId);

  /// Pendientes sin sync_error (para el motor de subida).
  List<CategoryModel> getDirty({int limit});

  /// Upsert desde servidor (dirty=0). Única vía que puede tocar la default.
  void updateFromServer(CategoryModel category);

  void markSynced(String id, int expectedVersion);
  void setSyncError(String id, String error);
}

/// Contrato de lectura/escritura de links.
abstract class LinkRepository {
  List<LinkModel> getAll();
  LinkModel? getById(String id);
  List<LinkModel> getByCategory(String categoryId);
  List<LinkModel> getByStatus(LinkStatus status);
  List<LinkModel> search(String query);

  /// Incluye borradas lógicamente; `isPendingSync` indica dirty local.
  LinkModel? getByIdIncludingDeleted(String id);

  /// Crea un link. Lanza [DefaultCategoryNotReadyException] si aún no
  /// existe la categoría por defecto local.
  String create(LinkModel link);

  void update(LinkModel link);
  void delete(String linkId);
  void move(String linkId, String newCategoryId);
  void deletePrivateLinks();

  /// Pendientes sin sync_error; `publicOnly` omite bóveda privada.
  List<LinkModel> getDirty({int limit, bool publicOnly});

  void updateFromServer(LinkModel link);

  void markSynced(String id, int expectedVersion);
  void setSyncError(String id, String error);
}
