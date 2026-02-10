import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// 文件管理服务类
/// 负责处理证明材料的存储、删除和路径管理
class FileManager {
  static final FileManager _instance = FileManager._internal();
  factory FileManager() => _instance;
  FileManager._internal();

  final Uuid _uuid = const Uuid();

  /// 获取应用数据目录
  /// 桌面端：应用所在目录的data文件夹
  /// 移动端：使用应用文档目录
  Future<Directory> get _appDataDirectory async {
    // 判断平台类型
    if (Platform.isAndroid || Platform.isIOS) {
      // 移动端：使用 path_provider 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory(path.join(appDir.path, 'app_data'));
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      return dataDir;
    } else {
      // 桌面端：在应用可执行文件目录下创建data文件夹
      final executablePath = Platform.resolvedExecutable;
      final executableDir = Directory(path.dirname(executablePath));
      final dataDir = Directory(path.join(executableDir.path, 'data'));
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      return dataDir;
    }
  }

  /// 获取证明材料存储目录（在应用data文件夹下）
  Future<Directory> get _proofMaterialsDirectory async {
    final dataDir = await _appDataDirectory;
    final proofDir = Directory(path.join(dataDir.path, 'proof_materials'));
    if (!await proofDir.exists()) {
      await proofDir.create(recursive: true);
    }
    return proofDir;
  }

  /// 获取应用数据目录路径（公共方法）
  Future<String> getAppDataPath() async {
    final dataDir = await _appDataDirectory;
    return dataDir.path;
  }

  /// 迁移现有证明材料文件从用户文档目录到应用data目录
  Future<void> migrateProofMaterials() async {
    try {
      // 获取旧的证明材料目录（用户文档目录下）
      final oldDocumentsDir = await getApplicationDocumentsDirectory();
      final oldProofDir = Directory('${oldDocumentsDir.path}/proof_materials');
      
      if (!await oldProofDir.exists()) {
        debugPrint('旧的证明材料目录不存在，无需迁移');
        return;
      }
      
      // 获取新的证明材料目录（应用data目录下）
      final newProofDir = await _proofMaterialsDirectory;
      
      // 获取旧目录中的所有文件
      final files = await oldProofDir.list().toList();
      int migratedCount = 0;
      
      for (final entity in files) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          final newFilePath = path.join(newProofDir.path, fileName);
          
          // 检查新位置是否已存在同名文件
          final newFile = File(newFilePath);
          if (!await newFile.exists()) {
            await entity.copy(newFilePath);
            migratedCount++;
            debugPrint('迁移文件: ${entity.path} -> $newFilePath');
          } else {
            debugPrint('文件已存在，跳过: $newFilePath');
          }
        }
      }
      
      debugPrint('证明材料迁移完成，共迁移 $migratedCount 个文件');
      
