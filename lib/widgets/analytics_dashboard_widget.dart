import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
 import '../providers/smart_task_provider.dart';
 import '../models/task_analytics.dart';
 import '../core/constants/colors.dart';
 import 'package:fl_chart/fl_chart.dart';
 class AnalyticsDashboardWidget extends StatefulWidget {
  const AnalyticsDashboardWidget({super.key});
  @override
  State<AnalyticsDashboardWidget> createState() => _AnalyticsDashboardWidgetState();
 }
 class _AnalyticsDashboardWidgetState extends State<AnalyticsDashboardWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();
  ProductivityInsights? _insights;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final provider = Provider.of<SmartTaskProvider>(context, listen: false);
      final insights = await provider.getProductivityInsights(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
      
      setState(() {
        _insights = insights;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
 } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildDateRangePicker(),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _insights == null
                  ? _buildEmptyState()
                  : _buildDashboard(),
        ),
      ],
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 28,
                ),
 const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Productivity Analytics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _exportAnalytics,
                  icon: const Icon(Icons.download, color: Colors.white),
                ),
                IconButton(
                  onPressed: _refreshAnalytics,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Performance'),
                Tab(text: 'Trends'),
                Tab(text: 'AI Insights'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDateRangePicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
 ),
      child: Row(
        children: [
          const Icon(Icons.date_range),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year} - ${_selectedEndDate.day}/${
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: _selectDateRange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
  Widget _buildDashboard() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildPerformanceTab(),
        _buildTrendsTab(),
        _buildAIInsightsTab(),
      ],
    );
  }
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          _buildProductivityChart(),
          const SizedBox(height: 24),
          _buildCategoryDistribution(),
        ],
      ),
    );
  }
 Widget _buildMetricsGrid() {
    final metrics = _insights!.metrics;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Tasks Completed',
          '${metrics.completedTasks}',
          Icons.check_circle,
          AppColors.success,
          subtitle: 'of ${metrics.totalTasks} total',
        ),
        _buildMetricCard(
          'Productivity Score',
          '${metrics.productivityScore.round()}%',
          Icons.trending_up,
          AppColors.primaryBlue,
          subtitle: _getProductivityLabel(metrics.productivityScore),
        ),
        _buildMetricCard(
          'Focus Time',
          _formatDuration(metrics.focusTime),
          Icons.psychology,
          AppColors.warning,
          subtitle: 'Daily average',
        ),
        _buildMetricCard(
          'Tasks per Day',
          '${metrics.tasksPerDay.toStringAsFixed(1)}',
          Icons.calendar_today,
          AppColors.info,
          subtitle: 'Average completion',
        ),
      ],
    );
  }
  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
 Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
 if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildProductivityChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productivity Over Time',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
 getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateProductivitySpots(),
                    isCurved: true,
                    color: AppColors.primaryBlue,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCategoryDistribution() {
    return Container(
      height: 300,
 padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Distribution by Category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: _generateCategorySections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildCategoryLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
 child: Column(
        children: [
          _buildEfficiencyMetrics(),
          const SizedBox(height: 24),
          _buildEstimationAccuracy(),
          const SizedBox(height: 24),
          _buildFocusAnalysis(),
        ],
      ),
    );
  }
  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTrendChart('Daily Productivity', _generateDailyTrend()),
          const SizedBox(height: 24),
          _buildTrendChart('Weekly Performance', _generateWeeklyTrend()),
          const SizedBox(height: 24),
          _buildOptimalWorkTimes(),
        ],
      ),
    );
  }
  Widget _buildAIInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAIRecommendations(),
          const SizedBox(height: 24),
          _buildPredictiveAnalytics(),
          const SizedBox(height: 24),
          _buildOptimizationOpportunities(),
        ],
      ),
    );
  }
  Widget _buildEfficiencyMetrics() {
    final efficiency = _insights!.efficiency;
    
    return Container(
      padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Efficiency Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildEfficiencyBar('Overall Efficiency', efficiency.overall, AppColors.primaryBlue),
          const SizedBox(height: 12),
          _buildEfficiencyBar('Estimation Accuracy', efficiency.estimation, AppColors.success),
          const SizedBox(height: 12),
          _buildEfficiencyBar('Focus Score', efficiency.focus, AppColors.warning),
          const SizedBox(height: 12),
          _buildEfficiencyBar('Consistency', efficiency.consistency, AppColors.info),
          const SizedBox(height: 12),
          _buildEfficiencyBar('Time Management', efficiency.timeManagement, AppColors.primaryDark),
        ],
      ),
    );
  }
  Widget _buildEfficiencyBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${(value * 100).round()}%', 
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                   color: color,
 )),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
  Widget _buildEstimationAccuracy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimation Accuracy Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Add estimation accuracy visualization
          Text(
            'Your estimation accuracy has improved by 15% this month.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
Widget _buildFocusAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Add focus analysis visualization
          Text(
            'Your focus score is highest during morning hours (9-11 AM).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  Widget _buildTrendChart(String title, List<FlSpot> spots) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryBlue,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOptimalWorkTimes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
 color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimal Work Times',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Add optimal work times visualization
          _buildTimeSlot('Morning', '9:00 - 11:00 AM', 0.9, AppColors.success),
          const SizedBox(height: 8),
          _buildTimeSlot('Afternoon', '2:00 - 4:00 PM', 0.7, AppColors.warning),
          const SizedBox(height: 8),
          _buildTimeSlot('Evening', '7:00 - 9:00 PM', 0.5, AppColors.error),
        ],
      ),
    );
  }
  Widget _buildTimeSlot(String period, String time, double efficiency, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(period, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
              Text(time, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: efficiency,
            backgroundColor: Colors.grey.withOpacity(0.2),
 valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(efficiency * 100).round()}%'),
      ],
    );
  }
  Widget _buildAIRecommendations() {
    final recommendations = _insights!.recommendations;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.take(5).map((rec) => _buildRecommendationCard(rec)),
        ],
      ),
    );
  }
