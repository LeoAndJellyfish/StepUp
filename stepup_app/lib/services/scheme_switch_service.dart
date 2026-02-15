import '../models/category.dart';
import '../services/classification_scheme_dao.dart';
import '../services/category_dao.dart';
import '../services/database_helper.dart';

class CategoryMapping {
  final int oldCategoryId;
  final int? newCategoryId;
  final String oldCategoryName;
  final String? newCategoryName;
  final int itemCount;
  final MappingStatus status;
  final String? reason;

  const CategoryMapping({
    required this.oldCategoryId,
    this.newCategoryId,
    required this.oldCategoryName,
    this.newCategoryName,
    required this.itemCount,
    required this.status,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldCategoryId': oldCategoryId,
      'newCategoryId': newCategoryId,
      'oldCategoryName': oldCategoryName,
      'newCategoryName': newCategoryName,
      'itemCount': itemCount,
      'status': status.name,
      'reason': reason,
    };
  }
}

enum MappingStatus {
  matched,
  partial,
  unmatched,
  manual,
}

class SchemeMigrationResult {
  final bool success;
  final int totalItems;
  final int migratedItems;
  final int unmatchedItems;
  final List<CategoryMapping> mappings;
  final String? error;

  const SchemeMigrationResult({
    required this.success,
    this.totalItems = 0,
    this.migratedItems = 0,
    this.unmatchedItems = 0,
    this.mappings = const [],
    this.error,
  });
}

class SchemeSwitchService {
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();
  final CategoryDao _categoryDao = CategoryDao();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<CategoryMapping>> analyzeMigration(int targetSchemeId) async {
    final activeScheme = await _schemeDao.getActiveScheme();
    if (activeScheme == null) {
      return [];
    }

    final oldCategories = await _categoryDao.getCategoriesBySchemeId(activeScheme.id!);
    final newCategories = await _categoryDao.getCategoriesBySchemeId(targetSchemeId);

    final List<CategoryMapping> mappings = [];

    for (final oldCategory in oldCategories) {
      final itemCount = await _getItemCountForCategory(oldCategory.id!);
      if (itemCount == 0) continue;

      Category? matchedCategory;
      MappingStatus status = MappingStatus.unmatched;
      String? reason;

      matchedCategory = newCategories.where((c) => c.code == oldCategory.code).firstOrNull;
      if (matchedCategory != null) {
        status = MappingStatus.matched;
        reason = '代码匹配';
      }

      if (matchedCategory == null) {
        matchedCategory = newCategories.where((c) => c.name == oldCategory.name).firstOrNull;
        if (matchedCategory != null) {
          status = MappingStatus.matched;
          reason = '名称匹配';
        }
      }

      if (matchedCategory == null) {
        matchedCategory = _findSimilarCategory(oldCategory, newCategories);
        if (matchedCategory != null) {
          status = MappingStatus.partial;
          reason = '相似匹配';
        }
      }

      mappings.add(CategoryMapping(
        oldCategoryId: oldCategory.id!,
        newCategoryId: matchedCategory?.id,
        oldCategoryName: oldCategory.name,
        newCategoryName: matchedCategory?.name,
        itemCount: itemCount,
        status: matchedCategory != null ? status : MappingStatus.unmatched,
        reason: reason,
      ));
    }

    return mappings;
  }

