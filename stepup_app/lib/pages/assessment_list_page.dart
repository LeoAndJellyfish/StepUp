import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../models/assessment_item.dart';
import '../models/category.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/event_bus.dart';

class AssessmentListPage extends StatefulWidget {
  const AssessmentListPage({Key? key}) : super(key: key);

  @override
  State<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends State<AssessmentListPage> {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final EventBus _eventBus = EventBus();
  
  List<AssessmentItem> _items = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;

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

      final items = await _assessmentItemDao.getAllItems(
        categoryId: _selectedCategoryId,
      );
      final categories = await _categoryDao.getAllCategories();
      
      setState(() {
        _items = items;
        _categories = categories;
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
        title: const Text('综测条目'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          final result = await context.push('/assessment/add');
          if (result == true) {
            _loadData();
          }
        },
        icon: Icons.add,
        tooltip: '添加条目',
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

    if (_items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment,
        title: '暂无条目',
        subtitle: '开始添加您的第一个综测条目吧！',
        action: FilledButton.icon(
          onPressed: () async {
            final result = await context.push('/assessment/add');
            if (result == true) {
              _loadData();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('添加条目'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final category = _categories.firstWhere(
          (cat) => cat.id == item.categoryId,
          orElse: () => Category(
            name: '未知分类',
            description: '',
            color: '#999999',
            icon: 'help',
            createdAt: DateTime.now(),
          ),
        );
        
        return _buildItemCard(item, category);
      },
    );
  }

  Widget _buildItemCard(AssessmentItem item, Category category) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: () async {
          final result = await context.push('/assessment/edit/${item.id}');
          if (result == true) {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(
                      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      Icons.category,
                      size: 16,
                      color: Color(
                        int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmDialog(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                category.name,
                style: AppTheme.labelMedium.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  item.description,
                  style: AppTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    '${item.score.toStringAsFixed(1)} 分',
                    style: AppTheme.bodyMedium.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    '${item.duration.toStringAsFixed(1)} 小时',
                    style: AppTheme.bodyMedium.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(item.activityDate),
                    style: AppTheme.bodySmall.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选条件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: '分类'),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ..._categories.map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadData();
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索条目'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入关键词搜索...',
          ),
          onChanged: (value) {
            searchQuery = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (searchQuery.isNotEmpty) {
                try {
                  final results = await _assessmentItemDao.searchItems(searchQuery);
                  setState(() {
                    _items = results;
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('搜索失败: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(AssessmentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除条目「${item.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItem(item);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 删除条目
  Future<void> _deleteItem(AssessmentItem item) async {
    try {
      await _assessmentItemDao.deleteItem(item.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除条目「${item.title}」')),
        );
        // 触发数据变更事件
        _eventBus.emit(AppEvent.assessmentItemChanged);
        _loadData(); // 刷新列表
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
}