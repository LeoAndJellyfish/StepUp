import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_dao.dart';
import '../services/classification_scheme_dao.dart';
import '../services/event_bus.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryDao _categoryDao = CategoryDao();
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();
  final EventBus _eventBus = EventBus();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String? _activeSchemeName;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _eventBus.on(AppEvent.schemeChanged, _loadCategories);
  }

  @override
  void dispose() {
    _eventBus.off(AppEvent.schemeChanged, _loadCategories);
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final activeScheme = await _schemeDao.getActiveScheme();
      
      List<Category> categories;
      if (activeScheme != null) {
        categories = await _categoryDao.getCategoriesBySchemeId(activeScheme.id!);
      } else {
        categories = await _categoryDao.getAllCategories();
      }
      
      setState(() {
        _categories = categories;
        _activeSchemeName = activeScheme?.name;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('分类管理'),
            if (_activeSchemeName != null)
              Text(
                '方案: $_activeSchemeName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/schemes'),
            tooltip: '管理分类方案',
          ),
        ],
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
                    context.push(
                      '/categories/detail/${category.id}',
                      extra: category,
                    );
                  },
                ),
              );
            },
          );
  }
}
