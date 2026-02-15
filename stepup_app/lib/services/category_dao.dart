import '../models/category.dart';
import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<Category>> getAllCategories({int? schemeId}) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps;
    
    if (schemeId != null) {
      maps = await db.query(
        'categories',
        where: 'scheme_id = ?',
        whereArgs: [schemeId],
        orderBy: 'created_at ASC',
      );
    } else {
      maps = await db.query(
        'categories',
        orderBy: 'created_at ASC',
      );
    }

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<List<Category>> getCategoriesBySchemeId(int schemeId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'scheme_id = ?',
      whereArgs: [schemeId],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

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

  Future<Category?> getCategoryByName(String name, {int? schemeId}) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps;
    
    if (schemeId != null) {
      maps = await db.query(
        'categories',
        where: 'name = ? AND scheme_id = ?',
        whereArgs: [name, schemeId],
      );
    } else {
      maps = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [name],
      );
    }

    if (maps.isEmpty) {
      return null;
    }

    return Category.fromMap(maps.first);
  }

  Future<Category?> getCategoryByCode(String code, {int? schemeId}) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps;
    
    if (schemeId != null) {
      maps = await db.query(
        'categories',
        where: 'code = ? AND scheme_id = ?',
        whereArgs: [code, schemeId],
      );
    } else {
      maps = await db.query(
        'categories',
        where: 'code = ?',
        whereArgs: [code],
      );
    }

    if (maps.isEmpty) {
      return null;
    }

    return Category.fromMap(maps.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await _databaseHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategoriesBySchemeId(int schemeId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'categories',
      where: 'scheme_id = ?',
      whereArgs: [schemeId],
    );
  }

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

  Future<Map<String, dynamic>> getCategoryStats(int categoryId) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assessment_items WHERE category_id = ?',
      [categoryId],
    );
    
    final List<Map<String, dynamic>> durationResult = await db.rawQuery(
      'SELECT SUM(duration) as total_duration FROM assessment_items WHERE category_id = ?',
      [categoryId],
    );

    return {
      'count': countResult.first['count'] ?? 0,
      'totalDuration': durationResult.first['total_duration'] ?? 0.0,
    };
  }

  Future<int> getCategoryCount(int schemeId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories WHERE scheme_id = ?',
      [schemeId],
    );
    return result.first['count'] as int;
  }
}
