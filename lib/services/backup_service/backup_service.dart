// lib/services/backup_service.dart
//
// Exportación e importación de links y categorías de Link Chest en un único
// archivo JSON con esquema versionado.
//
// Formato (schemaVersion 1), reflejando las tablas reales de SQLite:
// {
//   "format": "link_chest_backup",
//   "schemaVersion": 1,
//   "exportedAt": "2026-11-05T12:00:00.000Z",
//   "categories": [
//     { "id": "1", "title": "Sin categoría", "icon": "📂",
//       "color": "<valor tal cual lo guarda ColorParse>", "isDefault": true }
//   ],
//   "links": [
//     { "id": "7", "categoryId": "1", "title": "...", "url": "https://...",
//       "description": "..." | null, "status": "public" | "private" }
//   ]
// }
//
// Reglas de coherencia:
// - Los "id" del archivo solo sirven para relacionar links con categorías
//   dentro del mismo archivo. NO son identidad entre dispositivos (en SQLite
//   son autoincrementales y cambian de un teléfono a otro).
// - Identidad al importar: categoría = título (sin mayúsculas ni espacios
//   extremos); link = URL normalizada + categoría destino. Así importar dos
//   veces el mismo archivo no duplica nada.
// - La categoría por defecto ("isDefault") se enlaza siempre con la local.
// - Un link con categoría desconocida va a la categoría por defecto (aviso).
// - Se valida todo antes de escribir; las escrituras van en una transacción.
//
// Dependencia: file_picker ^13 (pubspec.yaml -> file_picker: ^13.0.0).

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

const String kBackupFormat = 'link_chest_backup';
const int kBackupSchemaVersion = 1;

// ---------------------------------------------------------------------------
// Errores y resultados
// ---------------------------------------------------------------------------

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum ImportMode {
  /// Añade lo que no exista. No modifica ni borra nada local.
  merge,

  /// Borra todos los links y las categorías (salvo la de por defecto) y deja
  /// el contenido del archivo. Si el archivo se exportó sin links privados,
  /// los privados locales se pierden.
  replace,
}

class ImportResult {
  ImportResult({
    required this.categoriesAdded,
    required this.categoriesMatched,
    required this.linksAdded,
    required this.linksSkipped,
    required this.warnings,
  });

  /// Categorías nuevas creadas.
  final int categoriesAdded;

  /// Categorías del archivo que ya existían (mismo título) y se reutilizaron.
  final int categoriesMatched;

  final int linksAdded;

  /// Links que ya existían (misma URL en la misma categoría).
  final int linksSkipped;
  final List<String> warnings;

  @override
  String toString() =>
      'Categorías: +$categoriesAdded (=$categoriesMatched ya existían) | '
      'Links: +$linksAdded (=$linksSkipped ya existían) | '
      'Avisos: ${warnings.length}';
}

// ---------------------------------------------------------------------------
// Modelos del respaldo (independientes de SQLite/Firestore)
// ---------------------------------------------------------------------------

class BackupCategory {
  BackupCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  final String id;
  final String title;

  /// Emoji u otro texto corto (columna icon).
  final String icon;

  /// Valor opaco: se guarda y restaura tal cual lo produce ColorParse.
  final String color;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'color': color,
        'isDefault': isDefault,
      };

  factory BackupCategory.fromJson(Map<String, dynamic> j) => BackupCategory(
        id: _reqId(j),
        title: _reqString(j, 'title'),
        icon: _optString(j, 'icon') ?? '📂',
        color: _reqString(j, 'color'),
        isDefault: _optBool(j, 'isDefault'),
      );
}

class BackupLink {
  BackupLink({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.url,
    this.description,
    this.isPrivate = false,
  });

  final String id;
  final String categoryId;
  final String title;
  final String url;
  final String? description;

  /// true si status == 'private' (bóveda con PIN).
  final bool isPrivate;

  BackupLink withCategory(String newCategoryId) => BackupLink(
        id: id,
        categoryId: newCategoryId,
        title: title,
        url: url,
        description: description,
        isPrivate: isPrivate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'title': title,
        'url': url,
        'description': description,
        'status': isPrivate ? 'private' : 'public',
      };

