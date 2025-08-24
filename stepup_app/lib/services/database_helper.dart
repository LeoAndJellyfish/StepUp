import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'stepup.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建用户表
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        student_id TEXT UNIQUE NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        major TEXT NOT NULL,
        grade INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL DEFAULT '#2196F3',
        icon TEXT NOT NULL DEFAULT 'category',
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建综测条目表
    await db.execute('''
      CREATE TABLE assessment_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL,
        score REAL NOT NULL DEFAULT 0.0,
        duration REAL NOT NULL DEFAULT 0.0,
        activity_date INTEGER NOT NULL,
        image_path TEXT,
        file_path TEXT,
        remarks TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 创建评分规则表
    await db.execute('''
      CREATE TABLE scoring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL,
        rule_type TEXT NOT NULL DEFAULT 'fixed',
        parameters TEXT,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_assessment_items_category_id ON assessment_items(category_id)');
    await db.execute('CREATE INDEX idx_assessment_items_activity_date ON assessment_items(activity_date)');
    await db.execute('CREATE INDEX idx_scoring_rules_category_id ON scoring_rules(category_id)');
    await db.execute('CREATE INDEX idx_scoring_rules_is_enabled ON scoring_rules(is_enabled)');

    // 插入默认分类数据
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时的处理逻辑
    if (oldVersion < newVersion) {
      // 这里添加数据库升级逻辑
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultCategories = [
      {
        'name': '学术科研',
        'description': '学术竞赛、科研项目、论文发表等',
        'color': '#2196F3',
        'icon': 'school',
        'created_at': now,
      },
      {
        'name': '社会实践',
        'description': '志愿服务、社会调研、实习实践等',
        'color': '#4CAF50',
        'icon': 'volunteer_activism',
        'created_at': now,
      },
      {
        'name': '文体活动',
        'description': '文艺表演、体育竞赛、社团活动等',
        'color': '#FF9800',
        'icon': 'sports',
        'created_at': now,
      },
      {
        'name': '技能培训',
        'description': '职业技能、语言学习、证书考试等',
        'color': '#9C27B0',
        'icon': 'psychology',
        'created_at': now,
      },
      {
        'name': '创新创业',
        'description': '创业项目、创新竞赛、专利申请等',
        'color': '#FF5722',
        'icon': 'lightbulb',
        'created_at': now,
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // 清空数据库（用于测试）
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'stepup.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}