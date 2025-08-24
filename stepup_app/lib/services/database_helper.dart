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
      version: 2,
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

    // 创建分类表（主维度）
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL DEFAULT '#2196F3',
        icon TEXT NOT NULL DEFAULT 'category',
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建子分类表
    await db.execute('''
      CREATE TABLE subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 创建级别表
    await db.execute('''
      CREATE TABLE levels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        score_multiplier REAL DEFAULT 1.0,
        description TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建标签表
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
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
        subcategory_id INTEGER,
        level_id INTEGER,
        score REAL NOT NULL DEFAULT 0.0,
        duration REAL NOT NULL DEFAULT 0.0,
        activity_date INTEGER NOT NULL,
        is_awarded INTEGER DEFAULT 0,
        award_level TEXT,
        is_collective INTEGER DEFAULT 0,
        is_leader INTEGER DEFAULT 0,
        participant_count INTEGER DEFAULT 1,
        image_path TEXT,
        file_path TEXT,
        remarks TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (subcategory_id) REFERENCES subcategories (id) ON DELETE SET NULL,
        FOREIGN KEY (level_id) REFERENCES levels (id) ON DELETE SET NULL
      )
    ''');

    // 创建活动标签关联表
    await db.execute('''
      CREATE TABLE assessment_item_tags (
        assessment_item_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (assessment_item_id, tag_id),
        FOREIGN KEY (assessment_item_id) REFERENCES assessment_items (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
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
    await db.execute('CREATE INDEX idx_assessment_items_subcategory_id ON assessment_items(subcategory_id)');
    await db.execute('CREATE INDEX idx_assessment_items_level_id ON assessment_items(level_id)');
    await db.execute('CREATE INDEX idx_assessment_items_activity_date ON assessment_items(activity_date)');
    await db.execute('CREATE INDEX idx_subcategories_category_id ON subcategories(category_id)');
    await db.execute('CREATE INDEX idx_scoring_rules_category_id ON scoring_rules(category_id)');
    await db.execute('CREATE INDEX idx_scoring_rules_is_enabled ON scoring_rules(is_enabled)');

    // 插入默认分类数据
    await _insertDefaultCategories(db);
    // 插入默认子分类数据
    await _insertDefaultSubcategories(db);
    // 插入默认级别数据
    await _insertDefaultLevels(db);
    // 插入默认标签数据
    await _insertDefaultTags(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 从版本1升级到版本2：添加新的数据表结构
      
      // 添加code字段到categories表
      await db.execute('ALTER TABLE categories ADD COLUMN code TEXT NOT NULL DEFAULT ""');
      
      // 创建子分类表
      await db.execute('''
        CREATE TABLE subcategories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      // 创建级别表
      await db.execute('''
        CREATE TABLE levels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          code TEXT,
          score_multiplier REAL DEFAULT 1.0,
          description TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      // 创建标签表
      await db.execute('''
        CREATE TABLE tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      // 添加新字段到assessment_items表
      await db.execute('ALTER TABLE assessment_items ADD COLUMN subcategory_id INTEGER');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN level_id INTEGER');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN is_awarded INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN award_level TEXT');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN is_collective INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN is_leader INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN participant_count INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN remarks TEXT');
      
      // 创建活动标签关联表
      await db.execute('''
        CREATE TABLE assessment_item_tags (
          assessment_item_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (assessment_item_id, tag_id),
          FOREIGN KEY (assessment_item_id) REFERENCES assessment_items (id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
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

      // 创建新的索引
      await db.execute('CREATE INDEX idx_assessment_items_subcategory_id ON assessment_items(subcategory_id)');
      await db.execute('CREATE INDEX idx_assessment_items_level_id ON assessment_items(level_id)');
      await db.execute('CREATE INDEX idx_subcategories_category_id ON subcategories(category_id)');
      await db.execute('CREATE INDEX idx_scoring_rules_category_id ON scoring_rules(category_id)');
      await db.execute('CREATE INDEX idx_scoring_rules_is_enabled ON scoring_rules(is_enabled)');
      
      // 更新categories表的code字段
      await db.execute('UPDATE categories SET code = "01" WHERE name = "德育"');
      await db.execute('UPDATE categories SET code = "02" WHERE name = "智育"');
      await db.execute('UPDATE categories SET code = "03" WHERE name = "体育锻炼"');
      await db.execute('UPDATE categories SET code = "04" WHERE name = "学术科研与创新"');
      await db.execute('UPDATE categories SET code = "05" WHERE name = "组织管理能力"');
      await db.execute('UPDATE categories SET code = "06" WHERE name = "劳动实践"');
      await db.execute('UPDATE categories SET code = "07" WHERE name = "美育素养"');
      
      // 插入默认子分类数据
      await _insertDefaultSubcategories(db);
      // 插入默认级别数据
      await _insertDefaultLevels(db);
      // 插入默认标签数据
      await _insertDefaultTags(db);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultCategories = [
      {
        'name': '德育',
        'code': '01',
        'description': '包括思想政治、道德品质、法纪观念、集体意识、生活修养等',
        'color': '#E91E63',
        'icon': 'favorite',
        'created_at': now,
      },
      {
        'name': '智育',
        'code': '02',
        'description': '学业成绩及人文素质培养情况',
        'color': '#2196F3',
        'icon': 'school',
        'created_at': now,
      },
      {
        'name': '体育锻炼',
        'code': '03',
        'description': '包括体质测试、体育活动参与与获奖等',
        'color': '#4CAF50',
        'icon': 'sports',
        'created_at': now,
      },
      {
        'name': '学术科研与创新',
        'code': '04',
        'description': '包括竞赛、科研项目、论文发表、专利等',
        'color': '#9C27B0',
        'icon': 'lightbulb',
        'created_at': now,
      },
      {
        'name': '组织管理能力',
        'code': '05',
        'description': '包括学生干部任职、重点工作参与等',
        'color': '#FF5722',
        'icon': 'management',
        'created_at': now,
      },
      {
        'name': '劳动实践',
        'code': '06',
        'description': '包括社会实践、志愿服务、实习、创业、劳动教育等',
        'color': '#FF9800',
        'icon': 'volunteer_activism',
        'created_at': now,
      },
      {
        'name': '美育素养',
        'code': '07',
        'description': '包括文艺类竞赛、发表作品、文化活动参与等',
        'color': '#607D8B',
        'icon': 'palette',
        'created_at': now,
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  Future<void> _insertDefaultSubcategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultSubcategories = [
      // 德育子分类 (category_id: 1)
      {'category_id': 1, 'name': '思想政治表现', 'code': 'D01', 'description': '入党申请、青马工程、团日活动等', 'created_at': now},
      {'category_id': 1, 'name': '获得表扬与荣誉', 'code': 'D02', 'description': '通报表扬、校级/院级荣誉', 'created_at': now},
      {'category_id': 1, 'name': '参加无偿献血', 'code': 'D03', 'description': '无偿献血/骨髃捐献等', 'created_at': now},
      {'category_id': 1, 'name': '拾金不昧见义勇为', 'code': 'D04', 'description': '拾金不昧/见义勇为', 'created_at': now},
      
      // 智育子分类 (category_id: 2)
      {'category_id': 2, 'name': '通识课程修读', 'code': 'Z01', 'description': '需记录所选类别', 'created_at': now},
      {'category_id': 2, 'name': '书籍阅读', 'code': 'Z02', 'description': '需提供读书笔记证明', 'created_at': now},
      {'category_id': 2, 'name': '参加阅读活动', 'code': 'Z03', 'description': '参加读书会/书评会等阅读活动', 'created_at': now},
      
      // 体育锻炼子分类 (category_id: 3)
      {'category_id': 3, 'name': '日常体育锻炼', 'code': 'T01', 'description': '可自动计算分值', 'created_at': now},
      {'category_id': 3, 'name': '体质健康测试成绩', 'code': 'T02', 'description': '体质健康测试成绩', 'created_at': now},
      {'category_id': 3, 'name': '参加体育赛事', 'code': 'T03', 'description': '校级、院级体育赛事', 'created_at': now},
      {'category_id': 3, 'name': '体育赛事获奖', 'code': 'T04', 'description': '体育赛事获奖', 'created_at': now},
      
      // 学术科研与创新子分类 (category_id: 4)
      {'category_id': 4, 'name': '学科竞赛', 'code': 'X01', 'description': '如数学建模、数学竞赛、挑战杯', 'created_at': now},
      {'category_id': 4, 'name': '学术科研项目', 'code': 'X02', 'description': '如大创、科研立项、结项', 'created_at': now},
      {'category_id': 4, 'name': '学术论文发表', 'code': 'X03', 'description': '需注明期刊等级和作者顺序', 'created_at': now},
      {'category_id': 4, 'name': '专利成果', 'code': 'X04', 'description': '发明、实用新型、外观设计', 'created_at': now},
      {'category_id': 4, 'name': '学术荣誉', 'code': 'X05', 'description': '国家级、校级、院级优秀称号', 'created_at': now},
      
      // 组织管理能力子分类 (category_id: 5)
      {'category_id': 5, 'name': '担任学生干部', 'code': 'G01', 'description': '需区分校级、院级、班级', 'created_at': now},
      {'category_id': 5, 'name': '工作业绩得分', 'code': 'G02', 'description': '由组织评定', 'created_at': now},
      {'category_id': 5, 'name': '获得优秀干部荣誉', 'code': 'G03', 'description': '工作期间获得优秀干部等荣誉称号', 'created_at': now},
      
      // 劳动实践子分类 (category_id: 6)
      {'category_id': 6, 'name': '社会实践', 'code': 'L01', 'description': '需记录团队/个人、是否立项、是否获奖', 'created_at': now},
      {'category_id': 6, 'name': '志愿服务', 'code': 'L02', 'description': '需记录时长、单位、活动类型', 'created_at': now},
      {'category_id': 6, 'name': '实习实践', 'code': 'L03', 'description': '需单位证明、岗位、时间', 'created_at': now},
      {'category_id': 6, 'name': '创业实践', 'code': 'L04', 'description': '需项目立项或成果证明', 'created_at': now},
      {'category_id': 6, 'name': '公益活动参与', 'code': 'L05', 'description': '如酵素制作、劳动教育课程等', 'created_at': now},
      {'category_id': 6, 'name': '志愿服务荣誉', 'code': 'L06', 'description': '如优秀志愿者', 'created_at': now},
      
      // 美育素养子分类 (category_id: 7)
      {'category_id': 7, 'name': '文化艺术类竞赛', 'code': 'M01', 'description': '如演讲、辩论、书法、摄影、舞蹈等', 'created_at': now},
      {'category_id': 7, 'name': '文化艺术类获奖', 'code': 'M02', 'description': '文化艺术类获奖', 'created_at': now},
      {'category_id': 7, 'name': '文学艺术类作品发表', 'code': 'M03', 'description': '文学艺术类作品发表', 'created_at': now},
      {'category_id': 7, 'name': '文化活动参与', 'code': 'M04', 'description': '如晚会、文化艺术社团', 'created_at': now},
      {'category_id': 7, 'name': '公共场合艺术展示', 'code': 'M05', 'description': '如个人画展、摄影展等', 'created_at': now},
    ];

    for (final subcategory in defaultSubcategories) {
      await db.insert('subcategories', subcategory);
    }
  }

  Future<void> _insertDefaultLevels(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultLevels = [
      {'name': '国家级', 'code': 'NATIONAL', 'score_multiplier': 5.0, 'description': '全国大学生数学建模竞赛一等奖', 'created_at': now},
      {'name': '省部级', 'code': 'PROVINCIAL', 'score_multiplier': 3.0, 'description': '省级学术比赛、部委主办的活动', 'created_at': now},
      {'name': '市级/地区级', 'code': 'CITY', 'score_multiplier': 2.0, 'description': '北京市级活动、跨校区域性比赛', 'created_at': now},
      {'name': '校级', 'code': 'UNIVERSITY', 'score_multiplier': 1.5, 'description': '中央财经大学主办的活动、校级竞赛', 'created_at': now},
      {'name': '院级', 'code': 'COLLEGE', 'score_multiplier': 1.0, 'description': '统计与数学学院主办活动', 'created_at': now},
      {'name': '其他', 'code': 'OTHER', 'score_multiplier': 0.5, 'description': '未明确级别，需人工核定', 'created_at': now},
    ];

    for (final level in defaultLevels) {
      await db.insert('levels', level);
    }
  }

  Future<void> _insertDefaultTags(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultTags = [
      {'name': '代表集体', 'code': 'COLLECTIVE', 'description': '活动是否是以集体身份参与', 'created_at': now},
      {'name': '获奖', 'code': 'AWARDED', 'description': '活动是否获得奖项', 'created_at': now},
      {'name': '自评', 'code': 'SELF_EVAL', 'description': '该活动需学生自评后由评议小组核定', 'created_at': now},
      {'name': '需证明', 'code': 'NEED_PROOF', 'description': '活动加分需要上传证明材料', 'created_at': now},
      {'name': '时长积分', 'code': 'TIME_BASED', 'description': '以参与时长计分', 'created_at': now},
      {'name': '一次记分', 'code': 'ONE_TIME', 'description': '同一事项取高不累加', 'created_at': now},
      {'name': '多人参与', 'code': 'TEAM_PROJECT', 'description': '团体项目，需区分负责人与成员得分', 'created_at': now},
    ];

    for (final tag in defaultTags) {
      await db.insert('tags', tag);
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