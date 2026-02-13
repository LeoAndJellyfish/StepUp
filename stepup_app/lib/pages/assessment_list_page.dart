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
import 'dart:math' as math;

class AssessmentListPage extends StatefulWidget {
  const AssessmentListPage({super.key});

  @override
  State<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends State<AssessmentListPage>
    with TickerProviderStateMixin {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  final LevelDao _levelDao = LevelDao();
  final AssessmentItemDeletionService _deletionService =
      AssessmentItemDeletionService();
  final ProofMaterialsExportService _exportService =
      ProofMaterialsExportService();
  final EventBus _eventBus = EventBus();

  List<AssessmentItem> _items = [];
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  List<Level> _levels = [];

  bool _isLoading = true;
  String? _error;

  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportMessage = '';

  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedLevelId;
  bool? _isAwarded;
  bool? _isCollective;
  bool? _isLeader;
  DateTime? _startDate;
  DateTime? _endDate;

  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
    _eventBus.on(AppEvent.assessmentItemChanged, _loadData);
  }

  @override
  void dispose() {
    _eventBus.off(AppEvent.assessmentItemChanged, _loadData);
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categories = await _categoryDao.getAllCategories();
      final levels = await _levelDao.getAllLevels();

      List<Subcategory> subcategories = [];
      if (_selectedCategoryId != null) {
        subcategories =
            await _subcategoryDao.getSubcategoriesByCategoryId(_selectedCategoryId!);
      } else {
        subcategories = await _subcategoryDao.getAllSubcategories();
      }

      final items = await _getFilteredItems();

      setState(() {
        _items = items;
        _categories = categories;
        _subcategories = subcategories;
        _levels = levels;
        _isLoading = false;
      });

      _listAnimationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = '加载数据失败: $e';
        _isLoading = false;
      });
    }
  }

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
          _AnimatedAppBarIcon(
            icon: Icons.download,
            onPressed: _showExportDialog,
            tooltip: '导出证明材料',
          ),
          _AnimatedAppBarIcon(
            icon: Icons.filter_list,
            onPressed: _showFilterDialog,
          ),
          _AnimatedAppBarIcon(
            icon: Icons.search,
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
      floatingActionButton: _AnimatedFAB(
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
        action: _MemphisAnimatedButton(
          onPressed: () async {
            final result = await context.push('/assessment/add');
            if (result == true) {
              _loadData();
            }
          },
          icon: Icons.add,
          label: '添加条目',
          backgroundColor: AppTheme.memphisPink,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
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

          return _AnimatedListItem(
            index: index,
            child: _buildItemCard(item, category),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(AssessmentItem item, Category category) {
    final theme = Theme.of(context);
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );

    return _AnimatedCard(
      shadowColor: categoryColor,
      onTap: () async {
        final result = await context.push('/assessment/edit/${item.id}');
        if (result == true) {
          _loadData();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: categoryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.category,
                    size: 18,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _AnimatedPopupMenuButton(
                  onDeleted: () => _showDeleteConfirmDialog(item),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.memphisBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.memphisBlue.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.memphisBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.duration.toStringAsFixed(1)} 小时',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.memphisBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
            if (item.imagePath != null || item.filePath != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              _AnimatedAttachmentChip(
                onTap: () => _showProofMaterialsDialog(item),
                hasImage: item.imagePath != null,
                hasFile: item.filePath != null,
              ),
            ],
          ],
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
              if (_subcategories.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedSubcategoryId,
                  decoration: const InputDecoration(labelText: '子分类'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    ..._subcategories
                        .where((sub) =>
                            _selectedCategoryId == null ||
                            sub.categoryId == _selectedCategoryId)
                        .map((subcategory) => DropdownMenuItem(
                              value: subcategory.id,
                              child:
                                  Text('${subcategory.name} (${subcategory.code})'),
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
                  final results =
                      await _assessmentItemDao.searchItems(searchQuery);
                  setState(() {
                    _items = results;
                  });
                  _listAnimationController.forward(from: 0);
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('搜索失败: $e'),
                        duration: const Duration(seconds: 2),
                      ),
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

  void _showDeleteConfirmDialog(AssessmentItem item) {
    DeleteConfirmDialog.show(
      context,
      content: '确定要删除条目「${item.title}」吗？此操作不可撤销。',
      onConfirm: () => _deleteItem(item),
    );
  }

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
                    leading:
                        Icon(_getFileIcon(item.filePath!), color: Colors.blue),
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

  void _previewImage(String imagePath) {
    context.push(
      '/image-preview?path=${Uri.encodeComponent(imagePath)}&title=${Uri.encodeComponent('证明图片')}',
    );
  }

  void _previewFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    final fileName = _getFileName(filePath);

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      context.push(
        '/image-preview?path=${Uri.encodeComponent(filePath)}&title=${Uri.encodeComponent('证明图片')}',
      );
    } else {
      context.push(
        '/document-preview?path=${Uri.encodeComponent(filePath)}&title=${Uri.encodeComponent(fileName)}',
      );
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

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

  Future<void> _deleteItem(AssessmentItem item) async {
    try {
      await _deletionService.deleteAssessmentItem(item.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除条目「${item.title}」及其所有证明材料'),
            duration: const Duration(seconds: 2),
          ),
        );
        _eventBus.emit(AppEvent.assessmentItemChanged);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showExportDialog() async {
    try {
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
              const Text('将导出所有条目的证明材料，并按条目名称重命名后打包：'),
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
                onPressed: (stats['itemsWithProof'] ?? 0) > 0
                    ? () {
                        Navigator.of(context).pop();
                        _startExport();
                      }
                    : null,
                child: const Text('开始导出'),
              ),
            ] else
              const TextButton(
                onPressed: null,
                child: Text('正在导出...'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取导出信息失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startExport() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!mounted) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportMessage = '准备导出...';
    });

    try {
      final outputPath = await _exportService.exportAllProofMaterials(
        progressCallback: (progress, message) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
              _exportMessage = message;
            });

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                    '导出进度: ${(progress * 100).toStringAsFixed(1)}% - $message'),
                duration: const Duration(milliseconds: 500),
              ),
            );
          }
        },
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已导出所有证明材料: ${outputPath.split('\\').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
            duration: const Duration(seconds: 2),
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

class _AnimatedAppBarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _AnimatedAppBarIcon({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  State<_AnimatedAppBarIcon> createState() => _AnimatedAppBarIconState();
}

class _AnimatedAppBarIconState extends State<_AnimatedAppBarIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * math.pi,
              child: IconButton(
                icon: Icon(widget.icon),
                onPressed: null,
                tooltip: widget.tooltip,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  const _AnimatedFAB({
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<Offset>(
      begin: const Offset(4, 4),
      end: const Offset(2, 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * math.pi,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.memphisPink,
                      AppTheme.memphisYellow,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.memphisBlack,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.memphisBlack.withValues(alpha: 0.3),
                      offset: _shadowAnimation.value,
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = (widget.index % 10) * 50;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? shadowColor;

  const _AnimatedCard({
    required this.child,
    this.onTap,
    this.shadowColor,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 4.0, end: 6.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = widget.shadowColor ?? AppTheme.memphisBlack;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel:
            widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.memphisBlack,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: _isHovered ? 0.3 : 0.15),
                      offset: Offset(_shadowAnimation.value, _shadowAnimation.value),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedPopupMenuButton extends StatefulWidget {
  final VoidCallback onDeleted;

  const _AnimatedPopupMenuButton({
    required this.onDeleted,
  });

  @override
  State<_AnimatedPopupMenuButton> createState() =>
      _AnimatedPopupMenuButtonState();
}

class _AnimatedPopupMenuButtonState extends State<_AnimatedPopupMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  widget.onDeleted();
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
          );
        },
      ),
    );
  }
}

class _AnimatedAttachmentChip extends StatefulWidget {
  final VoidCallback onTap;
  final bool hasImage;
  final bool hasFile;

  const _AnimatedAttachmentChip({
    required this.onTap,
    required this.hasImage,
    required this.hasFile,
  });

  @override
  State<_AnimatedAttachmentChip> createState() =>
      _AnimatedAttachmentChipState();
}

class _AnimatedAttachmentChipState extends State<_AnimatedAttachmentChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
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
                  if (widget.hasImage) ...[
                    const SizedBox(width: AppTheme.spacing4),
                    Icon(
                      Icons.image,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                  if (widget.hasFile) ...[
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
          );
        },
      ),
    );
  }
}

class _MemphisAnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _MemphisAnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  State<_MemphisAnimatedButton> createState() => _MemphisAnimatedButtonState();
}

class _MemphisAnimatedButtonState extends State<_MemphisAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<Offset>(
      begin: const Offset(4, 4),
      end: const Offset(2, 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.memphisBlack,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.3),
                    offset: _shadowAnimation.value,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
