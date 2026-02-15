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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE classification_schemes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        description TEXT,
        is_active INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        source TEXT DEFAULT 'manual',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheme_id INTEGER,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL DEFAULT '#2196F3',
        icon TEXT NOT NULL DEFAULT 'category',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (scheme_id) REFERENCES classification_schemes (id) ON DELETE CASCADE
      )
    ''');

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

    await db.execute('''
      CREATE TABLE levels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        description TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assessment_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL,
        subcategory_id INTEGER,
        level_id INTEGER,
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

    await db.execute('''
      CREATE TABLE assessment_item_tags (
        assessment_item_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (assessment_item_id, tag_id),
        FOREIGN KEY (assessment_item_id) REFERENCES assessment_items (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE file_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessment_item_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type TEXT,
        uploaded_at INTEGER NOT NULL,
        FOREIGN KEY (assessment_item_id) REFERENCES assessment_items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_file_attachments_assessment_item_id ON file_attachments(assessment_item_id)');
    await db.execute('CREATE INDEX idx_file_attachments_file_type ON file_attachments(file_type)');
    await db.execute('CREATE INDEX idx_assessment_items_category_id ON assessment_items(category_id)');
    await db.execute('CREATE INDEX idx_assessment_items_subcategory_id ON assessment_items(subcategory_id)');
    await db.execute('CREATE INDEX idx_assessment_items_level_id ON assessment_items(level_id)');
    await db.execute('CREATE INDEX idx_assessment_items_activity_date ON assessment_items(activity_date)');
    await db.execute('CREATE INDEX idx_subcategories_category_id ON subcategories(category_id)');
    await db.execute('CREATE INDEX idx_categories_scheme_id ON categories(scheme_id)');

    await _insertDefaultClassificationScheme(db);
    await _insertDefaultLevels(db);
    await _insertDefaultTags(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE categories ADD COLUMN code TEXT NOT NULL DEFAULT ""');
      
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

      await db.execute('''
        CREATE TABLE levels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          code TEXT,
          description TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('ALTER TABLE assessment_items ADD COLUMN subcategory_id INTEGER');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN level_id INTEGER');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN is_awarded INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN award_level TEXT');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN is_collective INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN is_leader INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN participant_count INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE assessment_items ADD COLUMN remarks TEXT');
      
      await db.execute('''
        CREATE TABLE assessment_item_tags (
          assessment_item_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (assessment_item_id, tag_id),
          FOREIGN KEY (assessment_item_id) REFERENCES assessment_items (id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_assessment_items_subcategory_id ON assessment_items(subcategory_id)');
      await db.execute('CREATE INDEX idx_assessment_items_level_id ON assessment_items(level_id)');
      await db.execute('CREATE INDEX idx_subcategories_category_id ON subcategories(category_id)');
      
      await db.execute('UPDATE categories SET code = "01" WHERE name = "德育"');
      await db.execute('UPDATE categories SET code = "02" WHERE name = "智育"');
      await db.execute('UPDATE categories SET code = "03" WHERE name = "体育锻炼"');
      await db.execute('UPDATE categories SET code = "04" WHERE name = "学术科研与创新"');
      await db.execute('UPDATE categories SET code = "05" WHERE name = "组织管理能力"');
      await db.execute('UPDATE categories SET code = "06" WHERE name = "劳动实践"');
      await db.execute('UPDATE categories SET code = "07" WHERE name = "美育素养"');
      
      await _insertDefaultSubcategories(db);
      await _insertDefaultLevels(db);
      await _insertDefaultTags(db);
    }
    
    if (oldVersion < 3) {
      await db.delete('assessment_item_tags', where: 'tag_id IN (SELECT id FROM tags WHERE code IN ("AWARDED", "COLLECTIVE"))');
      await db.delete('tags', where: 'code IN ("AWARDED", "COLLECTIVE")');
    }
    
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE file_attachments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assessment_item_id INTEGER NOT NULL,
          file_name TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          mime_type TEXT,
          uploaded_at INTEGER NOT NULL,
          FOREIGN KEY (assessment_item_id) REFERENCES assessment_items (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX idx_file_attachments_assessment_item_id ON file_attachments(assessment_item_id)');
      await db.execute('CREATE INDEX idx_file_attachments_file_type ON file_attachments(file_type)');
    }
    
    if (oldVersion < 5) {
      await db.delete('subcategories');
      
      await db.execute('UPDATE categories SET code = "DY", description = "包括思想政治、学习态度、道德品质、法纪观念、集体意识、生活修养等方面的评价，以及相关奖励与处罚" WHERE name = "德育"');
      await db.execute('UPDATE categories SET code = "ZY", description = "主要考察学生专业学习成绩和人文素质培养情况" WHERE name = "智育"');
      await db.execute('UPDATE categories SET name = "体质健康与锻炼", code = "TY", description = "考察学生日常体育锻炼、体质健康测试以及参与各级体育活动的表现" WHERE code = "03" OR name = "体育锻炼"');
      await db.execute('UPDATE categories SET code = "XS", description = "考察学生的学术探究兴趣、科研创新能力，包括参与竞赛、项目、发表论文、获得专利等" WHERE name = "学术科研与创新"');
      await db.execute('UPDATE categories SET code = "ZZ", description = "考察学生担任学生干部、参与组织管理工作的情况及业绩表现" WHERE name = "组织管理能力"');
      await db.execute('UPDATE categories SET code = "LD", description = "考察学生的劳动观念、技能、社会实践、志愿服务、实习创业等实践活动的参与情况与成果" WHERE name = "劳动实践"');
      await db.execute('UPDATE categories SET code = "MY", description = "考察学生参与文化艺术活动、培养艺术特长、发表文艺作品等方面的素养与成果" WHERE name = "美育素养"');
      
      await _insertDefaultSubcategories(db);
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE classification_schemes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          code TEXT NOT NULL UNIQUE,
          description TEXT,
          is_active INTEGER DEFAULT 0,
          is_default INTEGER DEFAULT 0,
          source TEXT DEFAULT 'manual',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('ALTER TABLE categories ADD COLUMN scheme_id INTEGER');
      await db.execute('CREATE INDEX idx_categories_scheme_id ON categories(scheme_id)');

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('classification_schemes', {
        'name': '默认分类方案',
        'code': 'DEFAULT',
        'description': '系统默认的综合测评分类方案',
        'is_active': 1,
        'is_default': 1,
        'source': 'system',
        'created_at': now,
        'updated_at': now,
      });

      final schemes = await db.query('classification_schemes', where: 'code = ?', whereArgs: ['DEFAULT']);
      if (schemes.isNotEmpty) {
        final schemeId = schemes.first['id'];
        await db.execute('UPDATE categories SET scheme_id = ?', [schemeId]);
      }
    }
  }

  Future<void> _insertDefaultClassificationScheme(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert('classification_schemes', {
      'name': '默认分类方案',
      'code': 'DEFAULT',
      'description': '系统默认的综合测评分类方案',
      'is_active': 1,
      'is_default': 1,
      'source': 'system',
      'created_at': now,
      'updated_at': now,
    });

    final schemes = await db.query('classification_schemes', where: 'code = ?', whereArgs: ['DEFAULT']);
    final schemeId = schemes.first['id'] as int?;

    final defaultCategories = [
      {
        'scheme_id': schemeId,
        'name': '德育',
        'code': 'DY',
        'description': '包括思想政治、学习态度、道德品质、法纪观念、集体意识、生活修养等方面的评价，以及相关奖励与处罚',
        'color': '#E91E63',
        'icon': 'favorite',
        'created_at': now,
      },
      {
        'scheme_id': schemeId,
        'name': '智育',
        'code': 'ZY',
        'description': '主要考察学生专业学习成绩和人文素质培养情况',
        'color': '#2196F3',
        'icon': 'school',
        'created_at': now,
      },
      {
        'scheme_id': schemeId,
        'name': '体质健康与锻炼',
        'code': 'TY',
        'description': '考察学生日常体育锻炼、体质健康测试以及参与各级体育活动的表现',
        'color': '#4CAF50',
        'icon': 'sports',
        'created_at': now,
      },
      {
        'scheme_id': schemeId,
        'name': '学术科研与创新',
        'code': 'XS',
        'description': '考察学生的学术探究兴趣、科研创新能力，包括参与竞赛、项目、发表论文、获得专利等',
        'color': '#9C27B0',
        'icon': 'lightbulb',
        'created_at': now,
      },
      {
        'scheme_id': schemeId,
        'name': '组织管理能力',
        'code': 'ZZ',
        'description': '考察学生担任学生干部、参与组织管理工作的情况及业绩表现',
        'color': '#FF5722',
        'icon': 'management',
        'created_at': now,
      },
      {
        'scheme_id': schemeId,
        'name': '劳动实践',
        'code': 'LD',
        'description': '考察学生的劳动观念、技能、社会实践、志愿服务、实习创业等实践活动的参与情况与成果',
        'color': '#FF9800',
        'icon': 'volunteer_activism',
        'created_at': now,
      },
      {
        'scheme_id': schemeId,
        'name': '美育素养',
        'code': 'MY',
        'description': '考察学生参与文化艺术活动、培养艺术特长、发表文艺作品等方面的素养与成果',
        'color': '#607D8B',
        'icon': 'palette',
        'created_at': now,
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }

    await _insertDefaultSubcategoriesWithScheme(db, schemeId);
  }

  Future<void> _insertDefaultSubcategoriesWithScheme(Database db, int? schemeId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final categories = await db.query(
      'categories',
      where: schemeId != null ? 'scheme_id = ?' : 'scheme_id IS NULL',
      whereArgs: schemeId != null ? [schemeId] : null,
    );
    final Map<String, int> categoryIdMap = {};
    for (final cat in categories) {
      categoryIdMap[cat['code'] as String] = cat['id'] as int;
    }

    final defaultSubcategories = [
      if (categoryIdMap.containsKey('DY')) ...[
        {'category_id': categoryIdMap['DY'], 'name': '思想政治', 'code': 'DY01', 'description': '思想政治表现评价', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '学习态度', 'code': 'DY02', 'description': '学习态度评价', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '道德品质', 'code': 'DY03', 'description': '道德品质评价', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '法纪观念', 'code': 'DY04', 'description': '法纪观念评价', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '集体意识', 'code': 'DY05', 'description': '集体意识评价', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '生活修养', 'code': 'DY06', 'description': '生活修养评价', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '德育奖励', 'code': 'DY07', 'description': '德育相关奖励加分', 'created_at': now},
        {'category_id': categoryIdMap['DY'], 'name': '德育处罚', 'code': 'DY08', 'description': '德育相关处罚减分', 'created_at': now},
      ],
      if (categoryIdMap.containsKey('ZY')) ...[
        {'category_id': categoryIdMap['ZY'], 'name': '学习成绩', 'code': 'ZY01', 'description': '专业学习成绩', 'created_at': now},
        {'category_id': categoryIdMap['ZY'], 'name': '人文素质培养', 'code': 'ZY02', 'description': '人文素质培养情况', 'created_at': now},
      ],
      if (categoryIdMap.containsKey('TY')) ...[
        {'category_id': categoryIdMap['TY'], 'name': '日常体育锻炼', 'code': 'TY01', 'description': '日常体育锻炼参与情况', 'created_at': now},
        {'category_id': categoryIdMap['TY'], 'name': '体质健康测试', 'code': 'TY02', 'description': '体质健康测试成绩', 'created_at': now},
        {'category_id': categoryIdMap['TY'], 'name': '体育活动参与与获奖', 'code': 'TY03', 'description': '参与各级体育活动及获奖情况', 'created_at': now},
      ],
      if (categoryIdMap.containsKey('XS')) ...[
        {'category_id': categoryIdMap['XS'], 'name': '基本科研素养', 'code': 'XS01', 'description': '基本科研素养评价', 'created_at': now},
        {'category_id': categoryIdMap['XS'], 'name': '学科竞赛', 'code': 'XS02', 'description': '参与学科竞赛及获奖', 'created_at': now},
        {'category_id': categoryIdMap['XS'], 'name': '科研与创新创业项目', 'code': 'XS03', 'description': '科研项目、大创项目等', 'created_at': now},
        {'category_id': categoryIdMap['XS'], 'name': '发表学术文章', 'code': 'XS04', 'description': '学术论文发表', 'created_at': now},
        {'category_id': categoryIdMap['XS'], 'name': '学术科研类荣誉称号', 'code': 'XS05', 'description': '学术科研相关荣誉称号', 'created_at': now},
      ],
      if (categoryIdMap.containsKey('ZZ')) ...[
        {'category_id': categoryIdMap['ZZ'], 'name': '基本职责履行', 'code': 'ZZ01', 'description': '学生干部基本职责履行', 'created_at': now},
        {'category_id': categoryIdMap['ZZ'], 'name': '业绩能力考核', 'code': 'ZZ02', 'description': '工作业绩能力考核', 'created_at': now},
        {'category_id': categoryIdMap['ZZ'], 'name': '组织管理类荣誉称号', 'code': 'ZZ03', 'description': '优秀干部等荣誉称号', 'created_at': now},
      ],
      if (categoryIdMap.containsKey('LD')) ...[
        {'category_id': categoryIdMap['LD'], 'name': '基本劳动与实践素养', 'code': 'LD01', 'description': '基本劳动与实践素养', 'created_at': now},
        {'category_id': categoryIdMap['LD'], 'name': '社会实践报告与团队项目', 'code': 'LD02', 'description': '社会实践、团队项目', 'created_at': now},
        {'category_id': categoryIdMap['LD'], 'name': '志愿服务', 'code': 'LD03', 'description': '志愿服务参与情况', 'created_at': now},
        {'category_id': categoryIdMap['LD'], 'name': '实习与创业实践', 'code': 'LD04', 'description': '实习、创业实践', 'created_at': now},
        {'category_id': categoryIdMap['LD'], 'name': '实践类先进个人', 'code': 'LD05', 'description': '实践类先进个人荣誉', 'created_at': now},
        {'category_id': categoryIdMap['LD'], 'name': '劳动教育活动', 'code': 'LD06', 'description': '劳动教育活动参与', 'created_at': now},
      ],
      if (categoryIdMap.containsKey('MY')) ...[
        {'category_id': categoryIdMap['MY'], 'name': '基本文化艺术素养', 'code': 'MY01', 'description': '基本文化艺术素养', 'created_at': now},
        {'category_id': categoryIdMap['MY'], 'name': '文化艺术类竞赛', 'code': 'MY02', 'description': '文化艺术类竞赛参与及获奖', 'created_at': now},
        {'category_id': categoryIdMap['MY'], 'name': '发表文艺作品', 'code': 'MY03', 'description': '文艺作品发表', 'created_at': now},
      ],
    ];

    for (final subcategory in defaultSubcategories) {
      await db.insert('subcategories', subcategory);
    }
  }

  Future<void> _insertDefaultSubcategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultSubcategories = [
      {'category_id': 1, 'name': '思想政治', 'code': 'DY01', 'description': '思想政治表现评价', 'created_at': now},
      {'category_id': 1, 'name': '学习态度', 'code': 'DY02', 'description': '学习态度评价', 'created_at': now},
      {'category_id': 1, 'name': '道德品质', 'code': 'DY03', 'description': '道德品质评价', 'created_at': now},
      {'category_id': 1, 'name': '法纪观念', 'code': 'DY04', 'description': '法纪观念评价', 'created_at': now},
      {'category_id': 1, 'name': '集体意识', 'code': 'DY05', 'description': '集体意识评价', 'created_at': now},
      {'category_id': 1, 'name': '生活修养', 'code': 'DY06', 'description': '生活修养评价', 'created_at': now},
      {'category_id': 1, 'name': '德育奖励', 'code': 'DY07', 'description': '德育相关奖励加分', 'created_at': now},
      {'category_id': 1, 'name': '德育处罚', 'code': 'DY08', 'description': '德育相关处罚减分', 'created_at': now},
      
      {'category_id': 2, 'name': '学习成绩', 'code': 'ZY01', 'description': '专业学习成绩', 'created_at': now},
      {'category_id': 2, 'name': '人文素质培养', 'code': 'ZY02', 'description': '人文素质培养情况', 'created_at': now},
      
      {'category_id': 3, 'name': '日常体育锻炼', 'code': 'TY01', 'description': '日常体育锻炼参与情况', 'created_at': now},
      {'category_id': 3, 'name': '体质健康测试', 'code': 'TY02', 'description': '体质健康测试成绩', 'created_at': now},
      {'category_id': 3, 'name': '体育活动参与与获奖', 'code': 'TY03', 'description': '参与各级体育活动及获奖情况', 'created_at': now},
      
      {'category_id': 4, 'name': '基本科研素养', 'code': 'XS01', 'description': '基本科研素养评价', 'created_at': now},
      {'category_id': 4, 'name': '学科竞赛', 'code': 'XS02', 'description': '参与学科竞赛及获奖', 'created_at': now},
      {'category_id': 4, 'name': '科研与创新创业项目', 'code': 'XS03', 'description': '科研项目、大创项目等', 'created_at': now},
      {'category_id': 4, 'name': '发表学术文章', 'code': 'XS04', 'description': '学术论文发表', 'created_at': now},
      {'category_id': 4, 'name': '学术科研类荣誉称号', 'code': 'XS05', 'description': '学术科研相关荣誉称号', 'created_at': now},
      
      {'category_id': 5, 'name': '基本职责履行', 'code': 'ZZ01', 'description': '学生干部基本职责履行', 'created_at': now},
      {'category_id': 5, 'name': '业绩能力考核', 'code': 'ZZ02', 'description': '工作业绩能力考核', 'created_at': now},
      {'category_id': 5, 'name': '组织管理类荣誉称号', 'code': 'ZZ03', 'description': '优秀干部等荣誉称号', 'created_at': now},
      
      {'category_id': 6, 'name': '基本劳动与实践素养', 'code': 'LD01', 'description': '基本劳动与实践素养', 'created_at': now},
      {'category_id': 6, 'name': '社会实践报告与团队项目', 'code': 'LD02', 'description': '社会实践、团队项目', 'created_at': now},
      {'category_id': 6, 'name': '志愿服务', 'code': 'LD03', 'description': '志愿服务参与情况', 'created_at': now},
      {'category_id': 6, 'name': '实习与创业实践', 'code': 'LD04', 'description': '实习、创业实践', 'created_at': now},
      {'category_id': 6, 'name': '实践类先进个人', 'code': 'LD05', 'description': '实践类先进个人荣誉', 'created_at': now},
      {'category_id': 6, 'name': '劳动教育活动', 'code': 'LD06', 'description': '劳动教育活动参与', 'created_at': now},
      
      {'category_id': 7, 'name': '基本文化艺术素养', 'code': 'MY01', 'description': '基本文化艺术素养', 'created_at': now},
      {'category_id': 7, 'name': '文化艺术类竞赛', 'code': 'MY02', 'description': '文化艺术类竞赛参与及获奖', 'created_at': now},
      {'category_id': 7, 'name': '发表文艺作品', 'code': 'MY03', 'description': '文艺作品发表', 'created_at': now},
    ];

    for (final subcategory in defaultSubcategories) {
      await db.insert('subcategories', subcategory);
    }
  }

  Future<void> _insertDefaultLevels(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultLevels = [
      {'name': '国家级', 'code': 'NATIONAL', 'description': '全国大学生数学建模竞赛一等奖', 'created_at': now},
      {'name': '省部级', 'code': 'PROVINCIAL', 'description': '省级学术比赛、部委主办的活动', 'created_at': now},
      {'name': '市级/地区级', 'code': 'CITY', 'description': '北京市级活动、跨校区域性比赛', 'created_at': now},
      {'name': '校级', 'code': 'UNIVERSITY', 'description': '中央财经大学主办的活动、校级竞赛', 'created_at': now},
      {'name': '院级', 'code': 'COLLEGE', 'description': '统计与数学学院主办活动', 'created_at': now},
      {'name': '其他', 'code': 'OTHER', 'description': '未明确级别，需人工核定', 'created_at': now},
    ];

    for (final level in defaultLevels) {
      await db.insert('levels', level);
    }
  }

  Future<void> _insertDefaultTags(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultTags = [
      {'name': '竞赛', 'code': 'COMPETITION', 'description': '各类竞赛活动', 'created_at': now},
      {'name': '项目', 'code': 'PROJECT', 'description': '各类项目参与', 'created_at': now},
      {'name': '志愿服务', 'code': 'VOLUNTEER', 'description': '志愿服务活动', 'created_at': now},
      {'name': '学生工作', 'code': 'STUDENT_WORK', 'description': '学生干部工作', 'created_at': now},
      {'name': '科研', 'code': 'RESEARCH', 'description': '科研活动', 'created_at': now},
    ];

    for (final tag in defaultTags) {
      await db.insert('tags', tag);
    }
  }
}
