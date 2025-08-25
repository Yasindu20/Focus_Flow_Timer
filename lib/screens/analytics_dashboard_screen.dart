import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_dashboard_provider.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/goal_setting_dialog.dart';
import '../widgets/streak_widget.dart';
import '../widgets/efficiency_widget.dart';
import '../widgets/focus_pattern_widget.dart';
import '../widgets/progress_cards.dart';
import '../services/data_export_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsDashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGoalSettingDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnalyticsDashboardProvider>().loadDashboardData(),
          ),
        ],
      ),
      body: Consumer<AnalyticsDashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadDashboardData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.dashboardData == null) {
            return const Center(
              child: Text('No data available. Start some focus sessions!'),
            );
          }

          final data = provider.dashboardData!;

          return RefreshIndicator(
            onRefresh: () => provider.loadDashboardData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Cards
                  ProgressCards(data: data),
                  const SizedBox(height: 24),

                  // Streak and Efficiency Row
                  Row(
                    children: [
                      Expanded(child: StreakWidget(streak: data.streak)),
                      const SizedBox(width: 16),
                      Expanded(child: EfficiencyWidget(efficiency: data.efficiency)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Focus Patterns
                  FocusPatternWidget(focusPatterns: data.focusPatterns),
                  const SizedBox(height: 24),

                  // Daily Report Chart
                  _buildSectionTitle('Daily Sessions (Last 7 Days)'),
                  const SizedBox(height: 16),
                  DailySessionsChart(sessions: data.weeklySessions),
                  const SizedBox(height: 24),

                  // Weekly Report Chart
                  _buildSectionTitle('Weekly Progress'),
                  const SizedBox(height: 16),
                  WeeklyProgressChart(sessions: data.monthlySessions),
                  const SizedBox(height: 24),

                  // Monthly Overview
                  _buildSectionTitle('Monthly Overview'),
                  const SizedBox(height: 16),
                  MonthlyOverviewChart(sessions: data.monthlySessions),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showGoalSettingDialog() {
    final provider = context.read<AnalyticsDashboardProvider>();
    showDialog(
      context: context,
      builder: (context) => GoalSettingDialog(
        currentGoals: provider.dashboardData?.goals,
        onGoalsUpdated: (goals) => provider.updateGoals(goals),
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    final provider = context.read<AnalyticsDashboardProvider>();
    final data = provider.dashboardData;
    
    if (data == null) return;

    try {
      final exportService = DataExportService();
      String? filePath;

      if (format == 'csv') {
        filePath = await exportService.exportToCSV(data);
      } else if (format == 'pdf') {
        filePath = await exportService.exportToPDF(data);
      }

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Content widget for use in tab views
class AnalyticsDashboardContent extends StatefulWidget {
  const AnalyticsDashboardContent({super.key});

  @override
  State<AnalyticsDashboardContent> createState() => _AnalyticsDashboardContentState();
}

class _AnalyticsDashboardContentState extends State<AnalyticsDashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsDashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsDashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.loadDashboardData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.dashboardData == null) {
          return const Center(
            child: Text('No data available. Start some focus sessions!'),
          );
        }

        final data = provider.dashboardData!;

        return RefreshIndicator(
          onRefresh: () => provider.loadDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with quick actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Analytics Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: _showGoalSettingDialog,
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.download),
                          onSelected: _handleExport,
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                            const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Cards
                ProgressCards(data: data),
                const SizedBox(height: 24),

                // Streak and Efficiency Row
                Row(
                  children: [
                    Expanded(child: StreakWidget(streak: data.streak)),
                    const SizedBox(width: 16),
                    Expanded(child: EfficiencyWidget(efficiency: data.efficiency)),
                  ],
                ),
                const SizedBox(height: 24),

                // Focus Patterns
                FocusPatternWidget(focusPatterns: data.focusPatterns),
                const SizedBox(height: 24),

                // Daily Report Chart
                _buildSectionTitle('Daily Sessions (Last 7 Days)'),
                const SizedBox(height: 16),
                DailySessionsChart(sessions: data.weeklySessions),
                const SizedBox(height: 24),

                // Weekly Report Chart
                _buildSectionTitle('Weekly Progress'),
                const SizedBox(height: 16),
                WeeklyProgressChart(sessions: data.monthlySessions),
                const SizedBox(height: 24),

                // Monthly Overview
                _buildSectionTitle('Monthly Overview'),
                const SizedBox(height: 16),
                MonthlyOverviewChart(sessions: data.monthlySessions),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showGoalSettingDialog() {
    final provider = context.read<AnalyticsDashboardProvider>();
    showDialog(
      context: context,
      builder: (context) => GoalSettingDialog(
        currentGoals: provider.dashboardData?.goals,
        onGoalsUpdated: (goals) => provider.updateGoals(goals),
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    final provider = context.read<AnalyticsDashboardProvider>();
    final data = provider.dashboardData;
    
    if (data == null) return;

    try {
      final exportService = DataExportService();
      String? filePath;

      if (format == 'csv') {
        filePath = await exportService.exportToCSV(data);
      } else if (format == 'pdf') {
        filePath = await exportService.exportToPDF(data);
      }

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}