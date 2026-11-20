enum LinkStatus {
  public('public'),
  private('private');

  final String value;
  const LinkStatus(this.value);

  static LinkStatus fromString(String value) {
    return LinkStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LinkStatus.public,
    );
  }
}

class LinkModel {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final String url;
  final String categoryId;
  final LinkStatus status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool isPendingSync;
  final int version;
  final String? syncError;

  const LinkModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.url,
    required this.categoryId,
    this.status = LinkStatus.public,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isPendingSync = false,
    this.version = 0,
    this.syncError,
  });

  LinkModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? url,
    String? categoryId,
    LinkStatus? status,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    bool? clearDeletedAt = false,
    bool? isPendingSync,
    int? version,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return LinkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
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
        'category_id': categoryId,
        'status': status.value,
        'title': title,
        'description': description,
        'url': url,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'dirty': isPendingSync ? 1 : 0,
        'version': version,
        'sync_error': syncError,
      };

  factory LinkModel.fromMap(Map<String, dynamic> map) => LinkModel(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        url: map['url'] as String,
        categoryId: map['category_id'] as String,
        status: LinkStatus.fromString(map['status'] as String),
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        deletedAt: map['deleted_at'] as String?,
        isPendingSync: (map['dirty'] as int? ?? 0) == 1,
        version: map['version'] as int? ?? 0,
        syncError: map['sync_error'] as String?,
      );

  @override
  String toString() =>
      'LinkModel(id: $id, title: $title, url: $url, categoryId: $categoryId, '
      'status: ${status.value}, isPendingSync: $isPendingSync)';
}
