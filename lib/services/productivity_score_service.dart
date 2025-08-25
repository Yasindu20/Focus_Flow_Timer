import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/productivity_score.dart';
import '../models/pomodoro_session.dart';
import '../models/task.dart';
import 'optimized_storage_service.dart';

class ProductivityScoreService extends ChangeNotifier {
  static final ProductivityScoreService _instance = ProductivityScoreService._internal();
  factory ProductivityScoreService() => _instance;
  ProductivityScoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OptimizedStorageService _storage = OptimizedStorageService();

  ProductivityScore? _currentScore;
  List<ProductivityScore> _weeklyScores = [];
  List<ProductivityScore> _monthlyScores = [];
  bool _isInitialized = false;

  ProductivityScore? get currentScore => _currentScore;
  List<ProductivityScore> get weeklyScores => _weeklyScores;
  List<ProductivityScore> get monthlyScores => _monthlyScores;

  // Get trend data for charts
  List<double> get weeklyTrend => _weeklyScores.map((s) => s.dailyScore).toList();
  List<double> get monthlyTrend => _monthlyScores.map((s) => s.dailyScore).toList();

  double get averageWeeklyScore =>
      _weeklyScores.isEmpty ? 0 : _weeklyScores.map((s) => s.dailyScore).reduce((a, b) => a + b) / _weeklyScores.length;

