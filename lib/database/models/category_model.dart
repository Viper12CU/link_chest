class CategoryModel {
  final String? id;
  final String userId;
  final String title;
  final String icon;
  final String color;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool isPendingSync;
  final int version;
  final String? syncError;

  /// Fallo definitivo de sincronización (`sync_error` no nulo).
  bool get hasSyncError => syncError != null;

  const CategoryModel({
    this.id,
    required this.userId,
    required this.title,
    required this.icon,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isPendingSync = false,
    this.version = 0,
    this.syncError,
  });

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? icon,
    String? color,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    bool? clearDeletedAt = false,
    bool? isPendingSync,
    int? version,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
          clearDeletedAt == true ? null : (deletedAt ?? this.deletedAt),
      isPendingSync: isPendingSync ?? this.isPendingSync,
      version: version ?? this.version,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'icon': icon,
        'color': color,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'dirty': isPendingSync ? 1 : 0,
        'version': version,
        'sync_error': syncError,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        deletedAt: map['deleted_at'] as String?,
        isPendingSync: (map['dirty'] as int? ?? 0) == 1,
        version: map['version'] as int? ?? 0,
        syncError: map['sync_error'] as String?,
      );

  @override
  String toString() =>
      'CategoryModel(id: $id, title: $title, isDefault: $isDefault, '
      'isPendingSync: $isPendingSync)';
}
