// 文件附件模型类
class FileAttachment {
  final int? id;
  final int assessmentItemId; // 关联的评估条目ID
  final String fileName; // 原始文件名
  final String filePath; // 存储路径
  final String fileType; // 文件类型 (image/document)
  final int fileSize; // 文件大小（字节）
  final String? mimeType; // MIME类型
  final DateTime uploadedAt; // 上传时间

  const FileAttachment({
    this.id,
    required this.assessmentItemId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.mimeType,
    required this.uploadedAt,
  });

  // 从数据库Map创建FileAttachment对象
  factory FileAttachment.fromMap(Map<String, dynamic> map) {
    return FileAttachment(
      id: map['id']?.toInt(),
      assessmentItemId: map['assessment_item_id']?.toInt() ?? 0,
      fileName: map['file_name'] ?? '',
      filePath: map['file_path'] ?? '',
      fileType: map['file_type'] ?? '',
      fileSize: map['file_size']?.toInt() ?? 0,
      mimeType: map['mime_type'],
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(map['uploaded_at']),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assessment_item_id': assessmentItemId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_at': uploadedAt.millisecondsSinceEpoch,
    };
  }

  // 复制并更新部分字段
  FileAttachment copyWith({
    int? id,
    int? assessmentItemId,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    String? mimeType,
    DateTime? uploadedAt,
  }) {
    return FileAttachment(
      id: id ?? this.id,
      assessmentItemId: assessmentItemId ?? this.assessmentItemId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  // 判断是否为图片文件
  bool get isImage => fileType == 'image';

  // 判断是否为文档文件
  bool get isDocument => fileType == 'document';

  // 获取文件扩展名
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  // 获取格式化的文件大小
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'FileAttachment(id: $id, fileName: $fileName, fileType: $fileType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileAttachment &&
        other.id == id &&
        other.assessmentItemId == assessmentItemId &&
        other.fileName == fileName &&
        other.filePath == filePath;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        assessmentItemId.hashCode ^
        fileName.hashCode ^
        filePath.hashCode;
  }
}