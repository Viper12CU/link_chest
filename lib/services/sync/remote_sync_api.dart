/// Contrato de red del motor de sync. Permite probar el motor sin red.
abstract class RemoteSyncApi {
  /// Upsert masivo por `id` (no envía `updated_at`: lo fija el servidor).
  Future<void> upsertCategories(List<Map<String, dynamic>> rows);

  Future<void> upsertLinks(List<Map<String, dynamic>> rows);

  /// Página de categorías ordenada por `(updated_at, id)`.
  /// [updatedAt]/[id] son el cursor exclusivo (gt / eq+gt); null = desde el inicio.
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String? updatedAt,
    required String? id,
    required int limit,
  });

  Future<List<Map<String, dynamic>>> fetchLinks({
    required String? updatedAt,
    required String? id,
    required int limit,
  });
}
