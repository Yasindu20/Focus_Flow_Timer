import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/session_analytics.dart';

class DailySessionsChart extends StatelessWidget {
  final List<SessionAnalytics> sessions;

  const DailySessionsChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final dailyData = _groupSessionsByDay();
    
    return Container(
      height: 300,
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: dailyData.values.isNotEmpty ? 
              dailyData.values.reduce((a, b) => a > b ? a : b).toDouble() + 2 : 10,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueAccent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = dailyData.keys.elementAt(group.x.toInt());
                final count = rod.toY.round();
                return BarTooltipItem(
                  '${DateFormat('MMM dd').format(date)}\n$count sessions',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = dailyData.keys.elementAt(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM\ndd').format(date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyData.entries.map((entry) {
            final index = dailyData.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Theme.of(context).primaryColor,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<DateTime, int> _groupSessionsByDay() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final dailyData = <DateTime, int>{};

    // Initialize last 7 days
    for (int i = 0; i < 7; i++) {
      final date = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day + i);
      dailyData[date] = 0;
    }

    // Count completed sessions by day
    for (final session in sessions) {
      if (session.isCompleted) {
        final date = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
        if (dailyData.containsKey(date)) {
          dailyData[date] = (dailyData[date] ?? 0) + 1;
        }
      }
    }

    return dailyData;
  }
}

class WeeklyProgressChart extends StatelessWidget {
  final List<SessionAnalytics> sessions;

  const WeeklyProgressChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final weeklyData = _groupSessionsByWeek();
    
    return Container(
      height: 300,
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final weeks = weeklyData.keys.toList();
                  if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                    return Text('Week ${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
                },
                reservedSize: 35,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
          ),
          minX: 0,
          maxX: (weeklyData.length - 1).toDouble(),
          minY: 0,
          maxY: weeklyData.values.isNotEmpty ? 
              weeklyData.values.reduce((a, b) => a > b ? a : b) + 2 : 10,
          lineBarsData: [
            LineChartBarData(
              spots: weeklyData.entries.map((entry) {
                final index = weeklyData.keys.toList().indexOf(entry.key);
                return FlSpot(index.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, double> _groupSessionsByWeek() {
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final weeklyData = <DateTime, double>{};

    // Initialize last 4 weeks
    for (int i = 0; i < 4; i++) {
      final weekStart = fourWeeksAgo.add(Duration(days: i * 7));
      final week = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weeklyData[week] = 0.0;
    }

    // Group sessions by week and calculate hours
    for (final session in sessions) {
      if (session.isCompleted) {
        final sessionDate = session.startTime;
        final weekStart = sessionDate.subtract(Duration(days: sessionDate.weekday - 1));
        final sessionWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
        
        for (final weekEntry in weeklyData.entries) {
          final weekKey = weekEntry.key;
          if (sessionWeek.isAtSameMomentAs(weekKey) || 
              (sessionWeek.isAfter(weekKey) && sessionWeek.isBefore(weekKey.add(const Duration(days: 7))))) {
            weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + (session.durationMinutes / 60);
          }
        }
      }
    }

    return weeklyData;
  }
}

class MonthlyOverviewChart extends StatelessWidget {
  final List<SessionAnalytics> sessions;

  const MonthlyOverviewChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final completedSessions = sessions.where((s) => s.isCompleted).length;
    final interruptedSessions = sessions.where((s) => s.isInterrupted).length;
    final totalSessions = completedSessions + interruptedSessions;

    if (totalSessions == 0) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No sessions this month'),
        ),
      );
    }

    return Container(
      height: 300,
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  enabled: true,
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: completedSessions.toDouble(),
                    title: '${((completedSessions / totalSessions) * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: interruptedSessions.toDouble(),
                    title: '${((interruptedSessions / totalSessions) * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  color: Colors.green,
                  label: 'Completed',
                  value: completedSessions,
                ),
                const SizedBox(height: 8),
                _buildLegendItem(
                  color: Colors.red,
                  label: 'Interrupted',
                  value: interruptedSessions,
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: $totalSessions sessions',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}