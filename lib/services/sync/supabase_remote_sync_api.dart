import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_sync_api.dart';

/// Implementación de [RemoteSyncApi] sobre el cliente Supabase de la app.
class SupabaseRemoteSyncApi implements RemoteSyncApi {
  SupabaseRemoteSyncApi(this._client, {Duration? timeout})
      : _timeout = timeout ?? const Duration(seconds: 20);

  final SupabaseClient _client;
  final Duration _timeout;

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client
        .from('categories')
        .upsert(rows, onConflict: 'id')
        .timeout(_timeout);
  }

  @override
  Future<void> upsertLinks(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('links').upsert(rows, onConflict: 'id').timeout(_timeout);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String? updatedAt,
    required String? id,
    required int limit,
  }) => _fetch('categories', updatedAt: updatedAt, id: id, limit: limit);

  @override
  Future<List<Map<String, dynamic>>> fetchLinks({
    required String? updatedAt,
    required String? id,
    required int limit,
  }) => _fetch('links', updatedAt: updatedAt, id: id, limit: limit);

  Future<List<Map<String, dynamic>>> _fetch(
    String table, {
    required String? updatedAt,
    required String? id,
    required int limit,
  }) async {
    var query = _client.from(table).select();
    if (updatedAt != null && id != null) {
      query = query.or(
        'updated_at.gt.$updatedAt,and(updated_at.eq.$updatedAt,id.gt.$id)',
      );
    }
    final dynamic rows = await query
        .order('updated_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit)
        .timeout(_timeout);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
