import '../models/classification_scheme.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import 'database_helper.dart';
import 'category_dao.dart';
import 'subcategory_dao.dart';

class ClassificationSchemeDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<ClassificationScheme>> getAllSchemes() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'classification_schemes',
      orderBy: 'is_default DESC, created_at ASC',
    );
    return List.generate(maps.length, (i) => ClassificationScheme.fromMap(maps[i]));
  }

  Future<ClassificationScheme?> getSchemeById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'classification_schemes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ClassificationScheme.fromMap(maps.first);
    }
    return null;
  }

  Future<ClassificationScheme?> getActiveScheme() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'classification_schemes',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return ClassificationScheme.fromMap(maps.first);
    }
    return null;
  }

  Future<ClassificationScheme?> getDefaultScheme() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'classification_schemes',
      where: 'is_default = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return ClassificationScheme.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertScheme(ClassificationScheme scheme) async {
    final db = await _databaseHelper.database;
    return await db.insert('classification_schemes', scheme.toMap());
  }

  Future<int> updateScheme(ClassificationScheme scheme) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'classification_schemes',
      scheme.toMap(),
      where: 'id = ?',
      whereArgs: [scheme.id],
    );
  }

  Future<int> deleteScheme(int id) async {
    final db = await _databaseHelper.database;
    final scheme = await getSchemeById(id);
    if (scheme != null && scheme.isDefault) {
      return 0;
    }
    return await db.delete(
      'classification_schemes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setActiveScheme(int schemeId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'classification_schemes',
      {'is_active': 0},
    );
    await db.update(
      'classification_schemes',
      {'is_active': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [schemeId],
    );
  }

  Future<bool> hasActiveItems(int schemeId) async {
    final db = await _databaseHelper.database;
    final categories = await db.query(
      'categories',
      where: 'scheme_id = ?',
      whereArgs: [schemeId],
    );
    if (categories.isEmpty) return false;
    
    final categoryIds = categories.map((c) => c['id']).toList();
    final placeholders = List.filled(categoryIds.length, '?').join(',');
    
    final items = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assessment_items WHERE category_id IN ($placeholders)',
      categoryIds,
    );
    
    return (items.first['count'] as int) > 0;
  }

  Future<int> getItemCount(int schemeId) async {
    final db = await _databaseHelper.database;
    final categories = await db.query(
      'categories',
      where: 'scheme_id = ?',
      whereArgs: [schemeId],
    );
    if (categories.isEmpty) return 0;
    
    final categoryIds = categories.map((c) => c['id']).toList();
    final placeholders = List.filled(categoryIds.length, '?').join(',');
    
    final items = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assessment_items WHERE category_id IN ($placeholders)',
      categoryIds,
    );
    
    return items.first['count'] as int;
  }

  /// 复制分类方案及其所有分类和子分类
  /// 返回新创建的方案ID
  Future<int> duplicateScheme(int schemeId, {String? newName, String? newCode}) async {
    final categoryDao = CategoryDao();
    final subcategoryDao = SubcategoryDao();
    
    // 获取原方案
    final originalScheme = await getSchemeById(schemeId);
    if (originalScheme == null) {
      throw Exception('分类方案不存在');
    }
    
    // 生成新名称和编码
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = newName ?? '${originalScheme.name} (副本)';
    final code = newCode ?? '${originalScheme.code}_copy_$timestamp';
    
    // 创建新方案
    final newScheme = ClassificationScheme(
      name: name,
      code: code,
      description: originalScheme.description,
      isActive: false, // 复制方案默认不激活
      isDefault: false, // 复制方案不能是默认方案
      source: 'manual',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final newSchemeId = await insertScheme(newScheme);
    
    // 获取原方案的所有分类
    final categories = await categoryDao.getCategoriesBySchemeId(schemeId);
    
    // 复制分类和子分类
    for (final category in categories) {
      // 创建新分类
      final newCategory = Category(
        schemeId: newSchemeId,
        name: category.name,
        code: category.code,
        description: category.description,
        color: category.color,
        icon: category.icon,
        createdAt: DateTime.now(),
      );
      
      final newCategoryId = await categoryDao.insertCategory(newCategory);
      
      // 获取原分类的所有子分类
      if (category.id != null) {
        final subcategories = await subcategoryDao.getSubcategoriesByCategoryId(category.id!);
        
        // 复制子分类
        for (final subcategory in subcategories) {
          final newSubcategory = Subcategory(
            categoryId: newCategoryId,
            name: subcategory.name,
            code: subcategory.code,
            description: subcategory.description,
            createdAt: DateTime.now(),
          );
          
          await subcategoryDao.insertSubcategory(newSubcategory);
        }
      }
    }
    
    return newSchemeId;
  }
}
