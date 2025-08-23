import 'package:flutter/foundation.dart';
import '../models/daily_stats.dart';
import '../models/enhanced_task.dart';
import '../models/pomodoro_session.dart';
import 'storage_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  
  /// Track task creation event
  Future<void> trackTaskCreated(EnhancedTask task) async {
    debugPrint('Task created: ${task.title}');
    // TODO: Implement analytics tracking
  }
  
  /// Track task update event
  Future<void> trackTaskUpdated(EnhancedTask task) async {
    debugPrint('Task updated: ${task.title}');
    // TODO: Implement analytics tracking
  }
  
  /// Track task completion event
  Future<void> trackTaskCompleted(EnhancedTask task) async {
    debugPrint('Task completed: ${task.title}');
    // TODO: Implement analytics tracking
  }
  
  /// Track task deletion event
  Future<void> trackTaskDeleted(EnhancedTask task) async {
    debugPrint('Task deleted: ${task.title}');
    // TODO: Implement analytics tracking
  }

  static DailyStats getTodayStats() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    var stats = StorageService.getStatsForDate(todayKey);
    if (stats == null) {
      stats = DailyStats(date: todayKey);
      StorageService.updateDailyStats(stats);
    }

    return stats;
  }

  static Future<void> recordSession(PomodoroSession session) async {
    // Save the session
    await StorageService.addSession(session);

    // Update daily stats
    final stats = getTodayStats();

    if (session.completed && session.type == SessionType.work) {
      stats.completedSessions++;
      stats.totalMinutes += session.duration;

      // Calculate focus score (simple algorithm)
      stats.focusScore = _calculateFocusScore(stats);
    }

    await StorageService.updateDailyStats(stats);
  }

  static Future<void> recordTaskCompletion() async {
    final stats = getTodayStats();
    stats.tasksCompleted++;
    await StorageService.updateDailyStats(stats);
  }

  static double _calculateFocusScore(DailyStats stats) {
    // Simple focus score calculation
    // Base score on completed sessions and consistency
    final baseScore = (stats.completedSessions * 10).toDouble();
    final consistencyBonus = stats.completedSessions >= 4 ? 20.0 : 0.0;
    return (baseScore + consistencyBonus).clamp(0.0, 100.0);
  }

  static List<DailyStats> getWeeklyStats() {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return StorageService.getStatsForRange(weekStart, weekEnd);
  }

  static Map<String, int> getWeeklySummary() {
    final weeklyStats = getWeeklyStats();

    int totalSessions = 0;
    int totalMinutes = 0;
    int totalTasks = 0;

    for (final stat in weeklyStats) {
      totalSessions += stat.completedSessions;
      totalMinutes += stat.totalMinutes;
      totalTasks += stat.tasksCompleted;
    }

    return {
      'sessions': totalSessions,
      'minutes': totalMinutes,
      'tasks': totalTasks,
      'avgScore': weeklyStats.isNotEmpty
          ? (weeklyStats.map((s) => s.focusScore).reduce((a, b) => a + b) /
                    weeklyStats.length)
                .round()
          : 0,
    };
  }

  /// Generate productivity report for task provider
  Future<Map<String, dynamic>> generateProductivityReport({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    try {
      final stats = StorageService.getStatsForRange(startDate, endDate);
      
      return {
        'total_sessions': stats.fold(0, (sum, stat) => sum + stat.completedSessions),
        'total_minutes': stats.fold(0, (sum, stat) => sum + stat.totalMinutes),
        'total_tasks': stats.fold(0, (sum, stat) => sum + stat.tasksCompleted),
        'average_focus_score': stats.isNotEmpty 
            ? stats.fold(0.0, (sum, stat) => sum + stat.focusScore) / stats.length
            : 0.0,
        'productivity_trend': 'stable',
        'recommendations': ['Keep up the good work!'],
      };
    } catch (e) {
      debugPrint('Error generating productivity report: $e');
      return {
        'total_sessions': 0,
        'total_minutes': 0,
        'total_tasks': 0,
        'average_focus_score': 0.0,
        'productivity_trend': 'stable',
        'recommendations': ['Start tracking your productivity!'],
      };
    }
  }
}
