import 'package:flutter_test/flutter_test.dart';
import 'package:stepup_app/services/database_helper.dart';
import 'package:stepup_app/services/category_dao.dart';
import 'package:stepup_app/services/assessment_item_dao.dart';
import 'package:stepup_app/models/category.dart';
import 'package:stepup_app/models/assessment_item.dart';

void main() {
  group('Database Tests', () {
    late DatabaseHelper dbHelper;
    late CategoryDao categoryDao;
    late AssessmentItemDao assessmentItemDao;

    setUpAll(() async {
      dbHelper = DatabaseHelper();
      categoryDao = CategoryDao();
      assessmentItemDao = AssessmentItemDao();
    });

    tearDownAll(() async {
      await dbHelper.deleteDatabase();
    });

    test('Database initialization should create default categories', () async {
      final categories = await categoryDao.getAllCategories();
      expect(categories.length, greaterThan(0));
      
      // 验证默认分类是否存在
      final categoryNames = categories.map((c) => c.name).toList();
      expect(categoryNames, contains('学术科研'));
      expect(categoryNames, contains('社会实践'));
      expect(categoryNames, contains('文体活动'));
    });

    test('Category operations should work correctly', () async {
      // 测试添加分类
      final newCategory = Category(
        name: '测试分类',
        code: 'TEST',
        description: '这是一个测试分类',
        color: '#FF5722',
        icon: 'test',
        createdAt: DateTime.now(),
      );

      final categoryId = await categoryDao.insertCategory(newCategory);
      expect(categoryId, greaterThan(0));

      // 测试获取分类
      final savedCategory = await categoryDao.getCategoryById(categoryId);
      expect(savedCategory, isNotNull);
      expect(savedCategory!.name, equals('测试分类'));
      expect(savedCategory.description, equals('这是一个测试分类'));
    });

    test('Assessment item operations should work correctly', () async {
      // 首先获取一个分类
      final categories = await categoryDao.getAllCategories();
      expect(categories.length, greaterThan(0));
      
      final category = categories.first;

      // 测试添加综测条目
      final newItem = AssessmentItem(
        title: '测试活动',
        description: '这是一个测试活动',
        categoryId: category.id!,
        duration: 2.0,
        activityDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final itemId = await assessmentItemDao.insertItem(newItem);
      expect(itemId, greaterThan(0));

      // 测试获取条目
      final savedItem = await assessmentItemDao.getItemById(itemId);
      expect(savedItem, isNotNull);
      expect(savedItem!.title, equals('测试活动'));
      expect(savedItem.duration, equals(2.0));
    });

    test('Statistics should work correctly', () async {
      // 获取统计数据
      final stats = await assessmentItemDao.getStatistics();
      
      expect(stats, isNotNull);
      expect(stats['totalCount'], isA<int>());
      expect(stats['totalDuration'], isA<double>());
      expect(stats['categoryStats'], isA<List>());
      
      // 验证统计数据的合理性
      expect(stats['totalCount'], greaterThanOrEqualTo(0));
      expect(stats['totalDuration'], greaterThanOrEqualTo(0.0));
    });

    test('Search functionality should work correctly', () async {
      // 添加一个可搜索的条目
      final categories = await categoryDao.getAllCategories();
      final category = categories.first;

      final searchableItem = AssessmentItem(
        title: '可搜索的特殊活动',
        description: '这个活动包含特殊关键词',
        categoryId: category.id!,
        duration: 1.0,
        activityDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await assessmentItemDao.insertItem(searchableItem);

      // 测试搜索功能
      final searchResults = await assessmentItemDao.searchItems('特殊');
      expect(searchResults.length, greaterThan(0));
      
      final foundItem = searchResults.firstWhere(
        (item) => item.title.contains('特殊'),
        orElse: () => throw Exception('Search item not found'),
      );
      expect(foundItem.title, contains('特殊'));
    });
  });
}