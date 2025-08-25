import '../models/subcategory.dart';
import 'database_helper.dart';

class SubcategoryDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 获取所有子分类
  Future<List<Subcategory>> getAllSubcategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      orderBy: 'category_id, code',
    );

    return List.generate(maps.length, (i) {
      return Subcategory.fromMap(maps[i]);
    });
  }

  // 根据分类ID获取子分类
  Future<List<Subcategory>> getSubcategoriesByCategoryId(int categoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'code',
    );

    return List.generate(maps.length, (i) {
      return Subcategory.fromMap(maps[i]);
    });
  }

  // 根据ID获取子分类
  Future<Subcategory?> getSubcategoryById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Subcategory.fromMap(maps.first);
  }

  // 插入子分类
  Future<int> insertSubcategory(Subcategory subcategory) async {
    final db = await _databaseHelper.database;
    return await db.insert('subcategories', subcategory.toMap());
  }

  // 更新子分类
  Future<int> updateSubcategory(Subcategory subcategory) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'subcategories',
      subcategory.toMap(),
      where: 'id = ?',
      whereArgs: [subcategory.id],
    );
  }

  // 删除子分类
  Future<int> deleteSubcategory(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'subcategories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}