import '../models/assessment_item.dart';
import 'database_helper.dart';

class AssessmentItemDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 获取所有综测条目
  Future<List<AssessmentItem>> getAllItems({
    int? categoryId,
    int? subcategoryId,
    int? levelId,
    bool? isAwarded,
    bool? isCollective,
    bool? isLeader,
    DateTime? startDate,
    DateTime? endDate,
    String orderBy = 'created_at DESC',
  }) async {
    final db = await _databaseHelper.database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (subcategoryId != null) {
      whereClauses.add('subcategory_id = ?');
      whereArgs.add(subcategoryId);
    }

    if (levelId != null) {
      whereClauses.add('level_id = ?');
      whereArgs.add(levelId);
    }

    if (isAwarded != null) {
      whereClauses.add('is_awarded = ?');
      whereArgs.add(isAwarded ? 1 : 0);
    }

    if (isCollective != null) {
      whereClauses.add('is_collective = ?');
      whereArgs.add(isCollective ? 1 : 0);
    }

    if (isLeader != null) {
      whereClauses.add('is_leader = ?');
      whereArgs.add(isLeader ? 1 : 0);
    }

    if (startDate != null) {
      whereClauses.add('activity_date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClauses.add('activity_date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final String? whereClause = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'assessment_items',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) {
      return AssessmentItem.fromMap(maps[i]);
    });
  }

  // 根据ID获取综测条目
  Future<AssessmentItem?> getItemById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessment_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return AssessmentItem.fromMap(maps.first);
  }

  // 搜索综测条目
  Future<List<AssessmentItem>> searchItems(String keyword) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessment_items',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return AssessmentItem.fromMap(maps[i]);
    });
  }

  // 插入综测条目
  Future<int> insertItem(AssessmentItem item) async {
    final db = await _databaseHelper.database;
    return await db.insert('assessment_items', item.toMap());
  }

  // 更新综测条目
  Future<int> updateItem(AssessmentItem item) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'assessment_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // 删除综测条目
  Future<int> deleteItem(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'assessment_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 批量删除综测条目
  Future<int> deleteItems(List<int> ids) async {
    final db = await _databaseHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'assessment_items',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // 获取统计数据
  Future<Map<String, dynamic>> getStatistics({
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      whereClauses.add('activity_date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClauses.add('activity_date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final String whereClause = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    // 获取总数、总时长、获奖条目数
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_count,
        SUM(duration) as total_duration,
        SUM(CASE WHEN is_awarded = 1 THEN 1 ELSE 0 END) as awarded_count
      FROM assessment_items 
      $whereClause
    ''', whereArgs);

    // 获取各分类的统计
    List<String> categoryWhereClauses = [];
    List<dynamic> categoryWhereArgs = [];

    if (startDate != null) {
      categoryWhereClauses.add('activity_date >= ?');
      categoryWhereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      categoryWhereClauses.add('activity_date <= ?');
      categoryWhereArgs.add(endDate.millisecondsSinceEpoch);
    }

    String categoryWhereClause = '';
    if (categoryWhereClauses.isNotEmpty) {
      categoryWhereClause = 'WHERE ${categoryWhereClauses.join(' AND ')}';
    }

    final List<Map<String, dynamic>> categoryResult = await db.rawQuery('''
      SELECT 
        ai.category_id,
        c.name as category_name,
        c.color as category_color,
        COUNT(*) as count,
        SUM(ai.duration) as total_duration
      FROM assessment_items ai
      LEFT JOIN categories c ON ai.category_id = c.id
      $categoryWhereClause
      GROUP BY ai.category_id, c.name, c.color
      ORDER BY total_duration DESC
    ''', categoryWhereArgs);

    return {
      'totalCount': result.first['total_count'] ?? 0,
      'totalDuration': result.first['total_duration'] ?? 0.0,
      'awardedCount': result.first['awarded_count'] ?? 0,
      'categoryStats': categoryResult,
    };
  }

  // 获取最近的条目
  Future<List<AssessmentItem>> getRecentItems({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessment_items',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return AssessmentItem.fromMap(maps[i]);
    });
  }

  // 获取按月份分组的统计数据
  Future<List<Map<String, dynamic>>> getMonthlyStats(int year) async {
    final db = await _databaseHelper.database;
    
    final startOfYear = DateTime(year, 1, 1).millisecondsSinceEpoch;
    final endOfYear = DateTime(year + 1, 1, 1).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        strftime('%m', datetime(activity_date/1000, 'unixepoch')) as month,
        COUNT(*) as count,
        SUM(duration) as total_duration
      FROM assessment_items 
      WHERE activity_date >= ? AND activity_date < ?
      GROUP BY month
      ORDER BY month
    ''', [startOfYear, endOfYear]);

    return result;
  }
}