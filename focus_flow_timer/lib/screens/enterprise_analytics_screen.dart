import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/firebase_analytics_provider.dart';
import '../core/constants/colors.dart';
import '../models/enhanced_task.dart';

/// Enterprise Analytics Screen
/// Comprehensive dashboard with AI insights, predictive analytics, and real-time metrics
class EnterpriseAnalyticsScreen extends StatefulWidget {
  const EnterpriseAnalyticsScreen({super.key});

  @override
  State<EnterpriseAnalyticsScreen> createState() => _EnterpriseAnalyticsScreenState();
}

class _EnterpriseAnalyticsScreenState extends State<EnterpriseAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Refresh analytics when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseAnalyticsProvider>().refreshAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enterprise Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Performance'),
            Tab(text: 'Insights'),
            Tab(text: 'Predictions'),
          ],
        ),
      ),
      body: Consumer<FirebaseAnalyticsProvider>(
        builder: (context, analyticsProvider, child) {
          if (analyticsProvider.isLoading) {
            return _buildLoadingState();
          }

          if (analyticsProvider.error != null) {
            return _buildErrorState(analyticsProvider.error!);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(analyticsProvider),
              _buildPerformanceTab(analyticsProvider),
              _buildInsightsTab(analyticsProvider),
              _buildPredictionsTab(analyticsProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExportDialog(),
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading enterprise analytics...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Analytics Error',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<FirebaseAnalyticsProvider>().refreshAnalytics(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(FirebaseAnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRealTimeMetrics(provider),
          const SizedBox(height: 24),
          _buildTodayOverview(provider),
          const SizedBox(height: 24),
          _buildWeeklyTrend(provider),
          const SizedBox(height: 24),
          _buildCategoryBreakdown(provider),
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics(FirebaseAnalyticsProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Real-Time Metrics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Focus Score',
                    '${(provider.todayFocusScore * 100).toInt()}%',
                    provider.focusScoreColor,
                    Icons.psychology,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Sessions',
                    provider.todaySessions.toString(),
                    AppColors.accentColor,
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Focus Time',
                    '${provider.todayMinutes}m',
                    Colors.blue,
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Tasks Done',
                    provider.todayTasks.toString(),
                    Colors.green,
                    Icons.task_alt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview(FirebaseAnalyticsProvider provider) {
    final todayStats = provider.todayStats;
    if (todayStats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Performance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow('Focus Score', provider.focusScoreText, provider.focusScoreColor),
                      _buildStatRow('Productivity Trend', provider.productivityTrend, _getTrendColor(provider.productivityTrend)),
                      _buildStatRow('Interruptions', '${provider.todayInterruptions}', Colors.orange),
                      _buildStatRow('Efficiency', '${((provider.todayMinutes / (provider.todaySessions * 25)).clamp(0, 2) * 50).toInt()}%', Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sections: _buildFocusTimePieData(todayStats),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend(FirebaseAnalyticsProvider provider) {
    if (provider.weeklyStats.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trend',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Text(days[value.toInt() % 7]);
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.weeklyStats.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.averageFocusScore * 100);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(FirebaseAnalyticsProvider provider) {
    final categoryData = provider.categoryPerformance;
    if (categoryData.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(entry.value * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(entry.key),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(_getCategoryColor(entry.key)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab(FirebaseAnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerformanceMetrics(provider),
          const SizedBox(height: 24),
          _buildEfficiencyAnalysis(provider),
          const SizedBox(height: 24),
          _buildInterruptionAnalysis(provider),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(FirebaseAnalyticsProvider provider) {
    final realtimeMetrics = provider.realtimeMetrics;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildPerformanceCard(
                  'Daily Productivity',
                  '${((realtimeMetrics['daily_productivity_score'] ?? 0.0) * 100).toInt()}%',
                  Icons.trending_up,
                  AppColors.primaryColor,
                ),
                _buildPerformanceCard(
                  'Weekly Focus Avg',
                  '${((realtimeMetrics['weekly_average_focus'] ?? 0.0) * 100).toInt()}%',
                  Icons.psychology,
                  Colors.purple,
                ),
                _buildPerformanceCard(
                  'Streak Days',
                  '${realtimeMetrics['streak_days'] ?? 0}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildPerformanceCard(
                  'Efficiency Trend',
                  '${realtimeMetrics['efficiency_trend'] ?? 'Stable'}',
                  Icons.analytics,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyAnalysis(FirebaseAnalyticsProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency Analysis',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI-powered analysis of your productivity patterns and optimization opportunities.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            // This would show detailed efficiency metrics
            _buildAnalysisItem(
              'Peak Performance Hours',
              '9:00 AM - 11:00 AM',
              'You are most productive during morning hours',
              Icons.access_time,
              Colors.green,
            ),
            _buildAnalysisItem(
              'Optimal Session Length',
              '25-30 minutes',
              'Your focus peaks at 25-minute intervals',
              Icons.timer,
              Colors.blue,
            ),
            _buildAnalysisItem(
              'Break Optimization',
              '5-7 minutes',
              'Short breaks maintain your momentum',
              Icons.coffee,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String title, String value, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterruptionAnalysis(FirebaseAnalyticsProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interruption Analysis',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInterruptionMetric(
                    'Today',
                    provider.todayInterruptions.toString(),
                    provider.todayInterruptions <= 3 ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildInterruptionMetric(
                    'Weekly Avg',
                    '4.2',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildInterruptionMetric(
                    'Improvement',
                    '-23%',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recommendations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecommendationItem('Turn off non-essential notifications during focus time'),
            _buildRecommendationItem('Use "Do Not Disturb" mode during peak hours'),
            _buildRecommendationItem('Schedule specific times for checking emails'),
          ],
        ),
      ),
    );
  }

  Widget _buildInterruptionMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(FirebaseAnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAIInsights(provider),
          const SizedBox(height: 24),
          _buildProductivityInsights(provider),
          const SizedBox(height: 24),
          _buildPersonalizedRecommendations(provider),
        ],
      ),
    );
  }

  Widget _buildAIInsights(FirebaseAnalyticsProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              'Productivity Pattern',
              'Your productivity peaks at 10 AM and gradually decreases throughout the day. Consider scheduling important tasks in the morning.',
              Icons.psychology,
              Colors.blue,
            ),
            _buildInsightCard(
              'Task Estimation Accuracy',
              'You tend to underestimate coding tasks by 15% on average. Consider adding buffer time for development work.',
              Icons.precision_manufacturing,
              Colors.orange,
            ),
            _buildInsightCard(
              'Focus Quality',
              'Your focus score improves by 20% when you work on tasks for 2+ hours continuously. Try batching similar tasks.',
              Icons.center_focus_strong,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityInsights(FirebaseAnalyticsProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity Insights',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Time distribution chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _buildTimeDistributionData(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const categories = ['Code', 'Plan', 'Test', 'Doc', 'Meet'];
                          return Text(categories[value.toInt() % categories.length]);
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedRecommendations(FirebaseAnalyticsProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Recommendations',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              'Optimize Your Schedule',
              'Based on your patterns, schedule coding tasks between 9-11 AM for maximum productivity.',
              Icons.schedule,
              Colors.blue,
              'High Impact',
            ),
            _buildRecommendationCard(
              'Reduce Context Switching',
              'Group similar tasks together to maintain flow state and reduce mental overhead.',
              Icons.group_work,
              Colors.green,
              'Medium Impact',
            ),
            _buildRecommendationCard(
              'Improve Task Estimation',
              'Use historical data to improve time estimates - consider adding 20% buffer for complex tasks.',
              Icons.timer,
              Colors.orange,
              'Low Impact',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String description, IconData icon, Color color, String impact) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        impact,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab(FirebaseAnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBurnoutRiskCard(),
          const SizedBox(height: 24),
          _buildProductivityForecast(),
          const SizedBox(height: 24),
          _buildGoalProjections(),
        ],
      ),
    );
  }

  Widget _buildBurnoutRiskCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Burnout Risk Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Low Risk',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Current Status',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Risk Factors:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildRiskFactor('Work-Life Balance', 0.3, Colors.green),
                      _buildRiskFactor('Workload Intensity', 0.6, Colors.orange),
                      _buildRiskFactor('Stress Indicators', 0.2, Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactor(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
          ),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityForecast() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Productivity Forecast',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('W${value.toInt() + 1}');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Actual productivity
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 70),
                        FlSpot(1, 75),
                        FlSpot(2, 73),
                        FlSpot(3, 78),
                      ],
                      isCurved: true,
                      color: AppColors.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                    // Predicted productivity
                    LineChartBarData(
                      spots: [
                        FlSpot(3, 78),
                        FlSpot(4, 80),
                        FlSpot(5, 82),
                        FlSpot(6, 85),
                        FlSpot(7, 83),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProjections() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Projections',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalProjection('Monthly Focus Time Goal', 800, 650, 'minutes'),
            _buildGoalProjection('Task Completion Target', 25, 18, 'tasks'),
            _buildGoalProjection('Productivity Score Goal', 85, 78, '%'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProjection(String title, int target, int current, String unit) {
    final progress = current / target;
    final daysLeft = 30 - DateTime.now().day;
    final projectedValue = (current / DateTime.now().day) * 30;
    final onTrack = projectedValue >= target;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: onTrack ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  onTrack ? 'On Track' : 'Behind',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: onTrack ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(onTrack ? Colors.green : Colors.orange),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current/$target $unit',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              Text(
                'Projected: ${projectedValue.toInt()} $unit',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: onTrack ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for chart data
  List<PieChartSectionData> _buildFocusTimePieData(DailyStats stats) {
    return [
      PieChartSectionData(
        color: AppColors.primaryColor,
        value: stats.totalFocusTime.inMinutes.toDouble(),
        title: 'Focus',
        radius: 50,
      ),
      PieChartSectionData(
        color: AppColors.accentColor,
        value: stats.totalBreakTime.inMinutes.toDouble(),
        title: 'Break',
        radius: 50,
      ),
    ];
  }

  List<BarChartGroupData> _buildTimeDistributionData() {
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 120, color: Colors.blue)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 80, color: Colors.green)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 60, color: Colors.orange)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 40, color: Colors.red)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 90, color: Colors.purple)]),
    ];
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'Improving':
        return Colors.green;
      case 'Declining':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.coding:
        return Colors.blue;
      case TaskCategory.planning:
        return Colors.green;
      case TaskCategory.testing:
        return Colors.orange;
      case TaskCategory.documentation:
        return Colors.purple;
      case TaskCategory.meeting:
        return Colors.red;
      case TaskCategory.research:
        return Colors.teal;
      case TaskCategory.design:
        return Colors.pink;
      case TaskCategory.general:
        return Colors.grey;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Report'),
              onTap: () => _exportData('pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV Data'),
              onTap: () => _exportData('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON Data'),
              onTap: () => _exportData('json'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String format) async {
    Navigator.pop(context);
    
    try {
      final analyticsProvider = context.read<FirebaseAnalyticsProvider>();
      final downloadUrl = await analyticsProvider.exportAnalytics(
        format: format,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analytics exported to $format format'),
            action: SnackBarAction(
              label: 'Download',
              onPressed: () {
                // Open download URL
                debugPrint('Download URL: $downloadUrl');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}