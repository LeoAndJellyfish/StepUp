import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../services/assessment_item_dao.dart';
import '../services/event_bus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final EventBus _eventBus = EventBus();
  
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    // 监听数据变更事件
    _eventBus.on(AppEvent.assessmentItemChanged, _loadStatistics);
  }

  @override
  void dispose() {
    // 移除事件监听
    _eventBus.off(AppEvent.assessmentItemChanged, _loadStatistics);
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _assessmentItemDao.getStatistics();
      
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: '刷新统计数据',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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

    return SingleChildScrollView(
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting！',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '今天也要继续努力提升自己哦！',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    final stats = _statistics!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '总览',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          height: 140, // 固定高度以防止溢出，增加高度以防止数字被遮挡
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: '总条目',
                  value: '${stats['totalCount'] ?? 0}',
                  icon: Icons.assignment,
                  color: Colors.blue,
                  onTap: () => context.go('/assessment'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: StatsCard(
                  title: '总时长',
                  value: '${(stats['totalDuration'] ?? 0.0).toStringAsFixed(1)}h',
                  icon: Icons.access_time,
                  color: Colors.green,
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
        Text(
          '快捷操作',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push('/assessment/add'),
                icon: const Icon(Icons.add),
                label: const Text('添加条目'),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/categories'),
                icon: const Icon(Icons.category),
                label: const Text('管理分类'),
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
        Text(
          '分类统计',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryStats.length,
          itemBuilder: (context, index) {
            final category = categoryStats[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse(category['category_color'].substring(1), radix: 16) + 0xFF000000,
                  ).withValues(alpha: 0.2),
                  child: Icon(
                    Icons.category,
                    color: Color(
                      int.parse(category['category_color'].substring(1), radix: 16) + 0xFF000000,
                    ),
                  ),
                ),
                title: Text(category['category_name'] ?? '未知分类'),
                subtitle: Text('${category['count']} 个条目'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(category['total_duration'] ?? 0.0).toStringAsFixed(1)} 时',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                onTap: () => context.go('/assessment'),
              ),
            );
          },
        ),
      ],
    );
  }
}