import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import '../models/assessment_item.dart';
import '../models/file_attachment.dart';
import '../models/category.dart' as app_models;
import '../models/subcategory.dart';
import 'assessment_item_dao.dart';
import 'file_attachment_dao.dart';
import 'category_dao.dart';
import 'subcategory_dao.dart';

/// 证明材料导出进度回调
typedef ExportProgressCallback = void Function(double progress, String message);

/// 证明材料导出服务类
/// 提供将所有条目的证明材料按照条目名称重命名并打包导出的功能
class ProofMaterialsExportService {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final FileAttachmentDao _fileAttachmentDao = FileAttachmentDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();

  /// 导出所有条目的证明材料
  /// [outputPath] 导出文件路径（可选，默认为下载目录）
  /// [progressCallback] 进度回调函数
  /// 返回导出文件的完整路径
  Future<String> exportAllProofMaterials({
    String? outputPath,
    ExportProgressCallback? progressCallback,
  }) async {
    progressCallback?.call(0.0, '正在准备导出...');

    try {
      // 1. 获取所有条目
      progressCallback?.call(0.1, '正在获取条目数据...');
      final items = await _assessmentItemDao.getAllItems();
      
      if (items.isEmpty) {
        throw Exception('没有找到任何条目');
      }

      // 2. 获取分类信息
      progressCallback?.call(0.2, '正在获取分类信息...');
      final categories = await _categoryDao.getAllCategories();
      final subcategories = await _subcategoryDao.getAllSubcategories();

      // 3. 创建临时目录用于整理文件
      progressCallback?.call(0.3, '正在创建工作目录...');
      final tempDir = await Directory.systemTemp.createTemp('stepup_export_');
      
      try {
        // 4. 整理文件到临时目录
        await _organizeFilesToTempDirectory(
          items, 
          categories, 
          subcategories, 
          tempDir,
          progressCallback,
        );

        // 5. 创建ZIP文件
        progressCallback?.call(0.8, '正在创建压缩包...');
        final outputFilePath = await _createZipFile(tempDir, outputPath);

        progressCallback?.call(1.0, '导出完成');
        return outputFilePath;

      } finally {
        // 清理临时目录
        try {
          await tempDir.delete(recursive: true);
        } catch (e) {
          debugPrint('清理临时目录失败: $e');
        }
      }

    } catch (e) {
      progressCallback?.call(0.0, '导出失败: $e');
      rethrow;
    }
  }

  /// 整理文件到临时目录
  Future<void> _organizeFilesToTempDirectory(
    List<AssessmentItem> items,
    List<app_models.Category> categories,
    List<Subcategory> subcategories,
    Directory tempDir,
    ExportProgressCallback? progressCallback,
  ) async {
    int processedItems = 0;
    int totalItems = items.length;
    
    for (final item in items) {
      try {
        // 获取条目的文件附件
        final attachments = await _fileAttachmentDao.getAttachmentsByItemId(item.id!);
        
        if (attachments.isEmpty) {
          // 检查旧版本的imagePath和filePath字段
          if (item.imagePath == null && item.filePath == null) {
            processedItems++;
            continue;
          }
        }

        // 创建条目专用目录
        final itemDirName = _sanitizeFileName(item.title);
        final itemDir = Directory(path.join(tempDir.path, itemDirName));
        await itemDir.create(recursive: true);

        // 复制附件文件
        await _copyAttachmentsToItemDirectory(item, attachments, itemDir);

        // 创建条目信息文件
        await _createItemInfoFile(item, categories, subcategories, itemDir);

      } catch (e) {
        debugPrint('处理条目 ${item.title} 时出错: $e');
      }

      processedItems++;
      final progress = 0.3 + (0.5 * processedItems / totalItems);
      progressCallback?.call(progress, '正在处理条目: ${item.title}');
    }
  }

  /// 复制附件到条目目录
  Future<void> _copyAttachmentsToItemDirectory(
    AssessmentItem item,
    List<FileAttachment> attachments,
    Directory itemDir,
  ) async {
    int fileIndex = 1;

    // 处理新版本的文件附件
    for (final attachment in attachments) {
      final sourceFile = File(attachment.filePath);
      if (await sourceFile.exists()) {
        final extension = path.extension(attachment.fileName);
        final fileType = attachment.fileType == 'image' ? '图片' : '文档';
        final newFileName = '${fileType}_${fileIndex.toString().padLeft(2, '0')}$extension';
        final targetPath = path.join(itemDir.path, newFileName);
        
        await sourceFile.copy(targetPath);
        fileIndex++;
      }
    }

    // 处理旧版本的imagePath和filePath字段（兼容性处理）
    if (item.imagePath != null) {
      final imageFile = File(item.imagePath!);
      if (await imageFile.exists()) {
        final extension = path.extension(item.imagePath!);
        final fileName = '图片_${fileIndex.toString().padLeft(2, '0')}$extension';
        final targetPath = path.join(itemDir.path, fileName);
        await imageFile.copy(targetPath);
        fileIndex++;
      }
    }

    if (item.filePath != null) {
      final docFile = File(item.filePath!);
      if (await docFile.exists()) {
        final extension = path.extension(item.filePath!);
        final fileName = '文档_${fileIndex.toString().padLeft(2, '0')}$extension';
        final targetPath = path.join(itemDir.path, fileName);
        await docFile.copy(targetPath);
      }
    }
  }

