// 分类模型类
class Category {
  final int? id;
  final String name;
  final String description;
  final String color; // 存储颜色值，如 "#FF5722"
  final String icon; // 图标名称或编码
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  // 从数据库Map创建Category对象
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#2196F3',
      icon: map['icon'] ?? 'category',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, description: $description, color: $color, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.color == color &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        color.hashCode ^
        icon.hashCode;
  }
}