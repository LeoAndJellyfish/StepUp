import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../models/level.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/level_dao.dart';
import '../services/event_bus.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final LevelDao _levelDao = LevelDao();
  final EventBus _eventBus = EventBus();
  
  Map<String, dynamic>? _overallStats;
  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> _levelStats = [];
  
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
    
    // 监听评估条目变更事件，自动刷新统计数据
    _eventBus.on(AppEvent.assessmentItemChanged, _loadStatistics);
  }
  
  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // 加载基础数据
      final categories = await _categoryDao.getAllCategories();
      final levels = await _levelDao.getAllLevels();
      
      // 加载综合统计
      final overallStats = await _assessmentItemDao.getStatistics();
      
      // 加载各分类统计
      List<Map<String, dynamic>> categoryStats = [];
      for (final category in categories) {
        final stats = await _assessmentItemDao.getStatistics(categoryId: category.id!);
        if (stats['totalCount'] > 0) {
          categoryStats.add({
            'category': category,
            'stats': stats,
          });
        }
      }
      
      // 统计各级别数据
      List<Map<String, dynamic>> levelStats = [];
      for (final level in levels) {
        final items = await _assessmentItemDao.getAllItems(levelId: level.id);
        if (items.isNotEmpty) {
          final totalScore = items.fold<double>(0, (sum, item) => sum + item.score);
          final totalDuration = items.fold<double>(0, (sum, item) => sum + item.duration);
          levelStats.add({
            'level': level,
            'count': items.length,
            'totalScore': totalScore,
            'totalDuration': totalDuration,
            'avgScore': totalScore / items.length,
          });
        }
      }
      
      setState(() {
        _overallStats = overallStats;
        _categoryStats = categoryStats;
        _levelStats = levelStats;
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
  void dispose() {
    // 移除事件监听器
    _eventBus.off(AppEvent.assessmentItemChanged, _loadStatistics);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
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
      return const LoadingWidget(message: '加载统计数据中...');
    }
    
    if (_error != null) {
      return ErrorStateWidget(
        title: '加载失败',
        subtitle: _error,
        onRetry: _loadStatistics,
      );
    }
    
    if (_overallStats == null || _overallStats!['totalCount'] == 0) {
      return const EmptyStateWidget(
        icon: Icons.analytics,
        title: '暂无数据',
        subtitle: '请先添加一些综测条目再查看统计分析',
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStats(),
          const SizedBox(height: AppTheme.spacing24),
          _buildCategoryStats(),
          const SizedBox(height: AppTheme.spacing24),
          _buildLevelStats(),
          const SizedBox(height: AppTheme.spacing24),
        ],
      ),
    );
  }
  
  Widget _buildOverallStats() {
    final stats = _overallStats!;
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '综合数据概览',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '条目数量',
                    '${stats['totalCount']}',
                    '个',
                    Icons.assignment,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildStatCard(
                    '总分数',
                    '${(stats['totalScore'] ?? 0.0).toStringAsFixed(1)}',
                    '分',
                    Icons.star,
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '总时长',
                    '${(stats['totalDuration'] ?? 0.0).toStringAsFixed(1)}',
                    '小时',
                    Icons.access_time,
                    theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildStatCard(
                    '平均分数',
                    '${stats['totalCount'] > 0 ? ((stats['totalScore'] ?? 0.0) / stats['totalCount']).toStringAsFixed(1) : '0.0'}',
                    '分',
                    Icons.trending_up,
                    theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTheme.titleLarge.copyWith(color: color),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTheme.bodyMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '各维度统计',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (_categoryStats.isEmpty)
              const Text('暂无数据')
            else
              ..._categoryStats.map((data) {
                final category = data['category'] as Category;
                final stats = data['stats'] as Map<String, dynamic>;
                return _buildCategoryStatItem(category, stats);
              }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryStatItem(Category category, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  '${category.name} (${category.code})',
                  style: AppTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Expanded(
                child: Text('条目数: ${stats['totalCount']}')),
              Expanded(
                child: Text('得分: ${(stats['totalScore'] ?? 0.0).toStringAsFixed(1)}')),
              Expanded(
                child: Text('时长: ${(stats['totalDuration'] ?? 0.0).toStringAsFixed(1)}h')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLevelStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '级别分布统计',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (_levelStats.isEmpty)
              const Text('暂无数据')
            else
              ..._levelStats.map((data) {
                final level = data['level'] as Level;
                return _buildLevelStatItem(level, data);
              }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLevelStatItem(Level level, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.name,
                  style: AppTheme.titleSmall,
                ),
                Text(
                  '系数: ${level.scoreMultiplier}',
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text('数量: ${stats['count']}')),
          Expanded(
            child: Text('得分: ${(stats['totalScore']).toStringAsFixed(1)}')),
          Expanded(
            child: Text('平均: ${(stats['avgScore']).toStringAsFixed(1)}')),
        ],
      ),
    );
  }
}