  /// 创建条目信息文件
  Future<void> _createItemInfoFile(
    AssessmentItem item,
    List<app_models.Category> categories,
    List<Subcategory> subcategories,
    Directory itemDir,
  ) async {
    final category = categories.firstWhere(
      (cat) => cat.id == item.categoryId,
      orElse: () => app_models.Category(
        name: '未知分类',
        code: 'UNKNOWN',
        description: '',
        color: '#999999',
        icon: 'help',
        createdAt: DateTime.now(),
      ),
    );

    final subcategory = item.subcategoryId != null
        ? subcategories.firstWhere(
            (sub) => sub.id == item.subcategoryId,
            orElse: () => Subcategory(
              name: '未知子分类',
              code: 'UNKNOWN',
              description: '',
              categoryId: item.categoryId,
              createdAt: DateTime.now(),
            ),
          )
        : null;

    final infoContent = StringBuffer();
    infoContent.writeln('条目信息');
    infoContent.writeln('=' * 20);
    infoContent.writeln('条目名称: ${item.title}');
    infoContent.writeln('条目描述: ${item.description}');
    infoContent.writeln('主分类: ${category.name} (${category.code})');
    if (subcategory != null) {
      infoContent.writeln('子分类: ${subcategory.name} (${subcategory.code})');
    }
    infoContent.writeln('活动日期: ${_formatDate(item.activityDate)}');
    infoContent.writeln('时长: ${item.duration.toStringAsFixed(1)} 小时');
    if (item.isAwarded) {
      infoContent.writeln('获奖情况: 已获奖');
      if (item.awardLevel != null) {
        infoContent.writeln('获奖等级: ${item.awardLevel}');
      }
    } else {
      infoContent.writeln('获奖情况: 未获奖');
    }
    infoContent.writeln('是否代表集体: ${item.isCollective ? "是" : "否"}');
    infoContent.writeln('是否为负责人: ${item.isLeader ? "是" : "否"}');
    infoContent.writeln('参与人数: ${item.participantCount}');
    if (item.remarks?.isNotEmpty == true) {
      infoContent.writeln('备注: ${item.remarks}');
    }
    infoContent.writeln('创建时间: ${_formatDateTime(item.createdAt)}');
    infoContent.writeln('更新时间: ${_formatDateTime(item.updatedAt)}');

    final infoFile = File(path.join(itemDir.path, '条目信息.txt'));
    await infoFile.writeAsString(infoContent.toString(), encoding: utf8);
  }

  /// 创建ZIP文件
  Future<String> _createZipFile(Directory tempDir, String? outputPath) async {
    final timestamp = DateTime.now();
    final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
    final fileName = 'StepUp证明材料_${dateStr}_$timeStr.zip';

    String finalOutputPath;
    if (outputPath != null) {
      finalOutputPath = path.join(outputPath, fileName);
    } else {
      // 默认保存到应用文档目录
      final documentsDir = await getApplicationDocumentsDirectory();
      finalOutputPath = path.join(documentsDir.path, fileName);
    }

    // 创建归档
    final archive = Archive();

    // 递归添加目录中的所有文件
    await _addDirectoryToArchive(tempDir, archive, '');

    // 编码为ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('创建ZIP文件失败');
    }

    // 写入文件
    final outputFile = File(finalOutputPath);
    await outputFile.writeAsBytes(zipData);

    return finalOutputPath;
  }

  /// 递归添加目录到归档
  Future<void> _addDirectoryToArchive(
    Directory dir,
    Archive archive,
    String basePath,
  ) async {
    final entities = await dir.list().toList();
    
    for (final entity in entities) {
      final relativePath = basePath.isEmpty 
          ? path.basename(entity.path)
          : path.join(basePath, path.basename(entity.path));

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final file = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(file);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(entity, archive, relativePath);
      }
    }
  }

  /// 清理文件名，移除不合法字符
  String _sanitizeFileName(String fileName) {
    // 移除或替换Windows文件名中不允许的字符
    const invalidChars = r'<>:"/\|?*';
    String sanitized = fileName;
    
    for (int i = 0; i < invalidChars.length; i++) {
      sanitized = sanitized.replaceAll(invalidChars[i], '_');
    }
    
    // 移除前后空白和点号
    sanitized = sanitized.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');
    
    // 如果文件名为空或只有无效字符，使用默认名称
    if (sanitized.isEmpty) {
      sanitized = '未命名条目';
    }
    
    // 限制文件名长度
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }
    
    return sanitized;
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// 获取统计信息
  Future<Map<String, int>> getExportStatistics() async {
    final items = await _assessmentItemDao.getAllItems();
    int itemsWithProof = 0;
    int totalFiles = 0;

    for (final item in items) {
      final attachments = await _fileAttachmentDao.getAttachmentsByItemId(item.id!);
      bool hasProof = attachments.isNotEmpty;
      
      // 检查旧版本字段
      if (!hasProof && (item.imagePath != null || item.filePath != null)) {
        hasProof = true;
      }

      if (hasProof) {
        itemsWithProof++;
        totalFiles += attachments.length;
        
        // 计算旧版本文件
        if (item.imagePath != null) totalFiles++;
        if (item.filePath != null) totalFiles++;
      }
    }

    return {
      'totalItems': items.length,
      'itemsWithProof': itemsWithProof,
      'totalFiles': totalFiles,
    };
  }
}