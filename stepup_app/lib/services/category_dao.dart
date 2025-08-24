import '../models/category.dart';
import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 获取所有分类
  Future<List<Category>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // 根据ID获取分类
  Future<Category?> getCategoryById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Category.fromMap(maps.first);
  }

  // 根据名称获取分类
  Future<Category?> getCategoryByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Category.fromMap(maps.first);
  }

  // 插入分类
  Future<int> insertCategory(Category category) async {
    final db = await _databaseHelper.database;
    return await db.insert('categories', category.toMap());
  }

  // 更新分类
  Future<int> updateCategory(Category category) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // 删除分类
  Future<int> deleteCategory(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 检查分类是否被使用
  Future<bool> isCategoryInUse(int categoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'assessment_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // 获取分类统计信息
  Future<Map<String, dynamic>> getCategoryStats(int categoryId) async {
    final db = await _databaseHelper.database;
    
    // 获取条目数量
    final List<Map<String, dynamic>> countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assessment_items WHERE category_id = ?',
      [categoryId],
    );
    
    // 获取总分数
    final List<Map<String, dynamic>> scoreResult = await db.rawQuery(
      'SELECT SUM(score) as total_score FROM assessment_items WHERE category_id = ?',
      [categoryId],
    );
    
    // 获取总时长
    final List<Map<String, dynamic>> durationResult = await db.rawQuery(
      'SELECT SUM(duration) as total_duration FROM assessment_items WHERE category_id = ?',
      [categoryId],
    );

    return {
      'count': countResult.first['count'] ?? 0,
      'totalScore': scoreResult.first['total_score'] ?? 0.0,
      'totalDuration': durationResult.first['total_duration'] ?? 0.0,
    };
  }
}