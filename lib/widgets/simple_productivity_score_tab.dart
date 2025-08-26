import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/productivity_score_service.dart';

/// A simplified tab-friendly version of ProductivityScoreScreen content
class SimpleProductivityScoreTab extends StatefulWidget {
  const SimpleProductivityScoreTab({super.key});

  @override
  State<SimpleProductivityScoreTab> createState() => _SimpleProductivityScoreTabState();
}

class _SimpleProductivityScoreTabState extends State<SimpleProductivityScoreTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _scoreAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityScoreService>(
      builder: (context, scoreService, child) {
        return Column(
          children: [
            Flexible(
              flex: 0,
              child: _buildScoreHeader(scoreService),
            ),
            Flexible(
              flex: 0,
              child: _buildTabBar(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(scoreService),
                      _buildTrendTab(scoreService),
                      _buildBreakdownTab(scoreService),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreHeader(ProductivityScoreService service) {
    final currentScore = service.currentScore?.dailyScore ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Score',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Text(
                      '${(currentScore * _scoreAnimation.value).toInt()}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: _getScoreColor(currentScore),
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                Text(
                  _getScoreLabel(currentScore),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _getScoreColor(currentScore),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _scoreAnimation.value * (currentScore / 100),
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(currentScore),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
          Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ProductivityScoreService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard('Focus Time Today', '${service.currentScore?.metrics.totalFocusMinutes ?? 0} min', Icons.timer),
          const SizedBox(height: 12),
          _buildMetricCard('Tasks Completed', '${service.currentScore?.metrics.tasksCompleted ?? 0}', Icons.task_alt),
          const SizedBox(height: 12),
          _buildMetricCard('Sessions Done', '${service.currentScore?.metrics.completedSessions ?? 0}', Icons.play_circle),
          const SizedBox(height: 12),
          _buildMetricCard('Weekly Average', '${service.averageWeeklyScore.toStringAsFixed(1)}', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildTrendTab(ProductivityScoreService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    child: service.weeklyTrend.isNotEmpty
                        ? _buildTrendChart(service.weeklyTrend)
                        : const Center(child: Text('No trend data available')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    child: service.monthlyTrend.isNotEmpty
                        ? _buildTrendChart(service.monthlyTrend)
                        : const Center(child: Text('No trend data available')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab(ProductivityScoreService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildBreakdownItem('Focus Time', 40, Colors.blue),
                  _buildBreakdownItem('Task Completion', 30, Colors.green),
                  _buildBreakdownItem('Session Consistency', 20, Colors.orange),
                  _buildBreakdownItem('Achievement Bonus', 10, Colors.purple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<double> data) {
    // Simple bar chart representation
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.asMap().entries.map((entry) {
        final value = entry.value;
        final normalizedHeight = (value / 100) * 150; // Max height 150
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              value.toInt().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: normalizedHeight.clamp(10, 150),
              decoration: BoxDecoration(
                color: _getScoreColor(value),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'D${entry.key + 1}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBreakdownItem(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${percentage.toInt()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.yellow[700] ?? Colors.yellow;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    return 'Needs Improvement';
  }
}