import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_dao.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryDao _categoryDao = CategoryDao();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categories = await _categoryDao.getAllCategories();
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载分类失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载中...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        title: '加载失败',
        subtitle: _error,
        onRetry: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.category,
        title: '暂无分类',
        subtitle: '系统会自动创建默认分类',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(
                int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
              ).withValues(alpha: 0.2),
              child: Icon(
                Icons.category,
                color: Color(
                  int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
                ),
              ),
            ),
            title: Text(category.name),
            subtitle: Text(category.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 分类详情页面将在后续实现
            },
          ),
        );
      },
    );
  }
}