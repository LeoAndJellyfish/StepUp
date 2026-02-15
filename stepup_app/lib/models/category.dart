class Category {
  final int? id;
  final int? schemeId;
  final String name;
  final String code;
  final String description;
  final String color;
  final String icon;
  final DateTime createdAt;

  const Category({
    this.id,
    this.schemeId,
    required this.name,
    required this.code,
    this.description = '',
    this.color = '#2196F3',
    this.icon = 'category',
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toInt(),
      schemeId: map['scheme_id']?.toInt(),
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#2196F3',
      icon: map['icon'] ?? 'category',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheme_id': schemeId,
      'name': name,
      'code': code,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Category copyWith({
    int? id,
    int? schemeId,
    String? name,
    String? code,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      schemeId: schemeId ?? this.schemeId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, schemeId: $schemeId, name: $name, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.schemeId == schemeId &&
        other.name == name &&
        other.code == code &&
        other.description == description &&
        other.color == color &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        schemeId.hashCode ^
        name.hashCode ^
        code.hashCode ^
        description.hashCode ^
        color.hashCode ^
        icon.hashCode;
  }
}
