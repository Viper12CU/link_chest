class CategoryModel {
  final int? id;
  final String title;
  final String icon;
  final String color;

  const CategoryModel({
    this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  CategoryModel copyWith({
    int? id,
    String? title,
    String? icon,
    String? color,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'color': color,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as int?,
        title: map['title'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String,
      );

  @override
  String toString() =>
      'CategoryModel(id: $id, title: $title, icon: $icon, color: $color)';
}