  Category? _findSimilarCategory(Category oldCategory, List<Category> newCategories) {
    final oldKeywords = _extractKeywords(oldCategory.name);
    
    Category? bestMatch;
    double bestScore = 0.0;

    for (final newCategory in newCategories) {
      final newKeywords = _extractKeywords(newCategory.name);
      final score = _calculateSimilarity(oldKeywords, newKeywords);
      
      if (score > bestScore && score > 0.5) {
        bestScore = score;
        bestMatch = newCategory;
      }
    }

    return bestMatch;
  }

  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1)
        .toList();
  }

  double _calculateSimilarity(List<String> list1, List<String> list2) {
    if (list1.isEmpty || list2.isEmpty) return 0.0;
    
    final set1 = list1.toSet();
    final set2 = list2.toSet();
    
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  Future<int> _getItemCountForCategory(int categoryId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assessment_items WHERE category_id = ?',
      [categoryId],
    );
    return result.first['count'] as int;
  }

  Future<SchemeMigrationResult> migrateItems(
    int targetSchemeId, {
    Map<int, int>? manualMappings,
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      final activeScheme = await _schemeDao.getActiveScheme();
      if (activeScheme == null) {
        return const SchemeMigrationResult(
          success: false,
          error: '没有当前激活的方案',
        );
      }

      if (activeScheme.id == targetSchemeId) {
        return const SchemeMigrationResult(
          success: false,
          error: '目标方案与当前方案相同',
        );
      }

      final mappings = await analyzeMigration(targetSchemeId);
      if (manualMappings != null) {
        for (final mapping in mappings) {
          if (manualMappings.containsKey(mapping.oldCategoryId)) {
            final newCategoryId = manualMappings[mapping.oldCategoryId]!;
            final newCategory = await _categoryDao.getCategoryById(newCategoryId);
            final index = mappings.indexOf(mapping);
            mappings[index] = CategoryMapping(
              oldCategoryId: mapping.oldCategoryId,
              newCategoryId: newCategoryId,
              oldCategoryName: mapping.oldCategoryName,
              newCategoryName: newCategory?.name,
              itemCount: mapping.itemCount,
              status: MappingStatus.manual,
              reason: '手动指定',
            );
          }
        }
      }

      final db = await _databaseHelper.database;
      int totalItems = 0;
      int migratedItems = 0;
      int unmatchedItems = 0;

      for (final mapping in mappings) {
        totalItems += mapping.itemCount;
      }

      int processedItems = 0;
      for (final mapping in mappings) {
        if (mapping.newCategoryId != null) {
          await db.update(
            'assessment_items',
            {'category_id': mapping.newCategoryId},
            where: 'category_id = ?',
            whereArgs: [mapping.oldCategoryId],
          );
          migratedItems += mapping.itemCount;
        } else {
          unmatchedItems += mapping.itemCount;
        }

        processedItems += mapping.itemCount;
        onProgress?.call(
          processedItems / totalItems,
          '正在迁移 ${mapping.oldCategoryName}...',
        );
      }

      await _schemeDao.setActiveScheme(targetSchemeId);

      return SchemeMigrationResult(
        success: true,
        totalItems: totalItems,
        migratedItems: migratedItems,
        unmatchedItems: unmatchedItems,
        mappings: mappings,
      );
    } catch (e) {
      return SchemeMigrationResult(
        success: false,
        error: '迁移失败: $e',
      );
    }
  }

  Future<Map<String, dynamic>> exportMigrationPlan(int targetSchemeId) async {
    final mappings = await analyzeMigration(targetSchemeId);
    final activeScheme = await _schemeDao.getActiveScheme();
    final targetScheme = await _schemeDao.getSchemeById(targetSchemeId);

    return {
      'sourceScheme': {
        'id': activeScheme?.id,
        'name': activeScheme?.name,
        'code': activeScheme?.code,
      },
      'targetScheme': {
        'id': targetScheme?.id,
        'name': targetScheme?.name,
        'code': targetScheme?.code,
      },
      'mappings': mappings.map((m) => m.toJson()).toList(),
      'summary': {
        'totalCategories': mappings.length,
        'matchedCategories': mappings.where((m) => m.status == MappingStatus.matched).length,
        'partialCategories': mappings.where((m) => m.status == MappingStatus.partial).length,
        'unmatchedCategories': mappings.where((m) => m.status == MappingStatus.unmatched).length,
        'totalItems': mappings.fold(0, (sum, m) => sum + m.itemCount),
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
