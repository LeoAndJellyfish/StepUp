import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/user_dao.dart';

/// 用户信息编辑页面
class UserProfileEditPage extends StatefulWidget {
  const UserProfileEditPage({super.key});

  @override
  State<UserProfileEditPage> createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  
  final UserDao _userDao = UserDao();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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

  Future<void> _loadUserData() async {
    try {
      final user = await _userDao.getFirstUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _studentIdController.text = user.studentId;
          _emailController.text = user.email;
          _phoneController.text = user.phone;
          _majorController.text = user.major;
          _gradeController.text = user.grade.toString();
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载用户信息失败: $e';
        _isInitialized = true;
      });
    }
  }

  Future<void> _saveUserInfo() async {
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

      final now = DateTime.now();
      User user;
      
      if (_currentUser != null) {
        // 更新现有用户
        user = _currentUser!.copyWith(
          name: _nameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          major: _majorController.text.trim(),
          grade: int.tryParse(_gradeController.text.trim()) ?? 1,
          updatedAt: now,
        );
        await _userDao.updateUser(user);
      } else {
        // 创建新用户
        user = User(
          name: _nameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          major: _majorController.text.trim(),
          grade: int.tryParse(_gradeController.text.trim()) ?? 1,
          createdAt: now,
          updatedAt: now,
        );
        await _userDao.addUser(user);
      }

      // 返回上一页
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息已保存'),
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
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
      appBar: AppBar(
        title: const Text('编辑个人信息'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
                      labelText: '姓名 *',
                      hintText: '请输入您的姓名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveUserInfo(),
                  ),
                  const SizedBox(height: 32),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserInfo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存信息'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}