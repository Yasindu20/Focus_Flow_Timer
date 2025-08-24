import 'package:flutter/material.dart';
import '../services/optimized_storage_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final OptimizedStorageService _storage = OptimizedStorageService();
  
  int _completedSessions = 0;
  int _totalMinutes = 0;
  int _tasksCompleted = 0;
  double _focusScore = 0.0;
  Map<String, int> _weeklySummary = {};

  int get completedSessions => _completedSessions;
  int get totalMinutes => _totalMinutes;
  int get tasksCompleted => _tasksCompleted;
  double get focusScore => _focusScore;
  Map<String, int> get weeklySummary => _weeklySummary;

  AnalyticsProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _storage.initialize();
    await refreshStats();
  }

  Future<void> refreshStats() async {
    try {
      final sessions = await _storage.getTimerSessions();
      final tasks = await _storage.getTasks();
      final today = DateTime.now();
      
      // Calculate today's stats
      final todaySessions = sessions.where((session) {
        final sessionDate = DateTime.parse(session['completedAt'] ?? '');
        return sessionDate.day == today.day &&
               sessionDate.month == today.month &&
               sessionDate.year == today.year;
      }).toList();
      
      _completedSessions = todaySessions.length;
      _totalMinutes = todaySessions.fold(0, (sum, session) => sum + (session['duration'] as int? ?? 0));
      
      final todayTasks = tasks.where((task) {
        final taskDate = DateTime.parse(task['completedAt'] ?? task['createdAt'] ?? '');
        return task['isCompleted'] == true &&
               taskDate.day == today.day &&
               taskDate.month == today.month &&
               taskDate.year == today.year;
      }).toList();
      
      _tasksCompleted = todayTasks.length;
      _focusScore = _calculateFocusScore();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing stats: $e');
    }
  }
  
  double _calculateFocusScore() {
    double score = 0.0;
    
    // Sessions contribute 40%
    if (_completedSessions > 0) {
      score += (_completedSessions * 10).clamp(0, 40);
    }
    
    // Minutes contribute 30%
    if (_totalMinutes > 0) {
      score += (_totalMinutes / 5).clamp(0, 30);
    }
    
    // Tasks contribute 30%
    if (_tasksCompleted > 0) {
      score += (_tasksCompleted * 15).clamp(0, 30);
    }
    
    return score.clamp(0, 100);
  }

  double get todayFocusScore => _focusScore;
  int get todaySessions => _completedSessions;
  int get todayMinutes => _totalMinutes;
  int get todayTasks => _tasksCompleted;

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
