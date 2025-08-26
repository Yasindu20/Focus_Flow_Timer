import 'session_analytics.dart';
import 'user_goals.dart';

class DashboardData {
  final List<SessionAnalytics> dailySessions;
  final List<SessionAnalytics> weeklySessions;
  final List<SessionAnalytics> monthlySessions;
  final UserGoals? goals;
  final double efficiency;
  final Map<int, int> focusPatterns;
  final int streak;

  DashboardData({
    required this.dailySessions,
    required this.weeklySessions,
    required this.monthlySessions,
    this.goals,
    required this.efficiency,
    required this.focusPatterns,
    required this.streak,
  });

  // Daily Progress
  double get dailyProgress {
    if (goals == null) return 0.0;
    final completedToday = dailySessions.where((s) => s.isCompleted).length;
    return (completedToday / goals!.dailySessions).clamp(0.0, 1.0);
  }

  // Weekly Progress
  double get weeklyProgress {
    if (goals == null) return 0.0;
    final weeklyMinutes = weeklySessions
        .where((s) => s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final weeklyHours = weeklyMinutes / 60;
    return (weeklyHours / goals!.weeklyHours).clamp(0.0, 1.0);
  }

  // Peak Focus Hour
  int get peakFocusHour {
    if (focusPatterns.isEmpty) return 9; // Default to 9 AM
    return focusPatterns.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Today's Focus Time
  int get todayFocusMinutes {
    return dailySessions
        .where((s) => s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // This Week's Focus Time
  int get weeklyFocusMinutes {
    return weeklySessions
        .where((s) => s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // This Month's Focus Time
  int get monthlyFocusMinutes {
    return monthlySessions
        .where((s) => s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }
}

class ExportData {
  final List<SessionAnalytics> sessions;
  final UserGoals? goals;
  final double efficiency;
  final int streak;
  final Map<int, int> focusPatterns;

  ExportData({
    required this.sessions,
    this.goals,
    required this.efficiency,
    required this.streak,
    required this.focusPatterns,
  });
}