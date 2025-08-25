import '../models/file_attachment.dart';
import 'database_helper.dart';

class FileAttachmentDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 获取评估条目的所有文件附件
  Future<List<FileAttachment>> getAttachmentsByItemId(int assessmentItemId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_attachments',
      where: 'assessment_item_id = ?',
      whereArgs: [assessmentItemId],
      orderBy: 'uploaded_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FileAttachment.fromMap(maps[i]);
    });
  }

  // 根据文件类型获取附件
  Future<List<FileAttachment>> getAttachmentsByType(int assessmentItemId, String fileType) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_attachments',
      where: 'assessment_item_id = ? AND file_type = ?',
      whereArgs: [assessmentItemId, fileType],
      orderBy: 'uploaded_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FileAttachment.fromMap(maps[i]);
    });
  }

  // 插入文件附件
  Future<int> insertAttachment(FileAttachment attachment) async {
    final db = await _databaseHelper.database;
    return await db.insert('file_attachments', attachment.toMap());
  }

  // 批量插入文件附件
  Future<List<int>> insertAttachments(List<FileAttachment> attachments) async {
    final db = await _databaseHelper.database;
    final List<int> ids = [];
    
    await db.transaction((txn) async {
      for (final attachment in attachments) {
        final id = await txn.insert('file_attachments', attachment.toMap());
        ids.add(id);
      }
    });
    
    return ids;
  }

  // 删除文件附件
  Future<int> deleteAttachment(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'file_attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除评估条目的所有文件附件
  Future<int> deleteAttachmentsByItemId(int assessmentItemId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'file_attachments',
      where: 'assessment_item_id = ?',
      whereArgs: [assessmentItemId],
    );
  }

  // 根据ID获取单个文件附件
  Future<FileAttachment?> getAttachmentById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_attachments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return FileAttachment.fromMap(maps.first);
  }

  // 更新文件附件
  Future<int> updateAttachment(FileAttachment attachment) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'file_attachments',
      attachment.toMap(),
      where: 'id = ?',
      whereArgs: [attachment.id],
    );
  }

  // 获取所有文件路径（用于清理未使用的文件）
  Future<List<String>> getAllFilePaths() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_attachments',
      columns: ['file_path'],
    );

    return maps.map((map) => map['file_path'] as String).toList();
  }

  // 统计评估条目的文件数量
  Future<Map<String, int>> getFileCountByItemId(int assessmentItemId) async {
    final db = await _databaseHelper.database;
    
    final imageCount = await db.rawQuery('''
      SELECT COUNT(*) as count FROM file_attachments 
      WHERE assessment_item_id = ? AND file_type = 'image'
    ''', [assessmentItemId]);
    
    final documentCount = await db.rawQuery('''
      SELECT COUNT(*) as count FROM file_attachments 
      WHERE assessment_item_id = ? AND file_type = 'document'
    ''', [assessmentItemId]);

    return {
      'image': imageCount.first['count'] as int,
      'document': documentCount.first['count'] as int,
    };
  }
}