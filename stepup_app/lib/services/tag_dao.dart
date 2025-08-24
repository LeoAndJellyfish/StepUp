import '../models/tag.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class TagDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 获取所有标签
  Future<List<Tag>> getAllTags() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      orderBy: 'name',
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  // 根据ID获取标签
  Future<Tag?> getTagById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Tag.fromMap(maps.first);
  }

  // 获取条目的标签
  Future<List<Tag>> getTagsByAssessmentItemId(int assessmentItemId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN assessment_item_tags ait ON t.id = ait.tag_id
      WHERE ait.assessment_item_id = ?
      ORDER BY t.name
    ''', [assessmentItemId]);

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  // 为条目添加标签
  Future<void> addTagToAssessmentItem(int assessmentItemId, int tagId) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'assessment_item_tags',
      {
        'assessment_item_id': assessmentItemId,
        'tag_id': tagId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // 为条目移除标签
  Future<void> removeTagFromAssessmentItem(int assessmentItemId, int tagId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'assessment_item_tags',
      where: 'assessment_item_id = ? AND tag_id = ?',
      whereArgs: [assessmentItemId, tagId],
    );
  }

  // 设置条目的标签（先清除所有标签，然后添加新标签）
  Future<void> setTagsForAssessmentItem(int assessmentItemId, List<int> tagIds) async {
    final db = await _databaseHelper.database;
    
    // 开启事务
    await db.transaction((txn) async {
      // 先删除所有现有标签
      await txn.delete(
        'assessment_item_tags',
        where: 'assessment_item_id = ?',
        whereArgs: [assessmentItemId],
      );
      
      // 添加新标签
      for (int tagId in tagIds) {
        await txn.insert(
          'assessment_item_tags',
          {
            'assessment_item_id': assessmentItemId,
            'tag_id': tagId,
          },
        );
      }
    });
  }

  // 插入标签
  Future<int> insertTag(Tag tag) async {
    final db = await _databaseHelper.database;
    return await db.insert('tags', tag.toMap());
  }

  // 更新标签
  Future<int> updateTag(Tag tag) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  // 删除标签
  Future<int> deleteTag(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}