import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/assessment_item.dart';
import '../models/category.dart' as app_models;
import '../models/subcategory.dart';
import '../models/level.dart';
import '../models/tag.dart';
import '../models/user.dart';
import '../models/file_attachment.dart';
import 'assessment_item_dao.dart';
import 'category_dao.dart';
import 'subcategory_dao.dart';
import 'level_dao.dart';
import 'tag_dao.dart';
import 'user_dao.dart';
import 'file_attachment_dao.dart';
import 'database_helper.dart';
import 'event_bus.dart';
import 'file_manager.dart';

/// 数据导出进度回调
typedef ExportProgressCallback = void Function(double progress, String message);

/// 数据导入进度回调
typedef ImportProgressCallback = void Function(double progress, String message, {bool isError});

/// 数据导出服务类
/// 提供完整的数据导出与导入功能，支持备份和迁移
class DataExportService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  final LevelDao _levelDao = LevelDao();
  final TagDao _tagDao = TagDao();
  final UserDao _userDao = UserDao();
  final FileAttachmentDao _fileAttachmentDao = FileAttachmentDao();
  final EventBus _eventBus = EventBus();
  final FileManager _fileManager = FileManager();

  /// 导出所有数据到JSON文件
  /// [outputPath] 导出文件路径（可选，默认为下载目录）
  /// [includeFiles] 是否包含文件附件
  /// [progressCallback] 进度回调函数
  /// 返回导出文件的完整路径
  Future<String> exportAllData({
    String? outputPath,
    bool includeFiles = false,
    ExportProgressCallback? progressCallback,
  }) async {
    progressCallback?.call(0.0, '正在准备导出...');

    try {
      // 1. 获取所有数据
      progressCallback?.call(0.1, '正在获取用户数据...');
      final users = await _userDao.getUsers();

      progressCallback?.call(0.15, '正在获取分类数据...');
      final categories = await _categoryDao.getAllCategories();

      progressCallback?.call(0.2, '正在获取子分类数据...');
      final subcategories = await _subcategoryDao.getAllSubcategories();

      progressCallback?.call(0.25, '正在获取级别数据...');
      final levels = await _levelDao.getAllLevels();

      progressCallback?.call(0.3, '正在获取标签数据...');
      final tags = await _tagDao.getAllTags();

      progressCallback?.call(0.35, '正在获取条目数据...');
      final items = await _assessmentItemDao.getAllItems();

      // 2. 获取条目相关的附件数据
      progressCallback?.call(0.4, '正在获取附件数据...');
      final Map<int, List<FileAttachment>> attachmentsMap = {};
      if (includeFiles) {
        int processedItems = 0;
        for (final item in items) {
          if (item.id != null) {
            try {
              final attachments = await _fileAttachmentDao.getAttachmentsByItemId(item.id!);
              attachmentsMap[item.id!] = attachments;
            } catch (e) {
              debugPrint('获取条目 ${item.id} 的附件失败: $e');
              // 继续处理其他条目
            }
          }
          processedItems++;
          final progress = 0.4 + (0.2 * processedItems / (items.isNotEmpty ? items.length : 1));
          progressCallback?.call(progress, '正在获取附件数据...');
        }
      }

      // 3. 获取条目相关的标签数据
      progressCallback?.call(0.6, '正在获取条目标签关联数据...');
      final Map<int, List<Tag>> itemTagsMap = {};
      int processedItems = 0;
      for (final item in items) {
        if (item.id != null) {
          try {
            final tags = await _tagDao.getTagsByAssessmentItemId(item.id!);
            itemTagsMap[item.id!] = tags;
          } catch (e) {
            debugPrint('获取条目 ${item.id} 的标签失败: $e');
            // 继续处理其他条目
          }
        }
        processedItems++;
        final progress = 0.6 + (0.1 * processedItems / (items.isNotEmpty ? items.length : 1));
        progressCallback?.call(progress, '正在获取条目标签关联数据...');
      }

      // 4. 构建导出数据结构
      progressCallback?.call(0.7, '正在构建导出数据结构...');
      
      try {
        // 确保itemTagsMap的键是字符串而不是整数
        final sanitizedItemTagsMap = itemTagsMap.map((key, value) => 
          MapEntry(key.toString(), value.map((t) => t.id).toList())
        );
        
        // 确保 attachmentsMap 的键是字符串而不是整数
        // 并包含文件的实际内容
        final sanitizedAttachmentsMap = <String, List<Map<String, dynamic>>>{};
        final fileContentsMap = <String, String>{}; // 存储文件路径到Base64编码内容的映射
        
        if (includeFiles) {
          int processedAttachments = 0;
          int totalAttachments = 0;
          
          // 首先计算附件总数
          for (final attachments in attachmentsMap.values) {
            totalAttachments += attachments.length;
          }
          
          for (final entry in attachmentsMap.entries) {
            final itemId = entry.key;
            final attachments = entry.value;
            final attachmentMaps = <Map<String, dynamic>>[];
            
            for (final attachment in attachments) {
              try {
                // 获取原始附件数据
                final attachmentMap = attachment.toMap();
                
                // 处理DateTime字段
                attachmentMap.forEach((k, v) {
                  if (v is DateTime) {
                    attachmentMap[k] = v.toIso8601String();
                  }
                });
                
                // 读取文件内容并转为Base64
                final file = File(attachment.filePath);
                if (await file.exists()) {
                  // 读取文件内容
                  final bytes = await file.readAsBytes();
                  final base64Content = base64Encode(bytes);
                  
                  // 在映射中记录文件内容
                  final contentKey = '${attachment.id}_${path.basename(attachment.filePath)}';
                  fileContentsMap[contentKey] = base64Content;
                  
                  // 在附件元数据中添加内容的引用键
                  attachmentMap['content_key'] = contentKey;
                }
                
                attachmentMaps.add(attachmentMap);
                
                // 更新进度
                processedAttachments++;
                final subProgress = 0.7 + (0.1 * processedAttachments / (totalAttachments > 0 ? totalAttachments : 1));
                progressCallback?.call(subProgress, '正在处理附件文件...');
                
              } catch (e) {
                debugPrint('处理附件文件失败: ${attachment.fileName}, 错误: $e');
                // 继续处理其他附件
              }
            }
            
            sanitizedAttachmentsMap[itemId.toString()] = attachmentMaps;
          }
        }
        
        final exportData = {
          'metadata': {
            'exportedAt': DateTime.now().toIso8601String(),
            'version': '1.1', // 更新版本号表示包含文件内容
            'includeFiles': includeFiles,
          },
          'users': users.map((user) => user.toMap()).toList(),
          'categories': categories.map((category) => category.toMap()).toList(),
          'subcategories': subcategories.map((subcategory) => subcategory.toMap()).toList(),
          'levels': levels.map((level) => level.toMap()).toList(),
          'tags': tags.map((tag) => tag.toMap()).toList(),
          'items': items.map((item) => item.toMap()).toList(),
          'attachments': sanitizedAttachmentsMap,
          'itemTags': sanitizedItemTagsMap,
          'fileContents': fileContentsMap, // 添加文件内容映射
        };

        // 5. 创建JSON文件
        progressCallback?.call(0.8, '正在创建JSON文件...');
        final jsonString = JsonEncoder.withIndent('  ').convert(exportData);
      
        // 6. 确定输出路径
        final timestamp = DateTime.now();
        final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
        final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
      
        String userNamePart = '';
        if (users.isNotEmpty && users.first.name.isNotEmpty) {
          userNamePart = '${users.first.name}_';
        }
      
        final fileName = 'StepUp数据备份_$userNamePart${dateStr}_$timeStr.json';
        String finalOutputPath;
      
        if (outputPath != null) {
          finalOutputPath = path.join(outputPath, fileName);
        } else {
          // 默认保存到应用文档目录
          final documentsDir = await getApplicationDocumentsDirectory();
          finalOutputPath = path.join(documentsDir.path, fileName);
        }

        // 7. 写入文件
        final outputFile = File(finalOutputPath);
        await outputFile.writeAsString(jsonString, encoding: utf8);

        progressCallback?.call(1.0, '导出完成');
        return finalOutputPath;

      } catch (e) {
        debugPrint('构建导出数据结构失败: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('数据导出失败: $e');
      progressCallback?.call(0.0, '导出失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 导入数据从JSON文件
  /// [filePath] JSON文件路径
  /// [replaceExisting] 是否替换现有数据
  /// [progressCallback] 进度回调函数
  Future<void> importData({
    required String filePath,
    bool replaceExisting = false,
    ImportProgressCallback? progressCallback,
  }) async {
    progressCallback?.call(0.0, '正在准备导入...', isError: false);

    try {
      // 1. 读取JSON文件
      progressCallback?.call(0.05, '正在读取数据文件...', isError: false);
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final jsonString = await file.readAsString(encoding: utf8);
      Map<String, dynamic> importData;
      try {
        importData = json.decode(jsonString);
      } catch (e) {
        throw Exception('JSON文件格式错误: $e');
      }

      // 2. 验证数据格式
      progressCallback?.call(0.1, '正在验证数据格式...', isError: false);
      if (!importData.containsKey('metadata') || !importData.containsKey('users')) {
        throw Exception('无效的数据文件格式');
      }

      // 3. 处理替换现有数据逻辑
      if (replaceExisting) {
        progressCallback?.call(0.15, '正在清空现有数据...', isError: false);
        await _clearAllData();
      }

      // 4. 导入用户数据
      progressCallback?.call(0.2, '正在导入用户数据...', isError: false);
      if (importData.containsKey('users') && importData['users'] is List) {
        final usersData = importData['users'] as List;
        for (final userData in usersData) {
          if (userData is Map<String, dynamic>) {
            try {
              final user = User.fromMap(userData);
              // 如果是替换模式或用户不存在，则插入
              if (replaceExisting || !(await _userDao.hasUsers())) {
                // 处理ID冲突：先查询是否存在相同ID的用户
                if (user.id != null) {
                  final db = await _databaseHelper.database;
                  final existingUser = await db.query(
                    'users',
                    where: 'id = ?',
                    whereArgs: [user.id],
                  );
                  
                  if (existingUser.isNotEmpty) {
                    // 存在相同ID的用户，更新而不是插入
                    await _userDao.updateUser(user);
                    debugPrint('更新现有用户: ${user.name} (ID: ${user.id})');
                  } else {
                    // 不存在相同ID的用户，直接插入
                    await _userDao.addUser(user);
                    debugPrint('插入新用户: ${user.name} (ID: ${user.id})');
                  }
                } else {
                  // 没有指定ID，直接插入
                  await _userDao.addUser(user);
                  debugPrint('插入新用户: ${user.name}');
                }
              }
            } catch (e) {
              debugPrint('导入用户数据失败: $e');
              // 继续导入其他用户数据，但不要中断整个导入流程
              progressCallback?.call(0.2, '导入用户数据失败: ${e.toString()}', isError: true);
            }
          }
        }
      }

      // 5. 导入分类数据
      progressCallback?.call(0.25, '正在导入分类数据...', isError: false);
      if (importData.containsKey('categories') && importData['categories'] is List) {
        final categoriesData = importData['categories'] as List;
        for (final categoryData in categoriesData) {
          if (categoryData is Map<String, dynamic>) {
            try {
              final category = app_models.Category.fromMap(categoryData);
              await _categoryDao.insertCategory(category);
            } catch (e) {
              debugPrint('导入分类数据失败: $e');
              // 继续导入其他分类数据
            }
          }
        }
      }

      // 6. 导入子分类数据
      progressCallback?.call(0.3, '正在导入子分类数据...', isError: false);
      if (importData.containsKey('subcategories') && importData['subcategories'] is List) {
        final subcategoriesData = importData['subcategories'] as List;
        for (final subcategoryData in subcategoriesData) {
          if (subcategoryData is Map<String, dynamic>) {
            try {
              final subcategory = Subcategory.fromMap(subcategoryData);
              await _subcategoryDao.insertSubcategory(subcategory);
            } catch (e) {
              debugPrint('导入子分类数据失败: $e');
              // 继续导入其他子分类数据
            }
          }
        }
      }

      // 7. 导入级别数据
      progressCallback?.call(0.35, '正在导入级别数据...', isError: false);
      if (importData.containsKey('levels') && importData['levels'] is List) {
        final levelsData = importData['levels'] as List;
        for (final levelData in levelsData) {
          if (levelData is Map<String, dynamic>) {
            try {
              final level = Level.fromMap(levelData);
              await _levelDao.insertLevel(level);
            } catch (e) {
              debugPrint('导入级别数据失败: $e');
              // 继续导入其他级别数据
            }
          }
        }
      }

      // 8. 导入标签数据
      progressCallback?.call(0.4, '正在导入标签数据...', isError: false);
      if (importData.containsKey('tags') && importData['tags'] is List) {
        final tagsData = importData['tags'] as List;
        for (final tagData in tagsData) {
          if (tagData is Map<String, dynamic>) {
            try {
              final tag = Tag.fromMap(tagData);
              await _tagDao.insertTag(tag);
            } catch (e) {
              debugPrint('导入标签数据失败: $e');
              // 继续导入其他标签数据
            }
          }
        }
      }

      // 9. 导入条目数据
      progressCallback?.call(0.5, '正在导入条目数据...', isError: false);
      final Map<int, int> itemIdMap = {}; // 旧ID到新ID的映射
      if (importData.containsKey('items') && importData['items'] is List) {
        final itemsData = importData['items'] as List;
        int processedItems = 0;
        for (final itemData in itemsData) {
          if (itemData is Map<String, dynamic>) {
            try {
              final item = AssessmentItem.fromMap(itemData);
              final newId = await _assessmentItemDao.insertItem(item);
              // 记录ID映射（如果原数据有ID）
              if (itemData['id'] != null) {
                itemIdMap[itemData['id']] = newId;
              }
            } catch (e) {
              debugPrint('导入条目数据失败: $e');
              // 继续导入其他条目数据
            }
          }
          processedItems++;
          final progress = 0.5 + (0.2 * processedItems / (itemsData.isNotEmpty ? itemsData.length : 1));
          progressCallback?.call(progress, '正在导入条目数据...', isError: false);
        }
      }

      // 10. 导入附件数据
      progressCallback?.call(0.7, '正在导入附件数据...', isError: false);
      final Map<String, String> fileContentsMap = {};
      
      // 先提取文件内容映射
      if (importData.containsKey('fileContents') && importData['fileContents'] is Map) {
        final fileContents = importData['fileContents'] as Map;
        fileContents.forEach((key, value) {
          if (key is String && value is String) {
            fileContentsMap[key] = value;
          }
        });
      }
      
      if (importData.containsKey('attachments') && importData['attachments'] is Map) {
        final attachmentsData = importData['attachments'] as Map;
        int processedAttachments = 0;
        final totalAttachments = attachmentsData.length;
        
        // 创建附件存储目录
        final dataDir = await _fileManager.getAppDataPath();
        final proofDir = Directory(path.join(dataDir, 'proof_materials'));
        if (!await proofDir.exists()) {
          await proofDir.create(recursive: true);
        }
        
        for (final entry in attachmentsData.entries) {
          final oldItemIdStr = entry.key.toString();
          final attachmentsList = entry.value as List;
          
          // 将字符串键转换回整数
          final oldItemId = int.tryParse(oldItemIdStr) ?? 0;
          
          // 获取新ID
          final newItemId = itemIdMap[oldItemId] ?? oldItemId;
          
          for (final attachmentData in attachmentsList) {
            if (attachmentData is Map<String, dynamic>) {
              try {
                // 确保日期时间字段正确转换
                if (attachmentData['uploaded_at'] is String) {
                  try {
                    final dateTime = DateTime.parse(attachmentData['uploaded_at']);
                    attachmentData['uploaded_at'] = dateTime.millisecondsSinceEpoch;
                  } catch (e) {
                    debugPrint('解析上传时间失败: ${attachmentData['uploaded_at']}');
                    // 使用当前时间作为默认值
                    attachmentData['uploaded_at'] = DateTime.now().millisecondsSinceEpoch;
                  }
                }
                
                // 获取内容键并恢复文件
                final contentKey = attachmentData['content_key'] as String?;
                String? restoredFilePath;
                
                if (contentKey != null && fileContentsMap.containsKey(contentKey)) {
                  // 从 Base64 字符串恢复文件
                  final base64Content = fileContentsMap[contentKey]!;
                  final bytes = base64Decode(base64Content);
                  
                  // 使用原始文件名创建新文件
                  final fileName = attachmentData['file_name'] as String? ?? 'unknown.dat';
                  final fileExtension = path.extension(fileName);
                  final uuid = DateTime.now().millisecondsSinceEpoch.toString();
                  final newFileName = '$uuid$fileExtension';
                  final newFilePath = path.join(proofDir.path, newFileName);
                  
                  // 写入文件
                  final file = File(newFilePath);
                  await file.writeAsBytes(bytes);
                  
                  // 更新文件路径
                  restoredFilePath = newFilePath;
                  debugPrint('恢复文件: $fileName -> $newFilePath');
                }
                
                // 如果有新的文件路径，使用新路径
                if (restoredFilePath != null) {
                  attachmentData['file_path'] = restoredFilePath;
                }
                
                // 移除content_key字段，不存储到数据库
                attachmentData.remove('content_key');
                
                final attachment = FileAttachment.fromMap(attachmentData);
                // 更新关联的条目ID
                final updatedAttachment = attachment.copyWith(assessmentItemId: newItemId);
                await _fileAttachmentDao.insertAttachment(updatedAttachment);
              } catch (e) {
                debugPrint('导入附件数据失败: $e');
                // 继续导入其他附件数据
              }
            }
          }
          
          processedAttachments++;
          final progress = 0.7 + (0.15 * processedAttachments / (totalAttachments > 0 ? totalAttachments : 1));
          progressCallback?.call(progress, '正在导入附件数据...', isError: false);
        }
      }

      // 11. 导入条目标签关联数据
      progressCallback?.call(0.85, '正在导入条目标签关联数据...', isError: false);
      if (importData.containsKey('itemTags') && importData['itemTags'] is Map) {
        final itemTagsData = importData['itemTags'] as Map;
        int processedItems = 0;
        final totalItems = itemTagsData.length;
        for (final entry in itemTagsData.entries) {
          final oldItemIdStr = entry.key.toString();
          final tagIds = entry.value as List;
          
          // 将字符串键转换回整数
          final oldItemId = int.tryParse(oldItemIdStr) ?? 0;
          
          // 获取新ID
          final newItemId = itemIdMap[oldItemId] ?? oldItemId;
          
          try {
            // 设置条目的标签
            final intTagIds = tagIds.whereType<int>().toList();
            await _tagDao.setTagsForAssessmentItem(newItemId, intTagIds);
          } catch (e) {
            debugPrint('导入条目标签关联数据失败: $e');
            // 继续导入其他条目标签关联数据
          }
          
          processedItems++;
          final progress = 0.85 + (0.15 * processedItems / (totalItems > 0 ? totalItems : 1));
          progressCallback?.call(progress, '正在导入条目标签关联数据...', isError: false);
        }
      }

      progressCallback?.call(1.0, '导入完成', isError: false);
      
      // 触发数据变更事件，通知首页和综测页面刷新
      _eventBus.emit(AppEvent.assessmentItemChanged);
    } catch (e) {
      debugPrint('数据导入失败: $e');
      progressCallback?.call(0.0, '导入失败: ${e.toString()}', isError: true);
      rethrow;
    }
  }

  /// 清空所有数据（用于替换导入）
  Future<void> _clearAllData() async {
    final db = await _databaseHelper.database;
    
    // 按依赖关系顺序删除数据
    await db.delete('assessment_item_tags');
    await db.delete('file_attachments');
    await db.delete('assessment_items');
    await db.delete('subcategories');
    await db.delete('levels');
    await db.delete('tags');
    await db.delete('categories');
    // 注意：保留用户数据，除非明确指定要删除
  }

  /// 获取导出统计信息
  Future<Map<String, int>> getExportStatistics() async {
    final users = await _userDao.getUsers();
    final categories = await _categoryDao.getAllCategories();
    final subcategories = await _subcategoryDao.getAllSubcategories();
    final levels = await _levelDao.getAllLevels();
    final tags = await _tagDao.getAllTags();
    final items = await _assessmentItemDao.getAllItems();
    final attachments = await _getAllAttachments();

    return {
      'users': users.length,
      'categories': categories.length,
      'subcategories': subcategories.length,
      'levels': levels.length,
      'tags': tags.length,
      'items': items.length,
      'attachments': attachments.length,
    };
  }

  /// 获取所有附件（用于统计）
  Future<List<FileAttachment>> _getAllAttachments() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('file_attachments');
    return List.generate(maps.length, (i) => FileAttachment.fromMap(maps[i]));
  }
}