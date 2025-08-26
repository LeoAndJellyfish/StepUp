import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_dao.dart';
import '../services/data_export_service.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _userName;
  final DataExportService _dataExportService = DataExportService();
  
  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userDao = UserDao();
      final user = await userDao.getFirstUser();
      if (user != null && mounted) {
        setState(() {
          _userName = user.name;
        });
      }
    } catch (e) {
      debugPrint('加载用户名失败: $e');
    }
  }

  // 显示导出数据对话框
  Future<void> _showExportDialog() async {
    final stats = await _dataExportService.getExportStatistics();
    
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('数据导出'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('导出统计信息：'),
              const SizedBox(height: 8),
              Text('用户: ${stats['users']} 个'),
              Text('分类: ${stats['categories']} 个'),
              Text('子分类: ${stats['subcategories']} 个'),
              Text('级别: ${stats['levels']} 个'),
              Text('标签: ${stats['tags']} 个'),
              Text('条目: ${stats['items']} 个'),
              Text('附件: ${stats['attachments']} 个'),
              const SizedBox(height: 16),
              const Text('注意：导出的文件将保存到应用文档目录'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startExport();
              },
              child: const Text('开始导出'),
            ),
          ],
        );
      },
    );
  }

  // 开始导出数据
  Future<void> _startExport() async {
    if (!mounted) return;
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('正在导出数据...'),
                LinearProgressIndicator(
                  value: 0,
                  backgroundColor: Colors.white30,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(hours: 1), // 长时间显示
      backgroundColor: Colors.blue,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    try {
      final filePath = await _dataExportService.exportAllData(
        progressCallback: (progress, message) {
          // 更新进度（这里简化处理，实际应用中可能需要更复杂的进度更新机制）
          debugPrint('导出进度: $progress - $message');
        },
      );
      
      if (!mounted) return;
      
      // 关闭进度提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('数据导出成功！文件保存在: $filePath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // 关闭进度提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('数据导出失败: $e'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 显示导入数据对话框
  Future<void> _showImportDialog() async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('数据导入'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('导入数据将会：'),
              SizedBox(height: 8),
              Text('• 添加新的数据到现有数据中'),
              Text('• 或替换所有现有数据（可选）'),
              SizedBox(height: 16),
              Text('注意：请选择有效的数据备份文件（JSON格式）'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startImport(replaceExisting: false);
              },
              child: const Text('追加导入'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startImport(replaceExisting: true);
              },
              child: const Text('替换导入'),
            ),
          ],
        );
      },
    );
  }

  // 开始导入数据
  Future<void> _startImport({required bool replaceExisting}) async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) {
        // 用户取消选择
        return;
      }
      
      final filePath = result.files.first.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取文件路径'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (!mounted) return;
      
      final snackBar = SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('正在导入数据...'),
                  LinearProgressIndicator(
                    value: 0,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(hours: 1), // 长时间显示
        backgroundColor: Colors.blue,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      
      await _dataExportService.importData(
        filePath: filePath,
        replaceExisting: replaceExisting,
        progressCallback: (progress, message, {isError = false}) {
          // 更新进度（这里简化处理）
          debugPrint('导入进度: $progress - $message');
        },
      );
      
      if (!mounted) return;
      
      // 关闭进度提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据导入成功！'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // 重新加载用户名（以防用户数据发生变化）
      _loadUserName();
    } catch (e) {
      if (!mounted) return;
      
      // 关闭进度提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('数据导入失败: $e'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '个人信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userName != null ? '姓名: $_userName' : '未设置个人信息',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/profile/edit'),
                    child: const Text('编辑个人信息'),
                  ),
                ],
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('关于应用'),
            subtitle: Text('StepUp 综合测评系统 v1.0.0'),
          ),
          // 数据备份与恢复部分
          const Divider(),
          const ListTile(
            leading: Icon(Icons.backup),
            title: Text('数据备份与恢复'),
            subtitle: Text('导出或导入所有数据'),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导出数据'),
            subtitle: const Text('将所有数据导出为JSON文件'),
            onTap: _showExportDialog,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入数据'),
            subtitle: const Text('从JSON文件导入数据'),
            onTap: _showImportDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('意见反馈'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('帮助与支持'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中')),
              );
            },
          ),
        ],
      ),
    );
  }
}