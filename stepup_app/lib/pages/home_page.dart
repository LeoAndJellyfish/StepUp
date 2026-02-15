import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/classification_scheme_dao.dart';
import '../services/event_bus.dart';
import '../services/user_dao.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();
  final EventBus _eventBus = EventBus();
  final UserDao _userDao = UserDao();

  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;
  String? _userName;

  late AnimationController _mainAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    );

    _loadStatistics();
    _loadUserName();
    _eventBus.on(AppEvent.assessmentItemChanged, _loadStatistics);
    _eventBus.on(AppEvent.schemeChanged, _loadStatistics);
  }

  Future<void> _loadUserName() async {
    try {
      final user = await _userDao.getFirstUser();
      if (user != null) {
        setState(() {
          _userName = user.name;
        });
      }
    } catch (e) {
      debugPrint('加载用户名失败: $e');
    }
  }

  @override
  void dispose() {
    _eventBus.off(AppEvent.assessmentItemChanged, _loadStatistics);
    _eventBus.off(AppEvent.schemeChanged, _loadStatistics);
    _mainAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 获取当前激活的方案
      final activeScheme = await _schemeDao.getActiveScheme();

      // 根据当前方案获取分类
      List<Category> categories;
      if (activeScheme != null) {
        categories = await _categoryDao.getCategoriesBySchemeId(activeScheme.id!);
      } else {
        categories = await _categoryDao.getAllCategories();
      }

      // 获取当前方案下的分类ID列表
      final categoryIds = categories.map((c) => c.id).whereType<int>().toList();

      // 加载统计（只统计当前方案下的条目）
      final stats = categoryIds.isEmpty
          ? {'totalCount': 0, 'totalDuration': 0.0, 'awardedCount': 0, 'categoryStats': <Map<String, dynamic>>[]}
          : await _assessmentItemDao.getStatistics(categoryIds: categoryIds);

      setState(() {
        _statistics = stats;
        _isLoading = false;
      });

      _mainAnimationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = '加载统计数据失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StepUp 综合测评'),
        actions: [
          _AnimatedAppBarIcon(
            icon: Icons.refresh,
            onPressed: _loadStatistics,
            tooltip: '刷新统计数据',
          ),
          _AnimatedAppBarIcon(
            icon: Icons.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
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
        onRetry: _loadStatistics,
      );
    }

    if (_statistics == null) {
      return const EmptyStateWidget(
        icon: Icons.analytics,
        title: '暂无数据',
        subtitle: '开始添加您的综测条目吧！',
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(_fadeAnimation),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: AppTheme.spacing24),
              _buildOverviewStats(),
              const SizedBox(height: AppTheme.spacing24),
              _buildQuickActions(),
              const SizedBox(height: AppTheme.spacing24),
              _buildCategoryStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 6) {
      greeting = '夜深了';
    } else if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return _AnimatedCard(
      index: 0,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
                          color: AppTheme.memphisBlack.withValues(alpha: 0.15),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting，${_userName ?? '同学'}！',
                          style: AppTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          '每一步努力，都是成长的足迹！',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
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

  Widget _buildOverviewStats() {
    final stats = _statistics!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
          child: Text(
            '总览',
            style: AppTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: _AnimatedCard(
                  index: 1,
                  child: _AnimatedStatsCard(
                    title: '总条目',
                    value: '${stats['totalCount'] ?? 0}',
                    icon: Icons.assignment,
                    color: AppTheme.memphisBlue,
                    onTap: () => context.go('/assessment'),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _AnimatedCard(
                  index: 2,
                  child: _AnimatedStatsCard(
                    title: '总时长',
                    value: '${(stats['totalDuration'] ?? 0.0).toStringAsFixed(1)}h',
                    icon: Icons.access_time,
                    color: AppTheme.memphisGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
          child: Text(
            '快捷操作',
            style: AppTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _AnimatedCard(
                index: 3,
                child: _MemphisActionButton(
                  onPressed: () => context.push('/assessment/add'),
                  icon: Icons.add,
                  label: '添加条目',
                  backgroundColor: AppTheme.memphisPink,
                  isFilled: true,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _AnimatedCard(
                index: 4,
                child: _MemphisActionButton(
                  onPressed: () => context.go('/categories'),
                  icon: Icons.category,
                  label: '管理分类',
                  backgroundColor: AppTheme.memphisYellow,
                  isFilled: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryStats() {
    final categoryStats = _statistics!['categoryStats'] as List<Map<String, dynamic>>;

    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
          child: Text(
            '分类统计',
            style: AppTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryStats.length,
          itemBuilder: (context, index) {
            final category = categoryStats[index];
            return _AnimatedCard(
              index: 5 + index,
              child: _AnimatedCategoryCard(
                category: category,
                onTap: () => context.go('/assessment'),
              ),
            );
          },
        ),
      ],
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

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedCard({
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = widget.index * 80;
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
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
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
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AnimatedStatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_AnimatedStatsCard> createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<_AnimatedStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
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

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.memphisBlack,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      offset: Offset(_shadowAnimation.value, _shadowAnimation.value),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.color,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          if (widget.onTap != null)
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: theme.colorScheme.outline,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Flexible(
                        child: Text(
                          widget.value,
                          style: AppTheme.headlineSmall.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Flexible(
                        child: Text(
                          widget.title,
                          style: AppTheme.bodySmall.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCategoryCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback? onTap;

  const _AnimatedCategoryCard({
    required this.category,
    this.onTap,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
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
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(
      int.parse(widget.category['category_color'].substring(1), radix: 16) + 0xFF000000,
    );

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
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
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
                      color: categoryColor.withValues(alpha: _isHovered ? 0.3 : 0.15),
                      offset: Offset(_isHovered ? 5 : 4, _isHovered ? 5 : 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.category,
                          color: categoryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category['category_name'] ?? '未知分类',
                              style: AppTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              '${widget.category['count']} 个条目',
                              style: AppTheme.bodySmall.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(widget.category['total_duration'] ?? 0.0).toStringAsFixed(1)} 时',
                            style: AppTheme.titleSmall.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MemphisActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final bool isFilled;

  const _MemphisActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.isFilled,
  });

  @override
  State<_MemphisActionButton> createState() => _MemphisActionButtonState();
}

class _MemphisActionButtonState extends State<_MemphisActionButton>
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: widget.isFilled ? widget.backgroundColor : null,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isFilled ? Colors.white : AppTheme.memphisBlack,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isFilled ? Colors.white : AppTheme.memphisBlack,
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
