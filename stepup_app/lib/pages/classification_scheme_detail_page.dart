import 'package:flutter/material.dart';
import '../models/classification_scheme.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../services/classification_scheme_dao.dart';
import '../services/category_dao.dart';
import '../services/subcategory_dao.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class ClassificationSchemeDetailPage extends StatefulWidget {
  final int schemeId;

  const ClassificationSchemeDetailPage({
    super.key,
    required this.schemeId,
  });

  @override
  State<ClassificationSchemeDetailPage> createState() => _ClassificationSchemeDetailPageState();
}

class _ClassificationSchemeDetailPageState extends State<ClassificationSchemeDetailPage> {
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();

  ClassificationScheme? _scheme;
  List<Category> _categories = [];
  Map<int, List<Subcategory>> _subcategoriesByCategory = {};
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final scheme = await _schemeDao.getSchemeById(widget.schemeId);
      if (scheme == null) {
        setState(() {
          _error = '分类方案不存在';
          _isLoading = false;
        });
        return;
      }

      final categories = await _categoryDao.getCategoriesBySchemeId(widget.schemeId);
      
      final Map<int, List<Subcategory>> subcategoriesMap = {};
      for (final category in categories) {
        if (category.id != null) {
          final subcategories = await _subcategoryDao.getSubcategoriesByCategoryId(category.id!);
          subcategoriesMap[category.id!] = subcategories;
        }
      }

      setState(() {
        _scheme = scheme;
        _categories = categories;
        _subcategoriesByCategory = subcategoriesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载数据失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_scheme?.name ?? '分类方案详情'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
        onRetry: _loadData,
      );
    }

    if (_scheme == null) {
      return const EmptyStateWidget(
        icon: Icons.account_tree,
        title: '方案不存在',
        subtitle: '该分类方案可能已被删除',
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSchemeHeader(),
          const SizedBox(height: AppTheme.spacing24),
          _buildCategoriesSection(),
        ],
      ),
    );
  }

  Widget _buildSchemeHeader() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _scheme!.isActive
                        ? AppTheme.memphisGreen.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_tree,
                    color: _scheme!.isActive
                        ? AppTheme.memphisGreen
                        : theme.colorScheme.outline,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scheme!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing8,
                              vertical: AppTheme.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _scheme!.code,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_scheme!.isActive) ...[
                            const SizedBox(width: AppTheme.spacing8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing8,
                                vertical: AppTheme.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.memphisGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '当前使用',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.memphisGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (_scheme!.isDefault) ...[
                            const SizedBox(width: AppTheme.spacing8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing8,
                                vertical: AppTheme.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.memphisBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '默认',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.memphisBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_scheme!.description.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing16),
              const Divider(),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                '方案说明',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                _scheme!.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: AppTheme.spacing16),
            const Divider(),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.category,
                  label: '分类数',
                  value: _categories.length.toString(),
                ),
                const SizedBox(width: AppTheme.spacing24),
                FutureBuilder<int>(
                  future: _schemeDao.getItemCount(_scheme!.id!),
                  builder: (context, snapshot) {
                    return _buildStatItem(
                      icon: Icons.assignment,
                      label: '条目数',
                      value: (snapshot.data ?? 0).toString(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              '分类列表',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_categories.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_categories.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildCategoriesContent(),
      ],
    );
  }

  Widget _buildCategoriesContent() {
    if (_categories.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.category_outlined,
        title: '暂无分类',
        subtitle: '该方案下还没有分类数据',
      );
    }

    return Column(
      children: _categories.map((category) {
        return _buildCategoryCard(category);
      }).toList(),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final theme = Theme.of(context);
    final color = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );
    final subcategories = _subcategoriesByCategory[category.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppTheme.spacing16),
        childrenPadding: const EdgeInsets.only(
          left: AppTheme.spacing16,
          right: AppTheme.spacing16,
          bottom: AppTheme.spacing16,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.code,
                style: AppTheme.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (subcategories.isNotEmpty) ...[
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '${subcategories.length} 个子分类',
                style: AppTheme.bodySmall.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        children: [
          if (category.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
              child: Text(
                category.description,
                style: AppTheme.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (subcategories.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppTheme.spacing8),
            ...subcategories.map((subcategory) => _buildSubcategoryItem(subcategory, color)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryItem(Subcategory subcategory, Color parentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 16,
            color: parentColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: parentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subcategory.code,
              style: AppTheme.bodySmall.copyWith(
                color: parentColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              subcategory.name,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
