import 'package:flutter/material.dart';
import '../models/analytics_data.dart';

class ProgressCards extends StatelessWidget {
  final DashboardData data;

  const ProgressCards({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final spacing = isSmallScreen ? 8.0 : 16.0;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  context: context,
                  title: 'Today',
                  subtitle: '${data.dailySessions.where((s) => s.isCompleted).length} / ${data.goals?.dailySessions ?? 4} sessions',
                  progress: data.dailyProgress,
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildProgressCard(
                  context: context,
                  title: 'This Week',
                  subtitle: '${(data.weeklyFocusMinutes / 60).toStringAsFixed(1)} / ${data.goals?.weeklyHours ?? 20} hours',
                  progress: data.weeklyProgress,
                  icon: Icons.calendar_view_week,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  context: context,
                  title: 'Focus Time Today',
                  value: '${(data.todayFocusMinutes / 60).toStringAsFixed(1)}h',
                  subtitle: '${data.todayFocusMinutes} minutes',
                  icon: Icons.timer,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatsCard(
                  context: context,
                  title: 'Peak Hour',
                  value: _formatHour(data.peakFocusHour),
                  subtitle: 'Most productive',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 12 : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: isSmallScreen ? 12 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isSmallScreen ? 20 : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 11 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}