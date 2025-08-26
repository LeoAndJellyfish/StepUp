import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/user_dao.dart';
import '../theme/app_theme.dart';

/// 首次打开应用的欢迎页面
/// 仅要求用户输入姓名，并提供跳过选项
class FirstTimeWelcomePage extends StatefulWidget {
  const FirstTimeWelcomePage({super.key});

  @override
  State<FirstTimeWelcomePage> createState() => _FirstTimeWelcomePageState();
}

class _FirstTimeWelcomePageState extends State<FirstTimeWelcomePage> {
  final TextEditingController _nameController = TextEditingController();
  final UserDao _userDao = UserDao();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUserName() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '请输入您的姓名';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 创建用户对象，只设置姓名，其他字段使用默认值
      final now = DateTime.now();
      final user = User(
        name: _nameController.text.trim(),
        studentId: '',
        email: '',
        phone: '',
        major: '',
        grade: 1,
        createdAt: now,
        updatedAt: now,
      );

      // 保存到数据库
      await _userDao.addUser(user);

      // 导航到首页
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _skipAndContinue() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 创建一个默认用户（姓名为"用户"）
      final now = DateTime.now();
      final user = User(
        name: '用户',
        studentId: '',
        email: '',
        phone: '',
        major: '',
        grade: 1,
        createdAt: now,
        updatedAt: now,
      );

      // 保存到数据库
      await _userDao.addUser(user);

      // 导航到首页
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '创建用户失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                Hero(
                  tag: 'app_logo',
                  child: Icon(
                    Icons.trending_up,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '欢迎使用 StepUp',
                  style: AppTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '请告诉我们您的姓名，让我们更好地为您服务',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // 错误信息显示
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!, 
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // 姓名输入框
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    hintText: '请输入您的姓名',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveUserName(),
                ),
                const SizedBox(height: 24),

                // 保存按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUserName,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('开始使用'),
                  ),
                ),
                const SizedBox(height: 16),

                // 跳过按钮
                TextButton(
                  onPressed: _isLoading ? null : _skipAndContinue,
                  child: const Text('跳过，稍后设置'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}