      // 迁移完成后，可以选择删除旧目录（保留注释以便用户手动处理）
      // if (migratedCount > 0) {
      //   await oldProofDir.delete(recursive: true);
      //   debugPrint('已删除旧的证明材料目录: ${oldProofDir.path}');
      // }
      
    } catch (e) {
      debugPrint('迁移证明材料文件失败: $e');
      // 不抛出异常，以免影响应用启动
    }
  }
  /// [sourceFilePath] 源文件路径
  /// [fileName] 可选的文件名，如果不提供则使用UUID生成
  Future<String> copyFileToAppDirectory(String sourceFilePath, {String? fileName}) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('源文件不存在: $sourceFilePath');
    }

    final proofDir = await _proofMaterialsDirectory;
    final extension = path.extension(sourceFilePath);
    final targetFileName = fileName ?? '${_uuid.v4()}$extension';
    final targetPath = path.join(proofDir.path, targetFileName);

    await sourceFile.copy(targetPath);
    return targetPath;
  }
  
  /// 复制文件并获取文件信息
  /// [sourceFilePath] 源文件路径
  /// 返回 Map 包含: filePath, fileName, fileSize, mimeType, fileType
  Future<Map<String, dynamic>> copyFileWithInfo(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('源文件不存在: $sourceFilePath');
    }

    final proofDir = await _proofMaterialsDirectory;
    final extension = path.extension(sourceFilePath);
    final originalFileName = path.basename(sourceFilePath);
    final targetFileName = '${_uuid.v4()}$extension';
    final targetPath = path.join(proofDir.path, targetFileName);

    await sourceFile.copy(targetPath);
    
    final fileSize = await sourceFile.length();
    final mimeType = getMimeType(sourceFilePath);
    final fileType = isImageFile(sourceFilePath) ? 'image' : 'document';

    return {
      'filePath': targetPath,
      'fileName': originalFileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'fileType': fileType,
    };
  }

  /// 删除文件
  /// [filePath] 要删除的文件路径
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // 检查并处理只读属性（主要针对Windows平台）
        if (Platform.isWindows) {
          await _removeReadOnlyAttribute(file);
        }
        await file.delete();
        debugPrint('文件删除成功: $filePath');
      } else {
        debugPrint('文件不存在，无需删除: $filePath');
      }
    } catch (e) {
      debugPrint('删除文件失败: $filePath, 错误: $e');
      // 尝试强制删除（移除只读属性后重试）
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await _forceDeleteFile(file);
          debugPrint('强制删除文件成功: $filePath');
        }
      } catch (retryError) {
        debugPrint('强制删除文件也失败: $filePath, 错误: $retryError');
        // 记录错误但不抛出异常，避免影响主流程
      }
    }
  }

  /// 移除文件的只读属性（Windows平台）
  Future<void> _removeReadOnlyAttribute(File file) async {
    if (!Platform.isWindows) return;
    
    try {
      // 在Windows上，我们使用Process来执行attrib命令移除只读属性
      final result = await Process.run(
        'attrib',
        ['-R', file.path],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        debugPrint('移除只读属性失败: ${result.stderr}');
      } else {
        debugPrint('成功移除只读属性: ${file.path}');
      }
    } catch (e) {
      debugPrint('移除只读属性时出错: $e');
    }
  }

  /// 强制删除文件（处理权限问题）
  Future<void> _forceDeleteFile(File file) async {
    try {
      // 先尝试移除只读属性
      if (Platform.isWindows) {
        await _removeReadOnlyAttribute(file);
        
        // 等待一小段时间让系统更新文件属性
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // 再次尝试删除
      await file.delete();
    } catch (e) {
      // 如果还是失败，尝试使用系统命令删除
      if (Platform.isWindows) {
        final result = await Process.run(
          'del',
          ['/F', '/Q', file.path],
          runInShell: true,
        );
        
        if (result.exitCode != 0) {
          throw Exception('系统命令删除失败: ${result.stderr}');
        }
      } else {
        // 非Windows平台，重新抛出原始异常
        rethrow;
      }
    }
  }

  /// 获取文件大小（MB）
  /// [filePath] 文件路径
  Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // 转换为MB
      }
    } catch (e) {
      debugPrint('获取文件大小失败: $filePath, 错误: $e');
    }
    return 0.0;
  }

  /// 检查文件是否存在
  /// [filePath] 文件路径
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 获取文件名（不含路径）
  /// [filePath] 文件路径
  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// 获取文件扩展名
  /// [filePath] 文件路径
  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// 判断是否为图片文件
  /// [filePath] 文件路径
  bool isImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  /// 判断是否为文档文件
  /// [filePath] 文件路径
  bool isDocumentFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.pdf', '.doc', '.docx', '.txt', '.rtf'].contains(extension);
  }

  /// 清理未使用的文件
  /// 删除不再被任何条目引用的证明材料文件
  /// [usedFilePaths] 当前正在使用的文件路径列表
  Future<void> cleanupUnusedFiles(List<String> usedFilePaths) async {
    try {
      final proofDir = await _proofMaterialsDirectory;
      final files = await proofDir.list().toList();
      
      for (final entity in files) {
        if (entity is File) {
          final filePath = entity.path;
          if (!usedFilePaths.contains(filePath)) {
            await deleteFile(filePath);
            debugPrint('清理未使用的文件: $filePath');
          }
        }
      }
    } catch (e) {
      debugPrint('清理未使用文件失败: $e');
    }
  }

  /// 验证文件类型是否支持
  /// [filePath] 文件路径
  bool isSupportedFileType(String filePath) {
    return isImageFile(filePath) || isDocumentFile(filePath);
  }

  /// 获取文件MIME类型
  /// [filePath] 文件路径
  String? getMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      default:
        return null;
    }
  }

  /// 获取文件类型描述
  /// [filePath] 文件路径
  String getFileTypeDescription(String filePath) {
    final extension = getFileExtension(filePath);
    switch (extension) {
      case '.pdf':
        return 'PDF文档';
      case '.doc':
      case '.docx':
        return 'Word文档';
      case '.txt':
        return '文本文件';
      case '.jpg':
      case '.jpeg':
        return 'JPEG图片';
      case '.png':
        return 'PNG图片';
      case '.gif':
        return 'GIF图片';
      default:
        return '文件';
    }
  }
}