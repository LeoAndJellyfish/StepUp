import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/nutstore_config_service.dart';
import '../services/nutstore_backup_service.dart';

class NutstoreBackupPage extends StatefulWidget {
  const NutstoreBackupPage({super.key});

  @override
  State<NutstoreBackupPage> createState() => _NutstoreBackupPageState();
}

class _NutstoreBackupPageState extends State<NutstoreBackupPage> {
  final NutstoreConfigService _configService = NutstoreConfigService();
  final NutstoreBackupService _backupService = NutstoreBackupService();

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEnabled = false;
  bool _isAutoBackup = false;
  bool _isConfigured = false;
  DateTime? _lastBackupTime;
  bool _isLoading = true;
  bool _isTestingConnection = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  double _progress = 0.0;
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isEnabled = await _configService.isEnabled();
      final isAutoBackup = await _configService.isAutoBackup();
      final isConfigured = await _configService.isConfigured();
      final lastBackupTime = await _configService.getLastBackupTime();
      final username = await _configService.getUsername();
      final password = await _configService.getPassword();

      if (mounted) {
        setState(() {
          _isEnabled = isEnabled;
          _isAutoBackup = isAutoBackup;
          _isConfigured = isConfigured;
          _lastBackupTime = lastBackupTime;
          _usernameController.text = username ?? '';
          _passwordController.text = password ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载配置失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _configService.setUsername(_usernameController.text.trim());
      await _configService.setPassword(_passwordController.text);
      await _configService.setEnabled(_isEnabled);
      await _configService.setAutoBackup(_isAutoBackup);

      // 清除客户端缓存，强制重新创建
      _backupService.clearClient();

      if (mounted) {
        setState(() {
          _isConfigured = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置已保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存配置失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    try {
      final connected = await _backupService.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connected ? '连接成功！' : '连接失败，请检查账号密码'),
            backgroundColor: connected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _backup() async {
    setState(() {
      _isBackingUp = true;
      _progress = 0.0;
      _progressMessage = '准备备份...';
    });

    final success = await _backupService.backup(
      includeFiles: true,
      progressCallback: (progress, message) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _progressMessage = message;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isBackingUp = false;
        if (success) {
          _lastBackupTime = DateTime.now();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '备份成功！' : '备份失败'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text(
          '从云端恢复数据将替换当前所有数据。\n\n建议在恢复前先备份当前数据。\n\n是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('继续恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
      _progress = 0.0;
      _progressMessage = '准备恢复...';
    });

    final success = await _backupService.restore(
      replaceExisting: true,
      progressCallback: (progress, message) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _progressMessage = message;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isRestoring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '恢复成功！' : '恢复失败'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTutorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const NutstoreTutorialSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('坚果云备份'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTutorial,
            tooltip: '使用教程',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 状态卡片
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // 配置表单
                  _buildConfigForm(),
                  const SizedBox(height: 24),

                  // 操作按钮
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isEnabled && _isConfigured
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: _isEnabled && _isConfigured
                      ? Colors.green
                      : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnabled && _isConfigured
                            ? '云备份已启用'
                            : '云备份未启用',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _isConfigured
                            ? '账号已配置'
                            : '请先配置坚果云账号',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_lastBackupTime != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '上次备份: ${DateFormat('yyyy-MM-dd HH:mm').format(_lastBackupTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '账号配置',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '坚果云账号（邮箱）',
              hintText: '请输入坚果云注册邮箱',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入账号';
              }
              if (!value.contains('@')) {
                return '请输入有效的邮箱地址';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: '应用密码',
              hintText: '请输入第三方应用密码',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
              helperText: '非登录密码，需在坚果云网页版生成',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('启用云备份'),
            subtitle: const Text('开启后将数据备份到坚果云'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('自动备份'),
            subtitle: const Text('应用启动时自动检查并备份'),
            value: _isAutoBackup,
            onChanged: (value) {
              setState(() {
                _isAutoBackup = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('保存配置'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '备份操作',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_isBackingUp || _isRestoring) ...[
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(
            _progressMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isConfigured && !_isBackingUp && !_isRestoring)
                    ? _testConnection
                    : null,
                icon: _isTestingConnection
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: const Text('测试连接'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isConfigured && !_isBackingUp && !_isRestoring)
                    ? _backup
                    : null,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                label: const Text('立即备份'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isConfigured && !_isBackingUp && !_isRestoring)
                ? _restore
                : null,
            icon: _isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore),
            label: const Text('从云端恢复'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// 教程底部弹窗
class NutstoreTutorialSheet extends StatelessWidget {
  const NutstoreTutorialSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '坚果云配置教程',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    TutorialStep(
                      step: 1,
                      title: '注册坚果云账号',
                      content:
                          '访问坚果云官网 (www.jianguoyun.com) 注册账号。如果已有账号，可直接使用。',
                      icon: Icons.person_add,
                    ),
                    TutorialStep(
                      step: 2,
                      title: '登录网页版',
                      content: '在电脑浏览器中访问坚果云网页版，使用账号密码登录。',
                      icon: Icons.login,
                    ),
                    TutorialStep(
                      step: 3,
                      title: '生成应用密码',
                      content:
                          '点击右上角头像 → 账户信息 → 安全选项 → 添加应用密码。\n\n注意：这里生成的密码是专门给第三方应用使用的，不是你的登录密码。',
                      icon: Icons.password,
                    ),
                    TutorialStep(
                      step: 4,
                      title: '配置 StepUp',
                      content:
                          '在本页面输入：\n• 坚果云账号（邮箱）\n• 刚刚生成的应用密码\n• 开启"启用云备份"开关\n• 点击"保存配置"',
                      icon: Icons.settings,
                    ),
                    TutorialStep(
                      step: 5,
                      title: '测试连接',
                      content: '点击"测试连接"按钮，验证配置是否正确。',
                      icon: Icons.check_circle,
                    ),
                    TutorialStep(
                      step: 6,
                      title: '开始备份',
                      content:
                          '点击"立即备份"将数据上传到坚果云。之后可以随时点击"从云端恢复"来恢复数据。',
                      icon: Icons.cloud_upload,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  '小贴士',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• 建议定期备份重要数据\n'
                              '• 可以在多台设备上登录同一坚果云账号实现数据同步\n'
                              '• 备份文件存储在坚果云的 StepUpBackup 文件夹中\n'
                              '• 请勿手动修改备份文件',
                              style: TextStyle(color: Colors.blue[800]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TutorialStep extends StatelessWidget {
  final int step;
  final String title;
  final String content;
  final IconData icon;

  const TutorialStep({
    super.key,
    required this.step,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
