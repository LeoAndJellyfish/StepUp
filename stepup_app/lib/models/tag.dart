// 标签模型类
class Tag {
  final int? id;
  final String name;
  final String code;
  final String? description;
  final DateTime createdAt;

  const Tag({
    this.id,
    required this.name,
    required this.code,
    this.description,
    required this.createdAt,
  });

  // 从数据库Map创建Tag对象
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  Tag copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag &&
        other.id == id &&
        other.name == name &&
        other.code == code;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        code.hashCode;
  }
}