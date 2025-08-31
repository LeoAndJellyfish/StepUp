import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../models/assessment_item.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/level.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/subcategory_dao.dart';
import '../services/level_dao.dart';
import '../services/assessment_deletion_service.dart';
import '../services/proof_materials_export_service.dart';
import '../services/event_bus.dart';

class AssessmentListPage extends StatefulWidget {
  const AssessmentListPage({super.key});

  @override
  State<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends State<AssessmentListPage> {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  final LevelDao _levelDao = LevelDao();
  final AssessmentItemDeletionService _deletionService = AssessmentItemDeletionService();
  final ProofMaterialsExportService _exportService = ProofMaterialsExportService();
  final EventBus _eventBus = EventBus();
  
  List<AssessmentItem> _items = [];
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  List<Level> _levels = [];
  
  bool _isLoading = true;
  String? _error;
  
  // 导出状态
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportMessage = '';
  
  // 筛选条件
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedLevelId;
  bool? _isAwarded; // null表示全部，true表示已获奖，false表示未获奖
  bool? _isCollective;
  bool? _isLeader;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 监听评估条目变更事件，自动刷新数据
    _eventBus.on(AppEvent.assessmentItemChanged, _loadData);
  }

  @override
  void dispose() {
    // 移除事件监听
    _eventBus.off(AppEvent.assessmentItemChanged, _loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 加载基础数据
      final categories = await _categoryDao.getAllCategories();
      final levels = await _levelDao.getAllLevels();
      
      // 加载子分类
      List<Subcategory> subcategories = [];
      if (_selectedCategoryId != null) {
        subcategories = await _subcategoryDao.getSubcategoriesByCategoryId(_selectedCategoryId!);
      } else {
        subcategories = await _subcategoryDao.getAllSubcategories();
      }

      // 构建筛选条件
      final items = await _getFilteredItems();
      
      setState(() {
        _items = items;
        _categories = categories;
        _subcategories = subcategories;
        _levels = levels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载数据失败: $e';
        _isLoading = false;
      });
    }
  }

