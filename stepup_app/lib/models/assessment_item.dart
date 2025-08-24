// 综测条目模型类
class AssessmentItem {
  final int? id;
  final String title;
  final String description;
  final int categoryId;
  final double score;
  final double duration; // 时长（小时）
  final DateTime activityDate;
  final String? imagePath; // 证明图片路径
  final String? filePath; // 证明文件路径
  final String? remarks; // 备注
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssessmentItem({
    this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.score,
    required this.duration,
    required this.activityDate,
    this.imagePath,
    this.filePath,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从数据库Map创建AssessmentItem对象
  factory AssessmentItem.fromMap(Map<String, dynamic> map) {
    return AssessmentItem(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['category_id']?.toInt() ?? 0,
      score: map['score']?.toDouble() ?? 0.0,
      duration: map['duration']?.toDouble() ?? 0.0,
      activityDate: DateTime.fromMillisecondsSinceEpoch(map['activity_date']),
      imagePath: map['image_path'],
      filePath: map['file_path'],
      remarks: map['remarks'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'score': score,
      'duration': duration,
      'activity_date': activityDate.millisecondsSinceEpoch,
      'image_path': imagePath,
      'file_path': filePath,
      'remarks': remarks,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  AssessmentItem copyWith({
    int? id,
    String? title,
    String? description,
    int? categoryId,
    double? score,
    double? duration,
    DateTime? activityDate,
    String? imagePath,
    String? filePath,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      score: score ?? this.score,
      duration: duration ?? this.duration,
      activityDate: activityDate ?? this.activityDate,
      imagePath: imagePath ?? this.imagePath,
      filePath: filePath ?? this.filePath,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AssessmentItem(id: $id, title: $title, categoryId: $categoryId, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssessmentItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.score == score &&
        other.duration == duration &&
        other.activityDate == activityDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        score.hashCode ^
        duration.hashCode ^
        activityDate.hashCode;
  }
}