// 级别模型类
class Level {
  final int? id;
  final String name;
  final String? code;
  final double scoreMultiplier;
  final String? description;
  final DateTime createdAt;

  const Level({
    this.id,
    required this.name,
    this.code,
    required this.scoreMultiplier,
    this.description,
    required this.createdAt,
  });

  // 从数据库Map创建Level对象
  factory Level.fromMap(Map<String, dynamic> map) {
    return Level(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      code: map['code'],
      scoreMultiplier: (map['score_multiplier'] ?? 1.0).toDouble(),
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
      'score_multiplier': scoreMultiplier,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  Level copyWith({
    int? id,
    String? name,
    String? code,
    double? scoreMultiplier,
    String? description,
    DateTime? createdAt,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      scoreMultiplier: scoreMultiplier ?? this.scoreMultiplier,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Level(id: $id, name: $name, code: $code, scoreMultiplier: $scoreMultiplier)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Level &&
        other.id == id &&
        other.name == name &&
        other.code == code &&
        other.scoreMultiplier == scoreMultiplier;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        code.hashCode ^
        scoreMultiplier.hashCode;
  }
}