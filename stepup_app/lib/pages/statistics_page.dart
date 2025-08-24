import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
      ),
      body: const Center(
        child: EmptyStateWidget(
          icon: Icons.analytics,
          title: '统计功能开发中',
          subtitle: '敬请期待图表和详细统计分析功能',
        ),
      ),
    );
  }
}