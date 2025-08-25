import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../services/subcategory_dao.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class CategoryDetailPage extends StatefulWidget {
  final Category category;

  const CategoryDetailPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  List<Subcategory> _subcategories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final subcategories = await _subcategoryDao.getSubcategoriesByCategoryId(
        widget.category.id!,
      );
      
      setState(() {
        _subcategories = subcategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载子分类失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Color(
          int.parse(widget.category.color.substring(1), radix: 16) + 0xFF000000,
        ).withValues(alpha: 0.1),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubcategories,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(),
              const SizedBox(height: AppTheme.spacing24),
              _buildSubcategoriesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    final color = Color(
      int.parse(widget.category.color.substring(1), radix: 16) + 0xFF000000,
    );

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
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.category.code,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.category.description.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing16),
              const Divider(),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                '分类介绍',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                widget.category.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              '子分类',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (!_isLoading && _subcategories.isNotEmpty)
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
                  '${_subcategories.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildSubcategoriesContent(),
      ],
    );
  }

  Widget _buildSubcategoriesContent() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载子分类中...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        title: '加载失败',
        subtitle: _error,
        onRetry: _loadSubcategories,
      );
    }

    if (_subcategories.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.category_outlined,
        title: '暂无子分类',
        subtitle: '该分类下还没有子分类',
      );
    }

    return Column(
      children: _subcategories.map((subcategory) {
        return _buildSubcategoryCard(subcategory);
      }).toList(),
    );
  }

  Widget _buildSubcategoryCard(Subcategory subcategory) {
    final color = Color(
      int.parse(widget.category.color.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacing16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.subdirectory_arrow_right,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          subcategory.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing4),
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
                subcategory.code,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (subcategory.description.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                subcategory.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        isThreeLine: subcategory.description.isNotEmpty,
      ),
    );
  }
}