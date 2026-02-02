class Department {
  final int id;
  final String name;
  final bool isManager;

  Department({required this.id, required this.name, required this.isManager});

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id'],
    name: json['name'] ?? '',
    isManager: json['is_manager_department'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_manager_department': isManager,
  };
}
