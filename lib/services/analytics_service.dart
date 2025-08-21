import '../models/daily_stats.dart';
import '../models/pomodoro_session.dart';
import 'storage_service.dart';

class AnalyticsService {
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
}
