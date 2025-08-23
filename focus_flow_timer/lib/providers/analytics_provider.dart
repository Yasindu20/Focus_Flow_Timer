import 'package:flutter/material.dart';
import '../models/daily_stats.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  DailyStats? _todayStats;
  List<DailyStats> _weeklyStats = [];
  Map<String, int> _weeklySummary = {};

  DailyStats? get todayStats => _todayStats;
  List<DailyStats> get weeklyStats => _weeklyStats;
  Map<String, int> get weeklySummary => _weeklySummary;

  AnalyticsProvider() {
    refreshStats();
  }

  void refreshStats() {
    _todayStats = AnalyticsService.getTodayStats();
    _weeklyStats = AnalyticsService.getWeeklyStats();
    _weeklySummary = AnalyticsService.getWeeklySummary();
    notifyListeners();
  }

  double get todayFocusScore => _todayStats?.focusScore ?? 0.0;
  int get todaySessions => _todayStats?.completedSessions ?? 0;
  int get todayMinutes => _todayStats?.totalMinutes ?? 0;
  int get todayTasks => _todayStats?.tasksCompleted ?? 0;

  String get focusScoreText {
    final score = todayFocusScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Needs Improvement';
    return 'Getting Started';
  }

  Color get focusScoreColor {
    final score = todayFocusScore;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.red;
    return Colors.grey;
  }
}
