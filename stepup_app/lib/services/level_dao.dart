import '../models/level.dart';
import 'database_helper.dart';

class LevelDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 获取所有级别
  Future<List<Level>> getAllLevels() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'levels',
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return Level.fromMap(maps[i]);
    });
  }

  // 根据ID获取级别
  Future<Level?> getLevelById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'levels',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Level.fromMap(maps.first);
  }

  // 插入级别
  Future<int> insertLevel(Level level) async {
    final db = await _databaseHelper.database;
    return await db.insert('levels', level.toMap());
  }

  // 更新级别
  Future<int> updateLevel(Level level) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'levels',
      level.toMap(),
      where: 'id = ?',
      whereArgs: [level.id],
    );
  }

  // 删除级别
  Future<int> deleteLevel(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'levels',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}