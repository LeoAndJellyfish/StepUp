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

  Future<void> _editScheme() async {
    if (_scheme == null) return;

    final result = await showDialog<ClassificationScheme>(
      context: context,
      builder: (context) => _EditSchemeDialog(scheme: _scheme!),
    );

    if (result != null) {
      await _schemeDao.updateScheme(result);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('方案信息已更新')),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _AddCategoryDialog(schemeId: widget.schemeId),
    );

    if (result != null) {
      await _categoryDao.insertCategory(result);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分类已添加')),
        );
      }
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _EditCategoryDialog(category: category),
    );

    if (result != null) {
      await _categoryDao.updateCategory(result);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分类已更新')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    // 检查该分类下是否有条目
    final itemCount = await _categoryDao.getCategoryStats(category.id!);
    final hasItems = (itemCount['count'] as int) > 0;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类'),
        content: Text(
          hasItems
              ? '确定要删除分类「${category.name}」吗？\n\n该分类下的所有子分类也将被删除。\n\n⚠️ 注意：该分类下有 ${itemCount['count']} 个条目，删除后这些条目将变为"未分类"状态。'
              : '确定要删除分类「${category.name}」吗？\n\n该分类下的所有子分类也将被删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _categoryDao.deleteCategory(category.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasItems ? '分类已删除，相关条目已变为未分类' : '分类已删除'),
          ),
        );
      }
    }
  }

  Future<void> _addSubcategory(Category category) async {
    final result = await showDialog<Subcategory>(
      context: context,
      builder: (context) => _AddSubcategoryDialog(categoryId: category.id!),
    );

    if (result != null) {
      await _subcategoryDao.insertSubcategory(result);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('子分类已添加')),
        );
      }
    }
  }

  Future<void> _editSubcategory(Subcategory subcategory) async {
    final result = await showDialog<Subcategory>(
      context: context,
      builder: (context) => _EditSubcategoryDialog(subcategory: subcategory),
    );

    if (result != null) {
      await _subcategoryDao.updateSubcategory(result);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('子分类已更新')),
        );
      }
    }
  }

  Future<void> _deleteSubcategory(Subcategory subcategory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除子分类'),
        content: const Text('确定要删除该子分类吗？\n\n⚠️ 注意：使用了该子分类的条目将失去子分类信息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _subcategoryDao.deleteSubcategory(subcategory.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('子分类已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_scheme?.name ?? '分类方案详情'),
        actions: [
          if (_scheme != null && !_scheme!.isDefault)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editScheme,
              tooltip: '编辑方案',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
      floatingActionButton: _scheme != null && !_scheme!.isDefault
          ? FloatingActionButton.extended(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('添加分类'),
            )
          : null,
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
      return EmptyStateWidget(
        icon: Icons.category_outlined,
        title: '暂无分类',
        subtitle: _scheme!.isDefault
            ? '默认方案无法手动添加分类'
            : '点击右下角按钮添加分类',
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
    final canEdit = !_scheme!.isDefault;

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
        trailing: canEdit
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _addSubcategory(category),
                    tooltip: '添加子分类',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editCategory(category);
                          break;
                        case 'delete':
                          _deleteCategory(category);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : null,
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
            ...subcategories.map((subcategory) => _buildSubcategoryItem(subcategory, color, canEdit)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryItem(Subcategory subcategory, Color parentColor, bool canEdit) {
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
          if (canEdit)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: parentColor),
                  onPressed: () => _editSubcategory(subcategory),
                  tooltip: '编辑',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteSubcategory(subcategory),
                  tooltip: '删除',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EditSchemeDialog extends StatefulWidget {
  final ClassificationScheme scheme;

  const _EditSchemeDialog({required this.scheme});

  @override
  State<_EditSchemeDialog> createState() => _EditSchemeDialogState();
}

class _EditSchemeDialogState extends State<_EditSchemeDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scheme.name);
    _codeController = TextEditingController(text: widget.scheme.code);
    _descriptionController = TextEditingController(text: widget.scheme.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑方案信息'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '方案名称',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入方案名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '方案代码',
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入方案代码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '方案描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedScheme = widget.scheme.copyWith(
                name: _nameController.text.trim(),
                code: _codeController.text.trim(),
                description: _descriptionController.text.trim(),
                updatedAt: DateTime.now(),
              );
              Navigator.of(context).pop(updatedScheme);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final int schemeId;

  const _AddCategoryDialog({required this.schemeId});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#2196F3';

  final List<String> _presetColors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#00BCD4',
    '#795548',
    '#607D8B',
    '#E91E63',
    '#3F51B5',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加分类'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入分类名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '分类代码',
                  prefixIcon: Icon(Icons.code),
                  hintText: '如: A, B, C',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入分类代码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '分类描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('选择颜色', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final category = Category(
                schemeId: widget.schemeId,
                name: _nameController.text.trim(),
                code: _codeController.text.trim().toUpperCase(),
                description: _descriptionController.text.trim(),
                color: _selectedColor,
                createdAt: DateTime.now(),
              );
              Navigator.of(context).pop(category);
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final Category category;

  const _EditCategoryDialog({required this.category});

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  late String _selectedColor;

  final List<String> _presetColors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#00BCD4',
    '#795548',
    '#607D8B',
    '#E91E63',
    '#3F51B5',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _codeController = TextEditingController(text: widget.category.code);
    _descriptionController = TextEditingController(text: widget.category.description);
    _selectedColor = widget.category.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑分类'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入分类名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '分类代码',
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入分类代码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '分类描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('选择颜色', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedCategory = widget.category.copyWith(
                name: _nameController.text.trim(),
                code: _codeController.text.trim().toUpperCase(),
                description: _descriptionController.text.trim(),
                color: _selectedColor,
              );
              Navigator.of(context).pop(updatedCategory);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _AddSubcategoryDialog extends StatefulWidget {
  final int categoryId;

  const _AddSubcategoryDialog({required this.categoryId});

  @override
  State<_AddSubcategoryDialog> createState() => _AddSubcategoryDialogState();
}

class _AddSubcategoryDialogState extends State<_AddSubcategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加子分类'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '子分类名称',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入子分类名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '子分类代码',
                  prefixIcon: Icon(Icons.code),
                  hintText: '如: A1, A2, A3',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入子分类代码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '子分类描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final subcategory = Subcategory(
                categoryId: widget.categoryId,
                name: _nameController.text.trim(),
                code: _codeController.text.trim().toUpperCase(),
                description: _descriptionController.text.trim(),
                createdAt: DateTime.now(),
              );
              Navigator.of(context).pop(subcategory);
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _EditSubcategoryDialog extends StatefulWidget {
  final Subcategory subcategory;

  const _EditSubcategoryDialog({required this.subcategory});

  @override
  State<_EditSubcategoryDialog> createState() => _EditSubcategoryDialogState();
}

class _EditSubcategoryDialogState extends State<_EditSubcategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subcategory.name);
    _codeController = TextEditingController(text: widget.subcategory.code);
    _descriptionController = TextEditingController(text: widget.subcategory.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑子分类'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '子分类名称',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入子分类名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '子分类代码',
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入子分类代码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '子分类描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedSubcategory = widget.subcategory.copyWith(
                name: _nameController.text.trim(),
                code: _codeController.text.trim().toUpperCase(),
                description: _descriptionController.text.trim(),
              );
              Navigator.of(context).pop(updatedSubcategory);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