  /// [fallbackCategoryId] se usa si el link no trae categoryId.
  factory BackupLink.fromJson(
    Map<String, dynamic> j, {
    required String fallbackCategoryId,
  }) {
    final url = _reqString(j, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw FormatException('URL inválida: "$url"');
    }

    // Un valor de estado desconocido NO se interpreta como público: podría
    // exponer un link privado.
    final status = _optString(j, 'status') ?? 'public';
    if (status != 'public' && status != 'private') {
      throw FormatException('status inválido: "$status"');
    }

    final rawCategory = j['categoryId'];
    return BackupLink(
      id: _reqId(j),
      categoryId: rawCategory == null ? fallbackCategoryId : rawCategory.toString(),
      title: _optString(j, 'title') ?? url,
      url: url,
      description: _optString(j, 'description'),
      isPrivate: status == 'private',
    );
  }
}

/// Documento completo del respaldo.
class BackupDocument {
  BackupDocument({
    required this.exportedAt,
    required this.categories,
    required this.links,
  });

  final DateTime exportedAt;
  final List<BackupCategory> categories;
  final List<BackupLink> links;

  Map<String, dynamic> toJson() => {
        'format': kBackupFormat,
        'schemaVersion': kBackupSchemaVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
      };

  /// Errores estructurales lanzan BackupException. Elementos individuales
  /// inválidos se omiten y se anotan en [warnings].
  factory BackupDocument.fromJson(
    Map<String, dynamic> j,
    List<String> warnings, {
    required String defaultCategoryId,
  }) {
    if (j['format'] != kBackupFormat) {
      throw BackupException('Este archivo no es un respaldo de Link Chest.');
    }
    final version = j['schemaVersion'];
    if (version is! int) {
      throw BackupException('Falta schemaVersion en el archivo.');
    }
    if (version > kBackupSchemaVersion) {
      throw BackupException(
        'El respaldo fue creado por una versión más nueva de la app '
        '(esquema $version). Actualiza Link Chest para importarlo.',
      );
    }

    final rawCategories = j['categories'];
    final rawLinks = j['links'];
    if (rawCategories is! List || rawLinks is! List) {
      throw BackupException('Estructura inválida: faltan categories o links.');
    }

    // Si en el futuro cambia el esquema, aquí se migra desde `version`.

    final categories = <String, BackupCategory>{};
    for (var i = 0; i < rawCategories.length; i++) {
      try {
        final item = rawCategories[i];
        if (item is! Map<String, dynamic>) {
          throw const FormatException('no es un objeto');
        }
        final c = BackupCategory.fromJson(item);
        if (categories.containsKey(c.id)) {
          warnings.add('Categoría con ID repetido "${c.id}": se omitió la repetida.');
        } else {
          categories[c.id] = c;
        }
      } on FormatException catch (e) {
        warnings.add('Categoría #${i + 1} omitida: ${e.message}');
      }
    }

    final links = <String, BackupLink>{};
    for (var i = 0; i < rawLinks.length; i++) {
      try {
        final item = rawLinks[i];
        if (item is! Map<String, dynamic>) {
          throw const FormatException('no es un objeto');
        }
        final l = BackupLink.fromJson(item, fallbackCategoryId: defaultCategoryId);
        if (links.containsKey(l.id)) {
          warnings.add('Link con ID repetido "${l.id}": se omitió el repetido.');
        } else {
          links[l.id] = l;
        }
      } on FormatException catch (e) {
        warnings.add('Link #${i + 1} omitido: ${e.message}');
      }
    }

    return BackupDocument(
      exportedAt: _optDate(j, 'exportedAt') ?? DateTime.now().toUtc(),
      categories: categories.values.toList(),
      links: links.values.toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Contrato con el almacenamiento (SQLite hoy, Firestore después)
// ---------------------------------------------------------------------------

abstract class BackupStore {
  /// ID (como string) de la categoría "Sin categoría" local.
  String get defaultCategoryId;

  Future<List<BackupCategory>> readCategories();
  Future<List<BackupLink>> readLinks();

  /// Crea una categoría y devuelve el ID que le asignó el almacenamiento.
  /// El campo `id` del argumento se ignora (es el ID del archivo).
  Future<String> insertCategory(BackupCategory category);

  /// Inserta links nuevos. El `id` de cada uno se ignora; `categoryId` ya es
  /// el ID local.
  Future<void> insertLinks(List<BackupLink> links);

  /// Borra todos los links y todas las categorías excepto la de por defecto.
  Future<void> clearAll();

  /// Ejecuta [action] de forma atómica si el almacenamiento lo permite.
  Future<T> transaction<T>(Future<T> Function() action) => action();
}

// ---------------------------------------------------------------------------
// Servicio
// ---------------------------------------------------------------------------

class BackupService {
  BackupService(this._store);

  final BackupStore _store;

  // ----- Exportar -----

  /// [includePrivate] false por defecto: el JSON no está cifrado y los links de
  /// la bóveda quedarían en texto plano.
  Future<BackupDocument> buildDocument({bool includePrivate = false}) async {
    final categories = await _store.readCategories();
    var links = await _store.readLinks();
    if (!includePrivate) {
      links = links.where((l) => !l.isPrivate).toList();
    }

    // Integridad: todo link apunta a una categoría presente en el archivo.
    final categoryIds = categories.map((c) => c.id).toSet();
    links = links
        .map((l) => categoryIds.contains(l.categoryId)
            ? l
            : l.withCategory(_store.defaultCategoryId))
        .toList();

    // Orden estable: la categoría por defecto primero, luego por título.
    categories.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return BackupDocument(
      exportedAt: DateTime.now().toUtc(),
      categories: categories,
      links: links,
    );
  }

  Future<String> exportToJson({
    bool includePrivate = false,
    bool pretty = true,
  }) async {
    final doc = await buildDocument(includePrivate: includePrivate);
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(doc.toJson());
  }

  /// Respaldo serializado como bytes UTF-8 (lo que necesita saveFile en móvil).
  Future<Uint8List> exportToBytes({bool includePrivate = false}) async {
    final json = await exportToJson(includePrivate: includePrivate);
    return Uint8List.fromList(utf8.encode(json));
  }

  /// Abre el diálogo "guardar como" del sistema para que el usuario elija
  /// carpeta y nombre. Devuelve la ruta/URI donde se guardó, o null si el
  /// usuario canceló.
  Future<String?> exportWithPicker({bool includePrivate = false}) async {
    final bytes = await exportToBytes(includePrivate: includePrivate);

    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';

    try {
      // Según la versión, saveFile devuelve String? o Uri?; toString() cubre ambos.
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Guardar respaldo de Link Chest',
        fileName: 'link_chest_backup_$stamp.json',
        bytes: bytes,
      );
      return saved?.toString();
    } catch (e) {
      throw BackupException('No se pudo guardar el respaldo: $e');
    }
  }

  // ----- Importar -----

  /// Límite razonable: un respaldo de texto rara vez pasa de unos pocos MB.
  static const int _maxImportBytes = 20 * 1024 * 1024;

  /// Abre el selector de archivos del sistema, deja elegir un .json y lo
  /// importa. Devuelve null si el usuario canceló.
  Future<ImportResult?> importWithPicker({
    ImportMode mode = ImportMode.merge,
  }) async {
    final Uint8List bytes;
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Selecciona un respaldo de Link Chest',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return null; // Cancelado.
      bytes = await file.readAsBytes();
    } catch (e) {
      throw BackupException('No se pudo leer el archivo seleccionado: $e');
    }
    return importFromBytes(bytes, mode: mode);
  }

  Future<ImportResult> importFromBytes(
    Uint8List bytes, {
    ImportMode mode = ImportMode.merge,
  }) async {
    if (bytes.length > _maxImportBytes) {
      throw BackupException('El archivo es demasiado grande para ser un respaldo.');
    }
    final String raw;
    try {
      raw = utf8.decode(bytes);
    } on FormatException {
      throw BackupException('El archivo no es texto UTF-8 válido.');
    }
    // Quita el BOM si lo trae (algunos editores lo añaden).
    final clean = raw.startsWith('\uFEFF') ? raw.substring(1) : raw;
    return importFromJson(clean, mode: mode);
  }

  Future<ImportResult> importFromJson(
    String raw, {
    ImportMode mode = ImportMode.merge,
  }) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw BackupException('El archivo no es un JSON válido: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw BackupException('El JSON debe ser un objeto.');
    }

    // 1) Validar todo antes de tocar la base de datos.
    final warnings = <String>[];
    final doc = BackupDocument.fromJson(
      decoded,
      warnings,
      defaultCategoryId: _store.defaultCategoryId,
    );

    // 2) Aplicar dentro de una transacción.
    return _store.transaction(() => _apply(doc, mode, warnings));
  }

