import '../models/classification_scheme.dart';
import 'database_helper.dart';

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
}
