import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_dao.dart';
import '../services/data_export_service.dart';
import '../services/ai_config_service.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _userName;
  final DataExportService _dataExportService = DataExportService();
  final AIConfigService _aiConfigService = AIConfigService();
  bool _isAIEnabled = true;
  bool _isAIConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadAIConfig();
  }

  Future<void> _loadAIConfig() async {
    try {
      final isEnabled = await _aiConfigService.isEnabled();
      final isConfigured = await _aiConfigService.isConfigured();
      if (mounted) {
        setState(() {
          _isAIEnabled = isEnabled;
          _isAIConfigured = isConfigured;
        });
      }
    } catch (e) {
      debugPrint('加载 AI 配置失败: $e');
    }
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
    bool includeFiles = true; // 默认包含文件内容
    
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  CheckboxListTile(
                    title: const Text('包含附件文件内容'),
                    subtitle: const Text('加入所有证明材料的实际内容，导出文件将更大'),
                    value: includeFiles,
                    onChanged: (value) {
                      setState(() {
                        includeFiles = value ?? true;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
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
                    _startExport(includeFiles: includeFiles);
                  },
                  child: const Text('开始导出'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 开始导出数据
  Future<void> _startExport({bool includeFiles = true}) async {
    if (!mounted) return;
    
    // 显示初始进度
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在准备导出数据...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      bool hadError = false;
      String errorMsg = '';
      
      final filePath = await _dataExportService.exportAllData(
        includeFiles: includeFiles,
        progressCallback: (progress, message) {
          // 检测错误信息
          if (message.toLowerCase().contains('失败') || message.toLowerCase().contains('错误')) {
            hadError = true;
            errorMsg = message;
            debugPrint('导出错误: $message');
          }
          
          // 只在关键节点更新进度提示，避免频繁更新
          if (mounted && (progress == 0.0 || progress == 0.25 || progress == 0.5 || progress == 0.75 || progress == 1.0)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 1),
                backgroundColor: hadError ? Colors.orange : null,
              ),
            );
          }
          
          debugPrint('导出进度: $progress - $message');
        },
      );
      
      if (!mounted) return;
      
      // 显示成功消息
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (hadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据导出完成，但部分数据导出失败: $errorMsg'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange, // 使用橙色表示部分成功
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据导出成功！文件保存在: $filePath'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // 显示错误消息
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
      
      // 显示初始进度
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在准备导入数据...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      bool hadError = false;
      String errorMsg = '';
      
      await _dataExportService.importData(
        filePath: filePath,
        replaceExisting: replaceExisting,
        progressCallback: (progress, message, {isError = false}) {
          // 记录错误信息但继续导入
          if (isError) {
            hadError = true;
            errorMsg = message;
            debugPrint('导入错误: $message');
          }
          
          // 只在关键节点更新进度提示，避免频繁更新
          if (mounted && (progress == 0.0 || progress == 0.25 || progress == 0.5 || progress == 0.75 || progress == 1.0)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 1),
                backgroundColor: isError ? Colors.orange : null,
              ),
            );
          }
          
          debugPrint('导入进度: $progress - $message');
        },
      );
      
      if (!mounted) return;
      
      // 确保先隐藏任何可能存在的通知
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // 显示结果消息
      if (hadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据导入完成，但部分数据导入失败: $errorMsg'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange, // 使用橙色表示部分成功
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据导入成功！首页和综测页面已自动刷新'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // 重新加载用户名（以防用户数据发生变化）
      _loadUserName();
    } catch (e) {
      if (!mounted) return;
      
      // 确保先隐藏任何可能存在的通知
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

  // 显示 AI 配置对话框
  Future<void> _showAIConfigDialog() async {
    final apiKey = await _aiConfigService.getApiKey() ?? '';
    final baseUrl = await _aiConfigService.getBaseUrl();

    final apiKeyController = TextEditingController(text: apiKey);
    final baseUrlController = TextEditingController(text: baseUrl);

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue),
              SizedBox(width: 8),
              Text('AI 服务配置'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '配置 DeepSeek AI 服务，用于智能识别条目分类。',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // 可以添加打开浏览器访问 DeepSeek 平台的功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('请访问 https://platform.deepseek.com 获取 API Key'),
                      ),
                    );
                  },
                  child: Text(
                    '获取 API Key →',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key *',
                    hintText: '请输入 DeepSeek API Key',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.deepseek.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '提示：一般情况下无需修改 Base URL',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            if (_isAIConfigured)
              TextButton(
                onPressed: () async {
                  await _aiConfigService.clearApiKey();
                  await _loadAIConfig();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API Key 已清除')),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清除配置'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final newApiKey = apiKeyController.text.trim();
                final newBaseUrl = baseUrlController.text.trim();

                if (newApiKey.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入 API Key'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await _aiConfigService.setApiKey(newApiKey);
                if (newBaseUrl.isNotEmpty) {
                  await _aiConfigService.setBaseUrl(newBaseUrl);
                }
                await _loadAIConfig();

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI 配置已保存')),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
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
          // 坚果云备份部分
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('坚果云备份'),
            subtitle: const Text('配置云备份，数据更安全'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/settings/nutstore-backup'),
          ),
          // AI 设置部分
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.auto_awesome,
              color: _isAIConfigured ? Colors.green : Colors.grey,
            ),
            title: const Text('AI 智能识别'),
            subtitle: Text(
              _isAIConfigured
                  ? '已配置 DeepSeek API'
                  : '未配置 API Key，点击进行配置',
            ),
            trailing: Switch(
              value: _isAIEnabled,
              onChanged: _isAIConfigured
                  ? (value) async {
                      await _aiConfigService.setEnabled(value);
                      setState(() {
                        _isAIEnabled = value;
                      });
                    }
                  : null,
            ),
            onTap: _showAIConfigDialog,
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