  Future<ImportResult> _apply(
    BackupDocument doc,
    ImportMode mode,
    List<String> warnings,
  ) async {
    if (mode == ImportMode.replace) await _store.clearAll();

    // --- Categorías: se reutilizan por título; si no existen, se crean. ---
    final titleToLocalId = <String, String>{
      for (final c in await _store.readCategories()) _titleKey(c.title): c.id,
    };
    final fileToLocalId = <String, String>{}; // id en archivo -> id local
    var categoriesAdded = 0, categoriesMatched = 0;

    for (final c in doc.categories) {
      if (c.isDefault) {
        fileToLocalId[c.id] = _store.defaultCategoryId;
        categoriesMatched++;
        continue;
      }
      final key = _titleKey(c.title);
      final existing = titleToLocalId[key];
      if (existing != null) {
        fileToLocalId[c.id] = existing;
        categoriesMatched++;
      } else {
        final newId = await _store.insertCategory(c);
        fileToLocalId[c.id] = newId;
        titleToLocalId[key] = newId;
        categoriesAdded++;
      }
    }

    // --- Links: identidad = URL normalizada + categoría local destino. ---
    final seen = <String>{
      for (final l in await _store.readLinks()) _linkKey(l.url, l.categoryId),
    };
    final toInsert = <BackupLink>[];
    var linksSkipped = 0;

    for (final l in doc.links) {
      var localCategory = fileToLocalId[l.categoryId];
      if (localCategory == null) {
        warnings.add(
          'El link "${l.title}" apuntaba a una categoría inexistente; '
          'se importó en la categoría por defecto.',
        );
        localCategory = _store.defaultCategoryId;
      }
      if (!seen.add(_linkKey(l.url, localCategory))) {
        linksSkipped++;
        continue;
      }
      toInsert.add(l.withCategory(localCategory));
    }

    await _store.insertLinks(toInsert);

    return ImportResult(
      categoriesAdded: categoriesAdded,
      categoriesMatched: categoriesMatched,
      linksAdded: toInsert.length,
      linksSkipped: linksSkipped,
      warnings: warnings,
    );
  }
}