  double get averageMonthlyScore =>
      _monthlyScores.isEmpty ? 0 : _monthlyScores.map((s) => s.dailyScore).reduce((a, b) => a + b) / _monthlyScores.length;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadScoreHistory();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Productivity score service initialization error: $e');
    }
  }

  Future<void> _loadScoreHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _loadFromLocal();
        return;
      }

      try {
        // Load current score
        final currentDoc = await _firestore
            .collection('user_productivity_scores')
            .doc(user.uid)
            .collection('scores')
            .doc('current')
            .get();

        if (currentDoc.exists) {
          _currentScore = ProductivityScore.fromJson(currentDoc.data()!);
        }

        // Load weekly history
        final weeklyQuery = await _firestore
            .collection('user_productivity_scores')
            .doc(user.uid)
            .collection('scores')
            .where('date', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
            .orderBy('date', descending: true)
            .limit(7)
            .get();

        _weeklyScores = weeklyQuery.docs
            .map((doc) => ProductivityScore.fromJson(doc.data()))
            .toList();

        // Load monthly history
        final monthlyQuery = await _firestore
            .collection('user_productivity_scores')
            .doc(user.uid)
            .collection('scores')
            .where('date', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
            .orderBy('date', descending: true)
            .limit(30)
            .get();

        _monthlyScores = monthlyQuery.docs
            .map((doc) => ProductivityScore.fromJson(doc.data()))
            .toList();

      } catch (e) {
        debugPrint('Firestore load error, falling back to local: $e');
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint('Error loading productivity scores: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final currentScoreData = await _storage.getCurrentProductivityScore();
      if (currentScoreData != null) {
        _currentScore = ProductivityScore.fromJson(currentScoreData);
      }

      final weeklyData = await _storage.getWeeklyProductivityScores();
      _weeklyScores = weeklyData.map((json) => ProductivityScore.fromJson(json)).toList();

      final monthlyData = await _storage.getMonthlyProductivityScores();
      _monthlyScores = monthlyData.map((json) => ProductivityScore.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Local productivity score load error: $e');
    }
  }

  Future<void> calculateAndUpdateScore({
    required List<PomodoroSession> todaySessions,
    required List<Task> completedTasks,
    required int streakDays,
    required Map<String, List<PomodoroSession>> categorizedSessions,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final today = DateTime.now();

      // Calculate metrics
      final metrics = _calculateMetrics(
        sessions: todaySessions,
        completedTasks: completedTasks,
        streakDays: streakDays,
      );

      // Calculate category scores
      final categoryScores = _calculateCategoryScores(categorizedSessions);

      // Generate productivity score
      final newScore = ProductivityCalculator.calculateScore(
        userId: userId,
        date: today,
        metrics: metrics,
        categoryScores: categoryScores,
      );

      // Update current score
      _currentScore = newScore;

      // Add to history
      _addToHistory(newScore);

      // Save to storage
      await _saveScores();

      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating productivity score: $e');
    }
  }

  ProductivityMetrics _calculateMetrics({
    required List<PomodoroSession> sessions,
    required List<Task> completedTasks,
    required int streakDays,
  }) {
    int totalSessions = sessions.length;
    int completedSessions = sessions.where((s) => s.completed).length;
    int totalFocusMinutes = sessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + (s.duration ~/ 60000));
    
    int perfectSessions = sessions
        .where((s) => s.completed && s.interruptions == 0)
        .length;

    double averageSessionLength = completedSessions > 0
        ? sessions.where((s) => s.completed)
              .map((s) => s.duration / 60000.0)
              .reduce((a, b) => a + b) / completedSessions
        : 0.0;

    int interruptionCount = sessions.fold(0, (sum, s) => sum + s.interruptions);

    // Calculate consistency score (based on regular usage patterns)
    double consistencyScore = _calculateConsistencyScore(sessions);

    // Calculate efficiency score (based on completion rate and interruptions)
    double efficiencyScore = _calculateEfficiencyScore(sessions);

    return ProductivityMetrics(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      totalFocusMinutes: totalFocusMinutes,
      tasksCompleted: completedTasks.length,
      perfectSessions: perfectSessions,
      averageSessionLength: averageSessionLength,
      consistencyScore: consistencyScore,
      efficiencyScore: efficiencyScore,
      streakDays: streakDays,
      interruptionCount: interruptionCount,
    );
  }

  double _calculateConsistencyScore(List<PomodoroSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    // Group sessions by hour of day
    Map<int, int> hourlyDistribution = {};
    for (final session in sessions) {
      int hour = session.startTime.hour;
      hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
    }

    // Calculate consistency based on distribution spread
    if (hourlyDistribution.length <= 2) return 1.0; // Very consistent
    if (hourlyDistribution.length <= 4) return 0.8; // Good consistency
    if (hourlyDistribution.length <= 6) return 0.6; // Moderate consistency
    return 0.4; // Low consistency
  }

  double _calculateEfficiencyScore(List<PomodoroSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    int totalSessions = sessions.length;
    int completedSessions = sessions.where((s) => s.completed).length;
    int totalInterruptions = sessions.fold(0, (sum, s) => sum + s.interruptions);

    double completionRate = completedSessions / totalSessions;
    double interruptionRate = totalInterruptions / totalSessions;

    // Efficiency = completion rate - interruption penalty
    return (completionRate - (interruptionRate * 0.3)).clamp(0.0, 1.0);
  }

  Map<String, double> _calculateCategoryScores(
    Map<String, List<PomodoroSession>> categorizedSessions) {
    
    Map<String, double> categoryScores = {};
    
    categorizedSessions.forEach((category, sessions) {
      if (sessions.isEmpty) {
        categoryScores[category] = 0.0;
        return;
      }

      int completedSessions = sessions.where((s) => s.completed).length;
      double completionRate = completedSessions / sessions.length;
      
      // Category score based on completion rate and total time
      int totalMinutes = sessions
          .where((s) => s.completed)
          .fold(0, (sum, s) => sum + (s.duration ~/ 60000));
      
      double timeScore = (totalMinutes / 120.0).clamp(0.0, 1.0); // Max 2 hours per category
      double finalScore = (completionRate * 0.7 + timeScore * 0.3) * 100;
      
      categoryScores[category] = finalScore;
    });
    
    return categoryScores;
  }

  void _addToHistory(ProductivityScore score) {
    // Add to weekly history
    _weeklyScores.insert(0, score);
    if (_weeklyScores.length > 7) {
      _weeklyScores = _weeklyScores.take(7).toList();
    }

    // Add to monthly history
    _monthlyScores.insert(0, score);
    if (_monthlyScores.length > 30) {
      _monthlyScores = _monthlyScores.take(30).toList();
    }
  }

  Future<void> _saveScores() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Save to local storage
      if (_currentScore != null) {
        await _storage.setCurrentProductivityScore(_currentScore!.toJson());
      }
      await _storage.setWeeklyProductivityScores(
        _weeklyScores.map((s) => s.toJson()).toList(),
      );
      await _storage.setMonthlyProductivityScores(
        _monthlyScores.map((s) => s.toJson()).toList(),
      );

      // Save to Firestore if user is logged in
      if (user != null && _currentScore != null) {
        try {
          final batch = _firestore.batch();

          // Save current score
          final currentRef = _firestore
              .collection('user_productivity_scores')
              .doc(user.uid)
              .collection('scores')
              .doc('current');
          batch.set(currentRef, _currentScore!.toJson());

          // Save daily score with date as document ID
          final dateKey = DateTime.now().toIso8601String().split('T')[0];
          final dailyRef = _firestore
              .collection('user_productivity_scores')
              .doc(user.uid)
              .collection('scores')
              .doc(dateKey);
          batch.set(dailyRef, _currentScore!.toJson());

          await batch.commit();
        } catch (e) {
          debugPrint('Firestore save error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error saving productivity scores: $e');
    }
  }

  // Get productivity insights
  Map<String, dynamic> getProductivityInsights() {
    if (_currentScore == null || _weeklyScores.isEmpty) {
      return {
        'message': 'Complete more sessions to get insights',
        'suggestions': ['Start with a 25-minute focus session', 'Set daily goals']
      };
    }

    List<String> insights = [];
    List<String> suggestions = [];

    // Score-based insights
    if (_currentScore!.dailyScore >= 80) {
      insights.add('You\'re having an excellent productivity day! 🎉');
    } else if (_currentScore!.dailyScore >= 60) {
      insights.add('Good progress today! Keep up the momentum! 👍');
    } else {
      insights.add('There\'s room for improvement today. Small steps count! 💪');
      suggestions.add('Try completing 2-3 more focus sessions');
    }

    // Trend analysis
    if (_weeklyScores.length >= 3) {
      List<double> recentScores = _weeklyScores.take(3).map((s) => s.dailyScore).toList();
      bool improving = recentScores[0] > recentScores[1] && recentScores[1] > recentScores[2];
      bool declining = recentScores[0] < recentScores[1] && recentScores[1] < recentScores[2];

      if (improving) {
        insights.add('Your productivity is trending upward! 📈');
      } else if (declining) {
        insights.add('Your productivity has been declining. Let\'s turn it around! 🔄');
        suggestions.add('Review your daily routine and identify distractions');
      }
    }

    // Streak insights
    if (_currentScore!.metrics.streakDays >= 7) {
      insights.add('Amazing ${_currentScore!.metrics.streakDays}-day streak! 🔥');
    } else if (_currentScore!.metrics.streakDays >= 3) {
      insights.add('Good ${_currentScore!.metrics.streakDays}-day streak building up! 📅');
    } else {
      suggestions.add('Focus on building a daily habit streak');
    }

    // Perfect session insights
    double perfectRate = _currentScore!.metrics.perfectSessionRate;
    if (perfectRate >= 70) {
      insights.add('Excellent focus discipline with ${perfectRate.toInt()}% perfect sessions! 💎');
    } else if (perfectRate < 30) {
      suggestions.add('Try to minimize interruptions during sessions');
    }

    return {
      'insights': insights,
      'suggestions': suggestions,
      'score': _currentScore!.dailyScore,
      'grade': _currentScore!.scoreGrade,
      'trend': _currentScore!.trend.toString().split('.').last,
    };
  }

  // Get detailed score breakdown for analytics
  Map<String, dynamic> getScoreBreakdown() {
    if (_currentScore == null) return {};

    return {
      'total_score': _currentScore!.dailyScore,
      'grade': _currentScore!.scoreGrade,
      'components': _currentScore!.details.components.map((c) => {
        'name': c.name,
        'value': c.value,
        'description': c.description,
        'type': c.type.toString().split('.').last,
      }).toList(),
      'metrics': {
        'total_sessions': _currentScore!.metrics.totalSessions,
        'completed_sessions': _currentScore!.metrics.completedSessions,
        'completion_rate': _currentScore!.metrics.completionRate,
        'perfect_sessions': _currentScore!.metrics.perfectSessions,
        'perfect_rate': _currentScore!.metrics.perfectSessionRate,
        'focus_minutes': _currentScore!.metrics.totalFocusMinutes,
        'streak_days': _currentScore!.metrics.streakDays,
        'tasks_completed': _currentScore!.metrics.tasksCompleted,
      },
      'category_scores': _currentScore!.categoryScores,
    };
  }

  Future<void> resetScores() async {
    _currentScore = null;
    _weeklyScores.clear();
    _monthlyScores.clear();
    
    await _storage.clearProductivityScores();
    notifyListeners();
  }
}