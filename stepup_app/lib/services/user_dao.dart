import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import 'database_helper.dart';

/// 用户数据访问对象
/// 负责用户表的增删改查操作
class UserDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 添加新用户
  Future<int> addUser(User user) async {
    final db = await _databaseHelper.database;
    return await db.insert('users', user.toMap());
  }

  /// 获取用户列表
  Future<List<User>> getUsers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  /// 获取第一个用户（默认用户）
  Future<User?> getFirstUser() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return User.fromMap(maps[0]);
  }

  /// 更新用户信息
  Future<int> updateUser(User user) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// 删除用户
  Future<int> deleteUser(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查是否存在用户
  Future<bool> hasUsers() async {
    final users = await getUsers();
    return users.isNotEmpty;
  }

  /// 获取用户数量
  Future<int> getUserCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}