// ---------------------------------------------------------------------------
// Claves de identidad
// ---------------------------------------------------------------------------

String _titleKey(String title) => title.trim().toLowerCase();

String _linkKey(String url, String categoryId) {
  var u = url.trim();
  final uri = Uri.tryParse(u);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    u = uri
        .replace(scheme: uri.scheme.toLowerCase(), host: uri.host.toLowerCase())
        .toString();
  }
  if (u.endsWith('/')) u = u.substring(0, u.length - 1);
  return '$categoryId|$u';
}

// ---------------------------------------------------------------------------
// Helpers de parseo tolerante
// ---------------------------------------------------------------------------

String _reqId(Map<String, dynamic> j) {
  final v = j['id'];
  if ((v is String && v.trim().isNotEmpty) || v is int) return v.toString();
  throw const FormatException('falta "id"');
}

String _reqString(Map<String, dynamic> j, String key) {
  final v = _optString(j, key);
  if (v == null) throw FormatException('falta "$key"');
  return v;
}

String? _optString(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return null;
  if (v is! String) throw FormatException('"$key" debe ser texto');
  final t = v.trim();
  return t.isEmpty ? null : t;
}

bool _optBool(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return false;
  if (v is! bool) throw FormatException('"$key" debe ser true/false');
  return v;
}

DateTime? _optDate(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return null;
  if (v is! String) throw FormatException('"$key" debe ser una fecha ISO 8601');
  final d = DateTime.tryParse(v);
  if (d == null) throw FormatException('"$key" no es una fecha válida: "$v"');
  return d.toUtc();
}
