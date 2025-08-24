// 子分类模型类
class Subcategory {
  final int? id;
  final int categoryId;
  final String name;
  final String code;
  final String description;
  final DateTime createdAt;

  const Subcategory({
    this.id,
    required this.categoryId,
    required this.name,
    required this.code,
    required this.description,
    required this.createdAt,
  });

  // 从数据库Map创建Subcategory对象
  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      id: map['id']?.toInt(),
      categoryId: map['category_id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'code': code,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  Subcategory copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? code,
    String? description,
    DateTime? createdAt,
  }) {
    return Subcategory(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Subcategory(id: $id, categoryId: $categoryId, name: $name, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subcategory &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.name == name &&
        other.code == code;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        categoryId.hashCode ^
        name.hashCode ^
        code.hashCode;
  }
}