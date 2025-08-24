// 评分规则模型类
class ScoringRule {
  final int? id;
  final String name;
  final String description;
  final int categoryId;
  final String ruleType; // 规则类型：fixed, time_based, score_based
  final Map<String, dynamic> parameters; // 规则参数，以JSON形式存储
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScoringRule({
    this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.ruleType,
    required this.parameters,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从数据库Map创建ScoringRule对象
  factory ScoringRule.fromMap(Map<String, dynamic> map) {
    return ScoringRule(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['category_id']?.toInt() ?? 0,
      ruleType: map['rule_type'] ?? 'fixed',
      parameters: map['parameters'] is String 
          ? {} // 这里应该解析JSON，暂时用空Map
          : Map<String, dynamic>.from(map['parameters'] ?? {}),
      isEnabled: map['is_enabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'rule_type': ruleType,
      'parameters': parameters.toString(), // 实际应该用JSON序列化
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  ScoringRule copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    String? ruleType,
    Map<String, dynamic>? parameters,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScoringRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      ruleType: ruleType ?? this.ruleType,
      parameters: parameters ?? this.parameters,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ScoringRule(id: $id, name: $name, categoryId: $categoryId, ruleType: $ruleType, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoringRule &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.ruleType == ruleType &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        ruleType.hashCode ^
        isEnabled.hashCode;
  }
}