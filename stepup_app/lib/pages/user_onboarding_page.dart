import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/user_dao.dart';
import '../theme/app_theme.dart';

/// 用户引导页面
/// 用于首次启动时收集用户基本信息
class UserOnboardingPage extends StatefulWidget {
  const UserOnboardingPage({super.key});

  @override
  State<UserOnboardingPage> createState() => _UserOnboardingPageState();
}

class _UserOnboardingPageState extends State<UserOnboardingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  
  final UserDao _userDao = UserDao();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _majorController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    // 简单验证
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

      // 创建用户对象
      final now = DateTime.now();
      final user = User(
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        major: _majorController.text.trim(),
        grade: int.tryParse(_gradeController.text.trim()) ?? 1,
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
                  '请完善您的个人信息',
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

                // 表单字段
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    hintText: '请输入您的姓名',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: '学号',
                    hintText: '请输入您的学号',
                    prefixIcon: Icon(Icons.assignment_ind),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    hintText: '请输入您的邮箱',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '手机号码',
                    hintText: '请输入您的手机号码',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _majorController,
                  decoration: const InputDecoration(
                    labelText: '专业',
                    hintText: '请输入您的专业',
                    prefixIcon: Icon(Icons.book),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _gradeController,
                  decoration: const InputDecoration(
                    labelText: '年级',
                    hintText: '请输入您的年级',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveUserInfo(),
                ),
                const SizedBox(height: 32),
                
                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUserInfo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('完成并进入'),
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}