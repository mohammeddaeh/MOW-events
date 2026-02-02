class CategoryModel {
  final int? id;
  final String name;
  final String color;
  final String description;

  CategoryModel({
    this.id,
    required this.name,
    required this.color,
    required this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color,
    'description': description,
  };

  CategoryModel copyWith({
    int? id,
    String? name,
    String? color,
    String? description,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
