import 'package:flutter/material.dart';

class FocusPatternWidget extends StatelessWidget {
  final Map<int, int> focusPatterns;

  const FocusPatternWidget({super.key, required this.focusPatterns});

  @override
  Widget build(BuildContext context) {
    final maxSessions = focusPatterns.values.isNotEmpty 
        ? focusPatterns.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Focus Patterns',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your most productive hours',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _buildHourlyBars(maxSessions),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeLabels(),
        ],
      ),
    );
  }

  List<Widget> _buildHourlyBars(int maxSessions) {
    final bars = <Widget>[];
    
    for (int hour = 0; hour < 24; hour++) {
      final sessions = focusPatterns[hour] ?? 0;
      final height = maxSessions > 0 ? (sessions / maxSessions) * 150 : 0.0;
      
      bars.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (sessions > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    sessions.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: _getBarColor(sessions, maxSessions),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatHour(hour),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }
    
    return bars;
  }

  Widget _buildTimeLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimeLabel('Early Morning', '6-9 AM', Icons.wb_sunny),
        _buildTimeLabel('Morning', '9-12 PM', Icons.brightness_high),
        _buildTimeLabel('Afternoon', '12-6 PM', Icons.wb_sunny_outlined),
        _buildTimeLabel('Evening', '6-9 PM', Icons.brightness_2),
      ],
    );
  }

  Widget _buildTimeLabel(String title, String time, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getBarColor(int sessions, int maxSessions) {
    if (maxSessions == 0) return Colors.grey.shade300;
    
    final intensity = sessions / maxSessions;
    if (intensity >= 0.8) return Colors.green.shade600;
    if (intensity >= 0.6) return Colors.green.shade400;
    if (intensity >= 0.4) return Colors.orange.shade400;
    if (intensity >= 0.2) return Colors.orange.shade300;
    return Colors.grey.shade300;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12A';
    if (hour < 12) return '${hour}A';
    if (hour == 12) return '12P';
    return '${hour - 12}P';
  }
}