  // 根据筛选条件获取数据
  Future<List<AssessmentItem>> _getFilteredItems() async {
    return await _assessmentItemDao.getAllItems(
      categoryId: _selectedCategoryId,
      subcategoryId: _selectedSubcategoryId,
      levelId: _selectedLevelId,
      isAwarded: _isAwarded,
      isCollective: _isCollective,
      isLeader: _isLeader,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('综测条目'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: '导出证明材料',
          ),
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
            code: 'UNKNOWN',
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
              // 证明材料指示器
              if (item.imagePath != null || item.filePath != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                InkWell(
                  onTap: () => _showProofMaterialsDialog(item),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attachment,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spacing4),
                        Text(
                          '已上传证明材料',
                          style: AppTheme.bodySmall.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.imagePath != null) ...[
                          const SizedBox(width: AppTheme.spacing4),
                          Icon(
                            Icons.image,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                        if (item.filePath != null) ...[
                          const SizedBox(width: AppTheme.spacing4),
                          Icon(
                            Icons.attach_file,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                        const SizedBox(width: AppTheme.spacing4),
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主分类
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: '主分类'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部')),
                  ..._categories.map((category) => DropdownMenuItem(
                    value: category.id,
                    child: Text('${category.name} (${category.code})'),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedSubcategoryId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 子分类
              if (_subcategories.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedSubcategoryId,
                  decoration: const InputDecoration(labelText: '子分类'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    ..._subcategories.where((sub) => 
                      _selectedCategoryId == null || sub.categoryId == _selectedCategoryId
                    ).map((subcategory) => DropdownMenuItem(
                      value: subcategory.id,
                      child: Text('${subcategory.name} (${subcategory.code})'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // 活动级别
              DropdownButtonFormField<int>(
                initialValue: _selectedLevelId,
                decoration: const InputDecoration(labelText: '活动级别'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部')),
                  ..._levels.map((level) => DropdownMenuItem(
                    value: level.id,
                    child: Text(level.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLevelId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 获奖状态
              DropdownButtonFormField<bool>(
                initialValue: _isAwarded,
                decoration: const InputDecoration(labelText: '获奖状态'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全部')),
                  DropdownMenuItem(value: true, child: Text('已获奖')),
                  DropdownMenuItem(value: false, child: Text('未获奖')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isAwarded = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 是否代表集体
              DropdownButtonFormField<bool>(
                initialValue: _isCollective,
                decoration: const InputDecoration(labelText: '参加类型'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全部')),
                  DropdownMenuItem(value: true, child: Text('代表集体')),
                  DropdownMenuItem(value: false, child: Text('个人参加')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isCollective = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 是否为负责人
              DropdownButtonFormField<bool>(
                initialValue: _isLeader,
                decoration: const InputDecoration(labelText: '担任角色'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全部')),
                  DropdownMenuItem(value: true, child: Text('负责人')),
                  DropdownMenuItem(value: false, child: Text('普通参与者')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isLeader = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategoryId = null;
                _selectedSubcategoryId = null;
                _selectedLevelId = null;
                _isAwarded = null;
                _isCollective = null;
                _isLeader = null;
                _startDate = null;
                _endDate = null;
              });
            },
            child: const Text('清空'),
          ),
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
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              if (searchQuery.isNotEmpty) {
                try {
                  final results = await _assessmentItemDao.searchItems(searchQuery);
                  setState(() {
                    _items = results;
                  });
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
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
    DeleteConfirmDialog.show(
      context,
      content: '确定要删除条目「${item.title}」吗？此操作不可撤销。',
      onConfirm: () => _deleteItem(item),
    );
  }

  // 显示证明材料预览对话框
  void _showProofMaterialsDialog(AssessmentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('证明材料'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imagePath != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.image, color: Colors.green),
                    title: const Text('证明图片'),
                    subtitle: Text(_getFileName(item.imagePath!)),
                    trailing: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _previewImage(item.imagePath!);
                      },
                      icon: const Icon(Icons.visibility),
                      tooltip: '预览图片',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (item.filePath != null) ...[
                Card(
                  child: ListTile(
                    leading: Icon(_getFileIcon(item.filePath!), color: Colors.blue),
                    title: const Text('证明文件'),
                    subtitle: Text(_getFileName(item.filePath!)),
                    trailing: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _previewFile(item.filePath!);
                      },
                      icon: const Icon(Icons.visibility),
                      tooltip: '预览文件',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 预览图片
  void _previewImage(String imagePath) {
    context.push(
      '/image-preview?path=${Uri.encodeComponent(imagePath)}&title=${Uri.encodeComponent('证明图片')}',
    );
  }

  // 预览文件
  void _previewFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    final fileName = _getFileName(filePath);
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      // 如果是图片文件，使用图片预览
      context.push(
        '/image-preview?path=${Uri.encodeComponent(filePath)}&title=${Uri.encodeComponent('证明图片')}',
      );
    } else {
      // 其他文件使用文档预览
      context.push(
        '/document-preview?path=${Uri.encodeComponent(filePath)}&title=${Uri.encodeComponent(fileName)}',
      );
    }
  }

  // 获取文件名
  String _getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  // 获取文件图标
  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // 删除条目
  Future<void> _deleteItem(AssessmentItem item) async {
    try {
      // 使用删除服务完整删除条目及其所有文件
      await _deletionService.deleteAssessmentItem(item.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除条目「${item.title}」及其所有证明材料')),
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

  // 显示导出对话框
  void _showExportDialog() async {
    try {
      // 获取导出统计信息
      final stats = await _exportService.getExportStatistics();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出证明材料'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('将导出所有条目的证明材料，并按条目名称重命名后打包：'),
              const SizedBox(height: 16),
              Text('• 总条目数：${stats['totalItems']} 个'),
              Text('• 有证明材料的条目：${stats['itemsWithProof']} 个'),
              Text('• 证明材料文件数：${stats['totalFiles']} 个'),
              const SizedBox(height: 16),
              if (_isExporting) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  _exportMessage,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${(_exportProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ] else
                const Text(
                  '注意：导出过程可能需要一些时间，请耐心等待。进度信息将通过通知显示。',
                  style: TextStyle(color: Colors.orange),
                ),
            ],
          ),
          actions: [
            if (!_isExporting) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: (stats['itemsWithProof'] ?? 0) > 0 ? () {
                  Navigator.of(context).pop();
                  _startExport();
                } : null,
                child: const Text('开始导出'),
              ),
            ] else
              TextButton(
                onPressed: null, // 导出过程中禁用按钮
                child: const Text('正在导出...'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取导出信息失败: $e')),
        );
      }
    }
  }

  // 开始导出
  void _startExport() async {
    // 在异步操作开始前获取所需的引用
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!mounted) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportMessage = '准备导出...';
    });

    try {
      // 直接执行导出，不显示进度对话框
      final outputPath = await _exportService.exportAllProofMaterials(
        progressCallback: (progress, message) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
              _exportMessage = message;
            });
            
            // 使用预先获取的ScaffoldMessenger
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('导出进度: ${(progress * 100).toStringAsFixed(1)}% - $message'),
                duration: const Duration(milliseconds: 500),
              ),
            );
          }
        },
      );

      if (mounted) {
        // 显示成功消息
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已导出所有证明材料: ${outputPath.split('\\').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '查看位置',
              onPressed: () {
                _showExportSuccessDialog(outputPath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0.0;
          _exportMessage = '';
        });
      }
    }
  }

  // 显示导出成功对话框
  void _showExportSuccessDialog(String outputPath) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('证明材料已成功导出！'),
            const SizedBox(height: 8),
            SelectableText(
              '保存位置：$outputPath',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}