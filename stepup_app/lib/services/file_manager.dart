import 'dart:io';
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

  /// 获取应用文档目录
  Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// 获取证明材料存储目录
  Future<Directory> get _proofMaterialsDirectory async {
    final docs = await _documentsDirectory;
    final proofDir = Directory('${docs.path}/proof_materials');
    if (!await proofDir.exists()) {
      await proofDir.create(recursive: true);
    }
    return proofDir;
  }

  /// 复制文件到应用目录并返回新路径
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

  /// 删除文件
  /// [filePath] 要删除的文件路径
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 静默处理删除错误，避免影响主流程
      // 删除文件失败: $filePath, 错误: $e
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
      // 获取文件大小失败: $filePath, 错误: $e
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
            // 清理未使用的文件: $filePath
          }
        }
      }
    } catch (e) {
      // 清理未使用文件失败: $e
    }
  }

  /// 验证文件类型是否支持
  /// [filePath] 文件路径
  bool isSupportedFileType(String filePath) {
    return isImageFile(filePath) || isDocumentFile(filePath);
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