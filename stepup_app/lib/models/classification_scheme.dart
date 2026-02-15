class ClassificationScheme {
  final int? id;
  final String name;
  final String code;
  final String description;
  final bool isActive;
  final bool isDefault;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassificationScheme({
    this.id,
    required this.name,
    required this.code,
    this.description = '',
    this.isActive = false,
    this.isDefault = false,
    this.source = 'manual',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassificationScheme.fromMap(Map<String, dynamic> map) {
    return ClassificationScheme(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      isActive: map['is_active'] == 1,
      isDefault: map['is_default'] == 1,
      source: map['source'] ?? 'manual',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
      'source': source,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  ClassificationScheme copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    bool? isDefault,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassificationScheme(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ClassificationScheme(id: $id, name: $name, code: $code, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassificationScheme &&
        other.id == id &&
        other.name == name &&
        other.code == code &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ code.hashCode ^ isActive.hashCode;
  }
}
