import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../models/classification_scheme.dart';
import '../services/classification_scheme_dao.dart';
import '../services/event_bus.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class ClassificationSchemesPage extends StatefulWidget {
  const ClassificationSchemesPage({super.key});

  @override
  State<ClassificationSchemesPage> createState() => _ClassificationSchemesPageState();
}

class _ClassificationSchemesPageState extends State<ClassificationSchemesPage> {
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();
  final EventBus _eventBus = EventBus();
  List<ClassificationScheme> _schemes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final schemes = await _schemeDao.getAllSchemes();
      
      setState(() {
        _schemes = schemes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载分类方案失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _setActiveScheme(ClassificationScheme scheme) async {
    if (scheme.isActive) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('切换分类方案'),
        content: Text('确定要将「${scheme.name}」设为当前使用的分类方案吗？\n\n切换后，新增条目将使用新的分类体系。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _schemeDao.setActiveScheme(scheme.id!);
      await _loadSchemes();

      // 发送方案切换事件，通知所有页面刷新
      debugPrint('ClassificationSchemesPage: 发送方案切换事件');
      _eventBus.emit(AppEvent.schemeChanged);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到「${scheme.name}」'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteScheme(ClassificationScheme scheme) async {
    if (scheme.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('默认方案不能删除'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final hasItems = await _schemeDao.hasActiveItems(scheme.id!);
    
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类方案'),
        content: Text(
          hasItems
              ? '该方案下有相关条目，删除后这些条目的分类信息将丢失。确定要删除「${scheme.name}」吗？'
              : '确定要删除「${scheme.name}」吗？此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _schemeDao.deleteScheme(scheme.id!);
      await _loadSchemes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除分类方案'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '创建分类方案',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text('手动创建'),
              subtitle: const Text('自定义创建分类方案'),
              onTap: () {
                Navigator.of(context).pop();
                _createManualScheme();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                ),
              ),
              title: const Text('AI 识别'),
              subtitle: const Text('上传综测文件自动识别分类'),
              onTap: () {
                Navigator.of(context).pop();
                _createAIScheme();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createManualScheme() async {
    final result = await context.push('/settings/schemes/create');
    if (result == true) {
      _loadSchemes();
    }
  }

  Future<void> _createAIScheme() async {
    final result = await context.push('/settings/document-analysis');
    if (result == true) {
      _loadSchemes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类方案管理'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchemes,
        child: _buildBody(),
      ),
      floatingActionButton: _AnimatedFAB(
        onPressed: _showCreateOptions,
        icon: Icons.add,
        tooltip: '创建分类方案',
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
        onRetry: _loadSchemes,
      );
    }

    if (_schemes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.account_tree,
        title: '暂无分类方案',
        subtitle: '系统会自动创建默认方案',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      itemCount: _schemes.length,
      itemBuilder: (context, index) {
        final scheme = _schemes[index];
        return _buildSchemeCard(scheme);
      },
    );
  }

  Widget _buildSchemeCard(ClassificationScheme scheme) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: InkWell(
        onTap: () async {
          final result = await context.push('/settings/schemes/detail/${scheme.id}');
          if (result == true) {
            _loadSchemes();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.isActive
                          ? AppTheme.memphisGreen.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_tree,
                      color: scheme.isActive
                          ? AppTheme.memphisGreen
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              scheme.name,
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (scheme.isActive) ...[
                              const SizedBox(width: AppTheme.spacing8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.memphisGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '当前使用',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.memphisGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (scheme.isDefault) ...[
                              const SizedBox(width: AppTheme.spacing8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.memphisBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '默认',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.memphisBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          scheme.code,
                          style: AppTheme.bodySmall.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'activate') {
                        _setActiveScheme(scheme);
                      } else if (value == 'delete') {
                        _deleteScheme(scheme);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!scheme.isActive)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text('设为当前方案'),
                            ],
                          ),
                        ),
                      if (!scheme.isDefault)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      if (scheme.isActive && scheme.isDefault)
                        const PopupMenuItem(
                          enabled: false,
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('默认方案不可操作', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (scheme.description.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  scheme.description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppTheme.spacing12),
              FutureBuilder<int>(
                future: _schemeDao.getItemCount(scheme.id!),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count 个条目',
                        style: AppTheme.bodySmall.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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
                  gradient: const LinearGradient(
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
