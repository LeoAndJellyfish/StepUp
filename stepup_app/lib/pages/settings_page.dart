import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_dao.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _userName;
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