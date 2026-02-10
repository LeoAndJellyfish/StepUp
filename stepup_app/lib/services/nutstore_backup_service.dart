import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'nutstore_config_service.dart';
import 'data_export_service.dart';

/// 坚果云备份进度回调
typedef BackupProgressCallback = void Function(double progress, String message);

/// 坚果云备份服务
/// 提供基于 WebDAV 的坚果云数据备份和恢复功能
class NutstoreBackupService {
  final NutstoreConfigService _configService = NutstoreConfigService();
  final DataExportService _exportService = DataExportService();

  static const String _backupDirName = 'StepUpBackup';
  static const String _backupFileName = 'stepup_backup.json';

  webdav.Client? _client;

  /// 初始化 WebDAV 客户端
  Future<webdav.Client?> _getClient() async {
    if (_client != null) return _client;

    final isConfigured = await _configService.isConfigured();
    if (!isConfigured) {
      throw Exception('坚果云未配置，请先配置账号信息');
    }

    final serverUrl = await _configService.getServerUrl();
    final username = await _configService.getUsername();
    final password = await _configService.getPassword();

    if (serverUrl == null || username == null || password == null) {
      throw Exception('坚果云配置信息不完整');
    }

    try {
      _client = webdav.newClient(
        serverUrl,
        user: username,
        password: password,
        debug: false,
      );
      return _client;
    } catch (e) {
      throw Exception('创建 WebDAV 客户端失败: $e');
    }
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      final client = await _getClient();
      if (client == null) return false;

      // 尝试 ping 服务器来测试连接
      await client.ping();
      return true;
    } catch (e) {
      debugPrint('坚果云连接测试失败: $e');
      return false;
    }
  }

  /// 确保备份目录存在
  Future<void> _ensureBackupDir(webdav.Client client) async {
    try {
      // 检查目录是否存在
      final list = await client.readDir('/');
      final exists = list.any((file) =>
          file.isDir == true && file.name == _backupDirName);

      if (!exists) {
        // 创建备份目录
        await client.mkdir('/$_backupDirName');
      }
    } catch (e) {
      debugPrint('创建备份目录失败: $e');
      throw Exception('创建备份目录失败: $e');
    }
  }

  /// 上传备份文件到坚果云
  Future<void> _uploadBackupFile(
    webdav.Client client,
    String localFilePath,
    BackupProgressCallback? progressCallback,
  ) async {
    try {
      progressCallback?.call(0.7, '正在上传备份文件到坚果云...');

      final remotePath = '/$_backupDirName/$_backupFileName';

      await client.writeFromFile(
        localFilePath,
        remotePath,
        onProgress: (current, total) {
          final uploadProgress = current / total;
          debugPrint('上传进度: ${(uploadProgress * 100).toStringAsFixed(1)}%');
        },
      );

      progressCallback?.call(0.9, '备份文件上传完成');
    } catch (e) {
      debugPrint('上传备份文件失败: $e');
      throw Exception('上传备份文件失败: $e');
    }
  }

  /// 执行备份
  Future<bool> backup({
    BackupProgressCallback? progressCallback,
    bool includeFiles = true,
  }) async {
    try {
      progressCallback?.call(0.0, '开始备份...');

      // 1. 检查是否启用
      final isEnabled = await _configService.isEnabled();
      if (!isEnabled) {
        throw Exception('坚果云备份未启用');
      }

      // 2. 获取客户端
      progressCallback?.call(0.1, '连接坚果云...');
      final client = await _getClient();
      if (client == null) {
        throw Exception('无法创建 WebDAV 客户端');
      }

      // 3. 测试连接
      progressCallback?.call(0.15, '测试连接...');
      final connected = await testConnection();
      if (!connected) {
        throw Exception('无法连接到坚果云，请检查账号密码');
      }

      // 4. 确保备份目录存在
      progressCallback?.call(0.2, '准备备份目录...');
      await _ensureBackupDir(client);

      // 5. 导出数据到本地临时文件
      progressCallback?.call(0.25, '正在导出数据...');
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = path.join(tempDir.path, _backupFileName);

      await _exportService.exportAllData(
        outputPath: tempFilePath,
        includeFiles: includeFiles,
        progressCallback: (exportProgress, message) {
          // 将导出进度映射到 0.25 - 0.7 范围
          final mappedProgress = 0.25 + (exportProgress * 0.45);
          progressCallback?.call(mappedProgress, message);
        },
      );

      // 6. 上传文件到坚果云
      await _uploadBackupFile(client, tempFilePath, progressCallback);

      // 7. 更新最后备份时间
      await _configService.setLastBackupTime(DateTime.now());

      // 8. 清理临时文件
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('清理临时文件失败: $e');
      }

      progressCallback?.call(1.0, '备份完成');
      return true;
    } catch (e) {
      debugPrint('备份失败: $e');
      progressCallback?.call(0.0, '备份失败: $e');
      return false;
    }
  }

  /// 从坚果云下载备份文件
  Future<String?> _downloadBackupFile(
    webdav.Client client,
    BackupProgressCallback? progressCallback,
  ) async {
    try {
      progressCallback?.call(0.3, '正在从坚果云下载备份文件...');

      final remotePath = '/$_backupDirName/$_backupFileName';
      final tempDir = await getTemporaryDirectory();
      final localFilePath = path.join(tempDir.path, 'restore_$_backupFileName');

      // 下载文件
      await client.read2File(
        remotePath,
        localFilePath,
        onProgress: (current, total) {
          final downloadProgress = current / total;
          debugPrint('下载进度: ${(downloadProgress * 100).toStringAsFixed(1)}%');
        },
      );

      progressCallback?.call(0.6, '备份文件下载完成');
      return localFilePath;
    } catch (e) {
      debugPrint('下载备份文件失败: $e');
      throw Exception('下载备份文件失败: $e');
    }
  }

  /// 执行恢复
  Future<bool> restore({
    BackupProgressCallback? progressCallback,
    bool replaceExisting = true,
  }) async {
    try {
      progressCallback?.call(0.0, '开始恢复...');

      // 1. 检查是否启用
      final isEnabled = await _configService.isEnabled();
      if (!isEnabled) {
        throw Exception('坚果云备份未启用');
      }

      // 2. 获取客户端
      progressCallback?.call(0.1, '连接坚果云...');
      final client = await _getClient();
      if (client == null) {
        throw Exception('无法创建 WebDAV 客户端');
      }

      // 3. 测试连接
      progressCallback?.call(0.15, '测试连接...');
      final connected = await testConnection();
      if (!connected) {
        throw Exception('无法连接到坚果云，请检查账号密码');
      }

      // 4. 下载备份文件
      final backupFilePath = await _downloadBackupFile(client, progressCallback);
      if (backupFilePath == null) {
        throw Exception('下载备份文件失败');
      }

      // 5. 导入数据
      progressCallback?.call(0.7, '正在导入数据...');
      await _exportService.importData(
        filePath: backupFilePath,
        replaceExisting: replaceExisting,
        progressCallback: (importProgress, message, {isError = false}) {
          // 将导入进度映射到 0.7 - 1.0 范围
          final mappedProgress = 0.7 + (importProgress * 0.3);
          progressCallback?.call(mappedProgress, message);
        },
      );

      // 6. 清理临时文件
      try {
        final tempFile = File(backupFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('清理临时文件失败: $e');
      }

      progressCallback?.call(1.0, '恢复完成');
      return true;
    } catch (e) {
      debugPrint('恢复失败: $e');
      progressCallback?.call(0.0, '恢复失败: $e');
      return false;
    }
  }

  /// 检查云端是否存在备份
  Future<bool> checkBackupExists() async {
    try {
      final client = await _getClient();
      if (client == null) return false;

      final list = await client.readDir('/$_backupDirName');
      return list.any((file) => file.name == _backupFileName);
    } catch (e) {
      debugPrint('检查备份存在性失败: $e');
      return false;
    }
  }

  /// 获取云端备份信息
  Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final client = await _getClient();
      if (client == null) return null;

      final list = await client.readDir('/$_backupDirName');
      final backupFile = list.firstWhere(
        (file) => file.name == _backupFileName,
        orElse: () => throw Exception('备份文件不存在'),
      );

      return {
        'name': backupFile.name,
        'size': backupFile.size,
        'modified': backupFile.mTime,
        'path': backupFile.path,
      };
    } catch (e) {
      debugPrint('获取备份信息失败: $e');
      return null;
    }
  }

  /// 清除客户端缓存
  void clearClient() {
    _client = null;
  }
}
