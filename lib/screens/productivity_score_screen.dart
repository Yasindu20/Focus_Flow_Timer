import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/productivity_score.dart';
import '../services/productivity_score_service.dart';

class ProductivityScoreScreen extends StatefulWidget {
  const ProductivityScoreScreen({super.key});

  @override
  State<ProductivityScoreScreen> createState() => _ProductivityScoreScreenState();
}

class _ProductivityScoreScreenState extends State<ProductivityScoreScreen>
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductivityScoreService>(context, listen: false).initialize();
      _scoreAnimationController.forward();
    });
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Productivity Score'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () => _showInsights(context, scoreService),
                icon: const Icon(Icons.lightbulb),
                tooltip: 'Insights',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreHeader(ProductivityScoreService service) {
    final currentScore = service.currentScore;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getScoreGradientColors(currentScore?.dailyScore ?? 0),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final animatedScore = (currentScore?.dailyScore ?? 0) * _scoreAnimation.value;
              return Column(
                children: [
                  Text(
                    animatedScore.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    currentScore?.scoreGrade ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            currentScore?.scoreDescription ?? 'Complete sessions to get your score',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildScoreMetric(
                    'Weekly Avg',
                    service.averageWeeklyScore.toInt().toString(),
                    Icons.calendar_view_week,
                  ),
                ),
                Flexible(
                  child: _buildScoreMetric(
                    'Trend',
                    _getTrendIcon(currentScore?.trend ?? ProductivityTrend.stable),
                    _getTrendIconData(currentScore?.trend ?? ProductivityTrend.stable),
                  ),
                ),
                Flexible(
                  child: _buildScoreMetric(
                    'Monthly Avg',
                    service.averageMonthlyScore.toInt().toString(),
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Trends'),
          Tab(text: 'Breakdown'),
        ],
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Widget _buildOverviewTab(ProductivityScoreService service) {
    final insights = service.getProductivityInsights();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightsCard(insights),
          const SizedBox(height: 16),
          _buildQuickStatsCard(service),
          const SizedBox(height: 16),
          _buildWeeklyProgressCard(service),
        ],
      ),
    );
  }

  Widget _buildTrendTab(ProductivityScoreService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyTrendChart(service),
          const SizedBox(height: 16),
          _buildMonthlyTrendChart(service),
          const SizedBox(height: 16),
          _buildTrendAnalysis(service),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab(ProductivityScoreService service) {
    final breakdown = service.getScoreBreakdown();
    
    if (breakdown.isEmpty) {
      return _buildEmptyState(
        icon: Icons.analytics_outlined,
        title: 'No score breakdown available',
        subtitle: 'Complete some focus sessions to see your detailed breakdown',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreComponentsCard(breakdown),
          const SizedBox(height: 16),
          _buildMetricsCard(breakdown),
          const SizedBox(height: 16),
          _buildCategoryScoresCard(breakdown),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic> insights) {
    final insightsList = List<String>.from(insights['insights'] ?? []);
    final suggestionsList = List<String>.from(insights['suggestions'] ?? []);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insightsList.isNotEmpty) ...[
              ...insightsList.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(insight)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (suggestionsList.isNotEmpty) ...[
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...suggestionsList.map((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_forward, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(suggestion)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(ProductivityScoreService service) {
    final currentScore = service.currentScore;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (currentScore != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Sessions',
                      '${currentScore.metrics.completedSessions}/${currentScore.metrics.totalSessions}',
                      Icons.play_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Focus Time',
                      '${currentScore.metrics.totalFocusMinutes}m',
                      Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Perfect Sessions',
                      '${currentScore.metrics.perfectSessions}',
                      Icons.star,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Streak',
                      '${currentScore.metrics.streakDays} days',
                      Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No activity today yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressCard(ProductivityScoreService service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 150,
                maxHeight: 200,
              ),
              child: _buildWeeklyBarChart(service),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(ProductivityScoreService service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 250,
              ),
              child: _buildLineChart(service.weeklyTrend, 'Weekly'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(ProductivityScoreService service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 250,
              ),
              child: _buildLineChart(service.monthlyTrend, 'Monthly'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreComponentsCard(Map<String, dynamic> breakdown) {
    final components = List<Map<String, dynamic>>.from(breakdown['components'] ?? []);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...components.map((component) => _buildComponentRow(component)),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentRow(Map<String, dynamic> component) {
    final name = component['name'] as String;
    final value = (component['value'] as num).toDouble();
    final type = component['type'] as String;
    final description = component['description'] as String;
    
    Color color = Colors.blue;
    IconData icon = Icons.add;
    
    if (type == 'bonus') {
      color = Colors.green;
      icon = Icons.add;
    } else if (type == 'penalty') {
      color = Colors.red;
      icon = Icons.remove;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(Map<String, dynamic> breakdown) {
    final metrics = breakdown['metrics'] as Map<String, dynamic>? ?? {};
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricTile(
                  'Completion Rate',
                  '${(metrics['completion_rate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
                _buildMetricTile(
                  'Perfect Rate',
                  '${(metrics['perfect_rate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.star,
                ),
                _buildMetricTile(
                  'Focus Minutes',
                  '${metrics['focus_minutes'] ?? 0}m',
                  Icons.timer,
                ),
                _buildMetricTile(
                  'Tasks Done',
                  '${metrics['tasks_completed'] ?? 0}',
                  Icons.task_alt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScoresCard(Map<String, dynamic> breakdown) {
    final categoryScores = Map<String, double>.from(breakdown['category_scores'] ?? {});
    
    if (categoryScores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...categoryScores.entries.map((entry) => _buildCategoryRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String category, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${score.toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(ProductivityScoreService service) {
    final weeklyScores = service.weeklyScores;
    
    if (weeklyScores.isEmpty) {
      return const Center(
        child: Text('No weekly data available'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weeklyScores.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.dailyScore,
                color: _getScoreColor(entry.value.dailyScore),
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<double> data, String period) {
    if (data.isEmpty) {
      return Center(
        child: Text('No $period data available'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis(ProductivityScoreService service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Based on your recent productivity patterns, here are some observations:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Add trend analysis based on data
            const Text('• Your productivity tends to be highest on weekdays'),
            const SizedBox(height: 4),
            const Text('• Morning sessions show better completion rates'),
            const SizedBox(height: 4),
            const Text('• Consistency is key to maintaining high scores'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsights(BuildContext context, ProductivityScoreService service) {
    final insights = service.getProductivityInsights();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lightbulb,
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Productivity Insights',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...List<String>.from(insights['insights'] ?? []).map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(insight),
                ),
              ),
              if (List<String>.from(insights['suggestions'] ?? []).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...List<String>.from(insights['suggestions'] ?? []).map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $suggestion'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getScoreGradientColors(double score) {
    if (score >= 90) {
      return [Colors.green[400]!, Colors.green[600]!];
    } else if (score >= 80) {
      return [Colors.lightGreen[400]!, Colors.lightGreen[600]!];
    } else if (score >= 70) {
      return [Colors.orange[400]!, Colors.orange[600]!];
    } else if (score >= 60) {
      return [Colors.amber[400]!, Colors.amber[600]!];
    } else {
      return [Colors.red[400]!, Colors.red[600]!];
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.amber;
    return Colors.red;
  }

  String _getTrendIcon(ProductivityTrend trend) {
    switch (trend) {
      case ProductivityTrend.improving:
        return '↗️';
      case ProductivityTrend.declining:
        return '↘️';
      case ProductivityTrend.stable:
        return '→';
    }
  }

  IconData _getTrendIconData(ProductivityTrend trend) {
    switch (trend) {
      case ProductivityTrend.improving:
        return Icons.trending_up;
      case ProductivityTrend.declining:
        return Icons.trending_down;
      case ProductivityTrend.stable:
        return Icons.trending_flat;
    }
  }
}