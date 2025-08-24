// 用户模型类
class User {
  final int? id;
  final String name;
  final String studentId;
  final String email;
  final String phone;
  final String major;
  final int grade;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.major,
    required this.grade,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从数据库Map创建User对象
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      studentId: map['student_id'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      major: map['major'] ?? '',
      grade: map['grade']?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'student_id': studentId,
      'email': email,
      'phone': phone,
      'major': major,
      'grade': grade,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  User copyWith({
    int? id,
    String? name,
    String? studentId,
    String? email,
    String? phone,
    String? major,
    int? grade,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      major: major ?? this.major,
      grade: grade ?? this.grade,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, studentId: $studentId, email: $email, phone: $phone, major: $major, grade: $grade)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.studentId == studentId &&
        other.email == email &&
        other.phone == phone &&
        other.major == major &&
        other.grade == grade;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        studentId.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        major.hashCode ^
        grade.hashCode;
  }
}