Widget _buildRecommendationCard(ProductivityRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getRecommendationColor(recommendation.impact).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRecommendationColor(recommendation.impact).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRecommendationIcon(recommendation.type),
                size: 16,
                color: _getRecommendationColor(recommendation.impact),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRecommendationColor(recommendation.impact),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  recommendation.impact.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  Widget _buildPredictiveAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Predictive Analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPredictionCard(
            'Next Week Productivity',
            '85%',
            'Based on current trends',
            Icons.timeline,
            AppColors.success,
          ),
const SizedBox(height: 12),
          _buildPredictionCard(
            'Burnout Risk',
            'Low',
            'Maintain current pace',
            Icons.battery_std,
            AppColors.info,
          ),
        ],
      ),
    );
  }
  Widget _buildPredictionCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOptimizationOpportunities() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Optimization Opportunities',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOptimizationCard(
            'Break Down Large Tasks',
            'Tasks over 60 minutes show 23% lower completion rates',
            'Save 45 min/week',AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildOptimizationCard(
            'Schedule High-Priority Tasks Early',
            'Morning tasks have 67% higher success rate',
            'Save 30 min/week',
            AppColors.info,
          ),
        ],
      ),
    );
  }
  Widget _buildOptimizationCard(
    String title,
    String description,
    String savings,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
savings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No analytics data available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some tasks to see your productivity insights',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
);
  }
  Widget _buildCategoryLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: TaskCategory.values.take(5).map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  // Helper Methods
  List<FlSpot> _generateProductivitySpots() {
    // Generate sample productivity data
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), 60 + (index * 5) + (index % 2 * 10));
    });
  }
  List<PieChartSectionData> _generateCategorySections() {
    final categories = TaskCategory.values.take(5).toList();
    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
 return PieChartSectionData(
        value: (index + 1) * 20.0,
        color: _getCategoryColor(category),
        title: '${((index + 1) * 20).round()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  List<FlSpot> _generateDailyTrend() {
    return List.generate(30, (index) {
      return FlSpot(index.toDouble(), 50 + (index % 7) * 10 + (index % 3) * 5);
    });
  }
  List<FlSpot> _generateWeeklyTrend() {
    return List.generate(12, (index) {
      return FlSpot(index.toDouble(), 60 + (index % 4) * 15);
    });
  }
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.coding:
        return AppColors.primaryBlue;
      case TaskCategory.writing:
        return AppColors.success;
      case TaskCategory.meeting:
        return AppColors.warning;
      case TaskCategory.research:
        return AppColors.info;
      case TaskCategory.design:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
  String _getProductivityLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Fair';
 return 'Needs Improvement';
  }
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  Color _getRecommendationColor(RecommendationImpact impact) {
    switch (impact) {
      case RecommendationImpact.high:
        return AppColors.error;
      case RecommendationImpact.medium:
        return AppColors.warning;
      case RecommendationImpact.low:
        return AppColors.info;
    }
  }
  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.focusTime:
        return Icons.psychology;
      case RecommendationType.estimation:
        return Icons.timer;
      case RecommendationType.scheduling:
        return Icons.schedule;
      case RecommendationType.breaks:
        return Icons.pause;
      case RecommendationType.taskSize:
        return Icons.cut;
    }
  }
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
 ),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _loadAnalytics();
    }
  }
  Future<void> _refreshAnalytics() async {
    await _loadAnalytics();
  }
  Future<void> _exportAnalytics() async {
    try {
      final provider = Provider.of<SmartTaskProvider>(context, listen: false);
      final exportData = await provider.exportAnalytics(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        metrics: [
          'productivity_score',
          'estimation_accuracy',
          'task_completion_rate',
          'time_distribution',
          'category_performance',
        ],
      );
      // Show export success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analytics exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
 );
      }
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 }