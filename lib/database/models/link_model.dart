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
  final int? id;
  final String title;
  final String? description;
  final String url;
  final int categoryId;
  final LinkStatus status;

  const LinkModel({
    this.id,
    required this.title,
    this.description,
    required this.url,
    required this.categoryId,
    this.status = LinkStatus.public,
  });

  LinkModel copyWith({
    int? id,
    String? title,
    String? description,
    String? url,
    int? categoryId,
    LinkStatus? status,
  }) {
    return LinkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'url': url,
        'category_id': categoryId,
        'status': status.value,
      };

  factory LinkModel.fromMap(Map<String, dynamic> map) => LinkModel(
        id: map['id'] as int?,
        title: map['title'] as String,
        description: map['description'] as String?,
        url: map['url'] as String,
        categoryId: map['category_id'] as int,
        status: LinkStatus.fromString(map['status'] as String),
      );

  @override
  String toString() =>
      'LinkModel(id: $id, title: $title, url: $url, categoryId: $categoryId, status: ${status.value})';
}
