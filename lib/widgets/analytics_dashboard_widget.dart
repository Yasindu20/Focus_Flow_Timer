import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class AnalyticsDashboardWidget extends StatefulWidget {
  const AnalyticsDashboardWidget({super.key});

  @override
  State<AnalyticsDashboardWidget> createState() => _AnalyticsDashboardWidgetState();
}

class _AnalyticsDashboardWidgetState extends State<AnalyticsDashboardWidget> {
  Map<String, dynamic>? _insights;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final insights = await provider.getProductivityInsights();
      
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Analytics Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Content
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_insights != null)
              _buildAnalyticsContent()
            else
              const Center(child: Text('No analytics data available')),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return Column(
      children: [
        // Basic metrics grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Tasks',
              '${_insights!['totalTasks'] ?? 0}',
              Icons.task_alt,
              Colors.blue,
            ),
            _buildMetricCard(
              'Completion Rate',
              '${((_insights!['completionRate'] ?? 0.0) * 100).toInt()}%',
              Icons.check_circle,
              Colors.green,
            ),
            _buildMetricCard(
              'Avg Duration',
              '${_insights!['averageDuration'] ?? 0}m',
              Icons.timer,
              Colors.orange,
            ),
            _buildMetricCard(
              'Pomodoros',
              '${_insights!['totalPomodoros'] ?? 0}',
              Icons.circle,
              Colors.red,
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Category breakdown
        if (_insights!['categoryBreakdown'] != null)
          _buildCategoryBreakdown(),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoryData = _insights!['categoryBreakdown'] as Map<String, dynamic>;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...categoryData.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}