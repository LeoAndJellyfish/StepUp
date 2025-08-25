// 综测条目模型类
class AssessmentItem {
  final int? id;
  final String title;
  final String description;
  final int categoryId;
  final int? subcategoryId;
  final int? levelId;
  final double duration; // 时长（小时）
  final DateTime activityDate;
  final bool isAwarded; // 是否获奖
  final String? awardLevel; // 获奖等级
  final bool isCollective; // 是否代表集体
  final bool isLeader; // 是否为负责人
  final int participantCount; // 参与人数
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
    this.subcategoryId,
    this.levelId,
    required this.duration,
    required this.activityDate,
    this.isAwarded = false,
    this.awardLevel,
    this.isCollective = false,
    this.isLeader = false,
    this.participantCount = 1,
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
      subcategoryId: map['subcategory_id']?.toInt(),
      levelId: map['level_id']?.toInt(),
      duration: map['duration']?.toDouble() ?? 0.0,
      activityDate: DateTime.fromMillisecondsSinceEpoch(map['activity_date']),
      isAwarded: (map['is_awarded'] ?? 0) == 1,
      awardLevel: map['award_level'],
      isCollective: (map['is_collective'] ?? 0) == 1,
      isLeader: (map['is_leader'] ?? 0) == 1,
      participantCount: map['participant_count']?.toInt() ?? 1,
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
      'subcategory_id': subcategoryId,
      'level_id': levelId,
      'duration': duration,
      'activity_date': activityDate.millisecondsSinceEpoch,
      'is_awarded': isAwarded ? 1 : 0,
      'award_level': awardLevel,
      'is_collective': isCollective ? 1 : 0,
      'is_leader': isLeader ? 1 : 0,
      'participant_count': participantCount,
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
    int? subcategoryId,
    int? levelId,
    double? duration,
    DateTime? activityDate,
    bool? isAwarded,
    String? awardLevel,
    bool? isCollective,
    bool? isLeader,
    int? participantCount,
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
      subcategoryId: subcategoryId ?? this.subcategoryId,
      levelId: levelId ?? this.levelId,
      duration: duration ?? this.duration,
      activityDate: activityDate ?? this.activityDate,
      isAwarded: isAwarded ?? this.isAwarded,
      awardLevel: awardLevel ?? this.awardLevel,
      isCollective: isCollective ?? this.isCollective,
      isLeader: isLeader ?? this.isLeader,
      participantCount: participantCount ?? this.participantCount,
      imagePath: imagePath ?? this.imagePath,
      filePath: filePath ?? this.filePath,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AssessmentItem(id: $id, title: $title, categoryId: $categoryId, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssessmentItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.duration == duration &&
        other.activityDate == activityDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        duration.hashCode ^
        activityDate.hashCode;
  }
}