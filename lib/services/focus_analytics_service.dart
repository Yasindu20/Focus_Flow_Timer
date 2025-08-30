import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus_mode_manager.dart';

/// Comprehensive Focus Analytics Service
/// Tracks focus patterns, provides insights, and helps optimize focus sessions
class FocusAnalyticsService {
  static final FocusAnalyticsService _instance = FocusAnalyticsService._internal();
  factory FocusAnalyticsService() => _instance;
  FocusAnalyticsService._internal();

  static const String _sessionsKey = 'focus_sessions';
  static const String _distractionsKey = 'focus_distractions';
  static const String _streaksKey = 'focus_streaks';
  static const String _goalsKey = 'focus_goals';

  // Current session tracking
  FocusSession? _currentSession;
  final List<FocusDistraction> _currentDistractions = [];
  Timer? _sessionTimer;
  
  // Historical data
  List<FocusSession> _focusSessions = [];
  List<FocusDistraction> _allDistractions = [];
  FocusStreak _currentStreak = FocusStreak.empty();
  FocusGoals _userGoals = FocusGoals.defaultGoals();
  
  // Analytics state
  final StreamController<FocusInsights> _insightsController = 
      StreamController<FocusInsights>.broadcast();
  final StreamController<FocusAchievement> _achievementController = 
      StreamController<FocusAchievement>.broadcast();

  // Getters
  FocusSession? get currentSession => _currentSession;
  List<FocusSession> get focusSessions => List.unmodifiable(_focusSessions);
  FocusStreak get currentStreak => _currentStreak;
  FocusGoals get userGoals => _userGoals;
  
  Stream<FocusInsights> get insightsStream => _insightsController.stream;
  Stream<FocusAchievement> get achievementStream => _achievementController.stream;

  /// Initialize the analytics service
  Future<void> initialize() async {
    await _loadData();
    await _calculateStreak();
    await _generateInsights();
    
    if (kDebugMode) {
      print('📊 Focus Analytics Service initialized');
      print('   Total sessions: ${_focusSessions.length}');
      print('   Current streak: ${_currentStreak.days} days');
      print('   Average session: ${_getAverageSessionDuration().inMinutes} minutes');
    }
  }

  /// Start tracking a new focus session
  Future<void> startSession({
    required Duration plannedDuration,
    String? sessionType,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentSession != null) {
      await endSession(); // End previous session
    }

    _currentSession = FocusSession(
      id: _generateSessionId(),
      startTime: DateTime.now(),
      plannedDuration: plannedDuration,
      sessionType: sessionType ?? 'pomodoro',
      metadata: metadata ?? {},
    );

    _currentDistractions.clear();
    
    // Start session monitoring
    _startSessionMonitoring();
    
    if (kDebugMode) print('📊 Focus session started: ${_currentSession!.id}');
  }

  /// End the current focus session
  Future<void> endSession({bool wasCompleted = true}) async {
    if (_currentSession == null) return;

    final endTime = DateTime.now();
    final actualDuration = endTime.difference(_currentSession!.startTime);
    
    _currentSession = _currentSession!.copyWith(
      endTime: endTime,
      actualDuration: actualDuration,
      wasCompleted: wasCompleted,
      distractions: List.from(_currentDistractions),
      focusScore: _calculateFocusScore(),
      productivityScore: _calculateProductivityScore(),
    );

    // Add to historical data
    _focusSessions.add(_currentSession!);
    _allDistractions.addAll(_currentDistractions);

    // Save to storage
    await _saveData();

    // Update streak
    await _updateStreak(wasCompleted);
    
    // Check for achievements
    await _checkAchievements();

    // Generate new insights
    await _generateInsights();

    _sessionTimer?.cancel();
    
    if (kDebugMode) {
      print('📊 Focus session ended: ${_currentSession!.id}');
      print('   Duration: ${actualDuration.inMinutes} minutes');
      print('   Focus Score: ${_currentSession!.focusScore?.toStringAsFixed(1)}');
      print('   Distractions: ${_currentDistractions.length}');
    }

    _currentSession = null;
    _currentDistractions.clear();
  }

  /// Record a distraction during the current session
  void recordDistraction(FocusDistraction distraction) {
    if (_currentSession != null) {
      _currentDistractions.add(distraction);
      
      if (kDebugMode) {
        print('📊 Distraction recorded: ${distraction.type} (${distraction.severity})');
      }
    }
  }

  /// Get focus insights for different time periods
  Future<FocusInsights> getInsights({Duration? period}) async {
    final now = DateTime.now();
    final cutoff = period != null ? now.subtract(period) : 
                   now.subtract(const Duration(days: 30));

    final relevantSessions = _focusSessions
        .where((s) => s.startTime.isAfter(cutoff))
        .toList();

    final insights = _calculateInsights(relevantSessions);
    return insights;
  }

  /// Get focus trends over time
  List<FocusTrend> getFocusTrends({int days = 7}) {
    final trends = <FocusTrend>[];
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(const Duration(days: 1));
      
      final daySessions = _focusSessions
          .where((s) => s.startTime.isAfter(date) && s.startTime.isBefore(nextDate))
          .toList();

      final totalDuration = daySessions.fold<Duration>(
        Duration.zero,
        (total, session) => total + (session.actualDuration ?? Duration.zero),
      );

      final averageFocusScore = daySessions.isEmpty ? 0.0 :
          daySessions.map((s) => s.focusScore ?? 0.0).reduce((a, b) => a + b) / daySessions.length;

      trends.add(FocusTrend(
        date: date,
        totalFocusTime: totalDuration,
        sessionCount: daySessions.length,
        averageFocusScore: averageFocusScore,
        distractionCount: daySessions.fold(0, (total, session) => total + session.distractions.length),
      ));
    }
    
    return trends;
  }

  /// Get personalized focus recommendations
  List<FocusRecommendation> getRecommendations() {
    final recommendations = <FocusRecommendation>[];
    
    if (_focusSessions.length < 5) {
      recommendations.add(FocusRecommendation(
        type: RecommendationType.habit,
        title: 'Build Your Focus Habit',
        description: 'Complete 5 more focus sessions to unlock detailed analytics',
        priority: 1.0,
        actionable: true,
      ));
      return recommendations;
    }

    final recentSessions = _focusSessions.length <= 10 
        ? _focusSessions 
        : _focusSessions.sublist(_focusSessions.length - 10);
    final avgFocusScore = recentSessions.map((s) => s.focusScore ?? 0.0).reduce((a, b) => a + b) / recentSessions.length;
    final avgDistractions = recentSessions.map((s) => s.distractions.length).reduce((a, b) => a + b) / recentSessions.length;

    // Score-based recommendations
    if (avgFocusScore < 0.6) {
      recommendations.add(FocusRecommendation(
        type: RecommendationType.technique,
        title: 'Try Shorter Sessions',
        description: 'Your focus score is ${(avgFocusScore * 100).round()}%. Try 15-20 minute sessions to build focus stamina.',
        priority: 0.9,
        actionable: true,
      ));
    }

    // Distraction-based recommendations
    if (avgDistractions > 3) {
      recommendations.add(FocusRecommendation(
        type: RecommendationType.environment,
        title: 'Reduce Distractions',
        description: 'You average ${avgDistractions.round()} distractions per session. Try using stricter app blocking.',
        priority: 0.8,
        actionable: true,
      ));
    }

    // Time-based recommendations
    final bestTimeOfDay = _getBestFocusTime();
    if (bestTimeOfDay != null) {
      recommendations.add(FocusRecommendation(
        type: RecommendationType.timing,
        title: 'Optimal Focus Time',
        description: 'Your best focus hours are around $bestTimeOfDay. Schedule important work then.',
        priority: 0.7,
        actionable: false,
      ));
    }

    // Streak recommendations
    if (_currentStreak.days > 7) {
      recommendations.add(FocusRecommendation(
        type: RecommendationType.habit,
        title: 'Amazing Streak!',
        description: 'You\'re on a ${_currentStreak.days}-day streak! Keep it up to unlock new features.',
        priority: 0.6,
        actionable: false,
      ));
    }

    return recommendations..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Set user focus goals
  Future<void> setGoals(FocusGoals goals) async {
    _userGoals = goals;
    await _saveData();
    await _generateInsights();
  }

  /// Export focus data for external analysis
  Map<String, dynamic> exportData({Duration? period}) {
    final now = DateTime.now();
    final cutoff = period != null ? now.subtract(period) : DateTime(2020);

    final relevantSessions = _focusSessions
        .where((s) => s.startTime.isAfter(cutoff))
        .toList();

    return {
      'export_date': now.toIso8601String(),
      'period_days': period?.inDays ?? 'all_time',
      'total_sessions': relevantSessions.length,
      'total_focus_time_minutes': relevantSessions.fold(0, (total, session) => 
          total + (session.actualDuration?.inMinutes ?? 0)),
      'sessions': relevantSessions.map((s) => s.toMap()).toList(),
      'streak': _currentStreak.toMap(),
      'goals': _userGoals.toMap(),
    };
  }

  // Private methods

  void _startSessionMonitoring() {
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_currentSession == null) {
        timer.cancel();
        return;
      }
      
      // Update session progress
      final elapsed = DateTime.now().difference(_currentSession!.startTime);
      // Update session progress
      // final progress = elapsed.inMilliseconds / _currentSession!.plannedDuration.inMilliseconds;
      
      // Check for natural break points (every 25 minutes for Pomodoro)
      if (elapsed.inMinutes % 25 == 0 && elapsed.inMinutes > 0) {
        _suggestBreak();
      }
    });
  }

  void _suggestBreak() {
    // This would trigger a gentle break suggestion
    if (kDebugMode) print('☕ Break suggestion triggered');
  }

  double _calculateFocusScore() {
    if (_currentSession == null) return 0.0;
    
    final plannedMinutes = _currentSession!.plannedDuration.inMinutes;
    final actualMinutes = _currentSession!.actualDuration?.inMinutes ?? 0;
    final distractionCount = _currentDistractions.length;
    
    // Base score from completion ratio
    double score = min(actualMinutes / plannedMinutes, 1.0);
    
    // Penalty for distractions
    final distractionPenalty = min(distractionCount * 0.1, 0.5);
    score -= distractionPenalty;
    
    // Bonus for completing planned duration
    if (actualMinutes >= plannedMinutes) {
      score += 0.1;
    }
    
    return max(score, 0.0);
  }

  double _calculateProductivityScore() {
    if (_currentSession == null) return 0.0;
    
    final sessionDuration = _currentSession!.actualDuration?.inMinutes ?? 0;
    final highSeverityDistractions = _currentDistractions
        .where((d) => d.severity > 0.7)
        .length;
    
    // Base productivity score
    double score = min(sessionDuration / 60.0, 1.0); // Normalize to 1 hour
    
    // Severe penalty for high-severity distractions
    score -= highSeverityDistractions * 0.2;
    
    return max(score, 0.0);
  }

  FocusInsights _calculateInsights(List<FocusSession> sessions) {
    if (sessions.isEmpty) {
      return FocusInsights.empty();
    }

    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + (session.actualDuration ?? Duration.zero),
    );

    final averageDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ sessions.length,
    );

    final completedSessions = sessions.where((s) => s.wasCompleted).length;
    final completionRate = completedSessions / sessions.length;

    final avgFocusScore = sessions.map((s) => s.focusScore ?? 0.0).reduce((a, b) => a + b) / sessions.length;
    final totalDistractions = sessions.fold(0, (total, session) => total + session.distractions.length);

    // Productivity insights
    final bestDay = _findBestProductivityDay(sessions);
    final bestTimeOfDay = _getBestFocusTime();
    final commonDistractions = _analyzeCommonDistractions(sessions);

    return FocusInsights(
      totalSessions: sessions.length,
      totalFocusTime: totalDuration,
      averageSessionDuration: averageDuration,
      completionRate: completionRate,
      averageFocusScore: avgFocusScore,
      totalDistractions: totalDistractions,
      bestProductivityDay: bestDay,
      bestFocusTime: bestTimeOfDay,
      commonDistractions: commonDistractions,
      weeklyProgress: _calculateWeeklyProgress(),
      monthlyGoalProgress: _calculateGoalProgress(),
      focusTrends: getFocusTrends(),
      personalizedTips: _generatePersonalizedTips(sessions),
    );
  }

  String _findBestProductivityDay(List<FocusSession> sessions) {
    final dayScores = <int, List<double>>{};
    
    for (final session in sessions) {
      final day = session.startTime.weekday;
      dayScores.putIfAbsent(day, () => []);
      dayScores[day]!.add(session.focusScore ?? 0.0);
    }

    String bestDay = 'Monday';
    double bestScore = 0.0;
    
    dayScores.forEach((day, scores) {
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      if (avgScore > bestScore) {
        bestScore = avgScore;
        bestDay = _getDayName(day);
      }
    });

    return bestDay;
  }

  String? _getBestFocusTime() {
    if (_focusSessions.length < 5) return null;
    
    final hourScores = <int, List<double>>{};
    
    for (final session in _focusSessions) {
      final hour = session.startTime.hour;
      hourScores.putIfAbsent(hour, () => []);
      hourScores[hour]!.add(session.focusScore ?? 0.0);
    }

    int bestHour = 9;
    double bestScore = 0.0;
    
    hourScores.forEach((hour, scores) {
      if (scores.length >= 3) { // Need at least 3 sessions
        final avgScore = scores.reduce((a, b) => a + b) / scores.length;
        if (avgScore > bestScore) {
          bestScore = avgScore;
          bestHour = hour;
        }
      }
    });

    return '$bestHour:00';
  }

  List<String> _analyzeCommonDistractions(List<FocusSession> sessions) {
    final distractionCounts = <String, int>{};
    
    for (final session in sessions) {
      for (final distraction in session.distractions) {
        final key = distraction.appName ?? distraction.type.toString();
        distractionCounts[key] = (distractionCounts[key] ?? 0) + 1;
      }
    }

    final sorted = distractionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  double _calculateWeeklyProgress() {
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final weekSessions = _focusSessions
        .where((s) => s.startTime.isAfter(weekStart))
        .toList();

    final weeklyMinutes = weekSessions.fold(0, (total, session) => 
        total + (session.actualDuration?.inMinutes ?? 0));

    return weeklyMinutes / (_userGoals.weeklyMinutes ?? 300); // Default 5 hours/week
  }

  double _calculateGoalProgress() {
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthSessions = _focusSessions
        .where((s) => s.startTime.isAfter(monthStart))
        .toList();

    final monthlyMinutes = monthSessions.fold(0, (total, session) => 
        total + (session.actualDuration?.inMinutes ?? 0));

    return monthlyMinutes / (_userGoals.monthlyMinutes ?? 1200); // Default 20 hours/month
  }

  List<String> _generatePersonalizedTips(List<FocusSession> sessions) {
    final tips = <String>[];
    
    if (sessions.isEmpty) {
      return ['Start your first focus session to get personalized tips!'];
    }

    final avgFocusScore = sessions.map((s) => s.focusScore ?? 0.0).reduce((a, b) => a + b) / sessions.length;
    final avgDistractions = sessions.map((s) => s.distractions.length).reduce((a, b) => a + b) / sessions.length;

    if (avgFocusScore < 0.5) {
      tips.add('🎯 Try shorter 15-minute sessions to build focus stamina');
    }

    if (avgDistractions > 4) {
      tips.add('🚫 Enable stricter app blocking to reduce distractions');
    }

    final bestTime = _getBestFocusTime();
    if (bestTime != null) {
      tips.add('⏰ Your peak focus time is around $bestTime - schedule important tasks then');
    }

    if (_currentStreak.days < 3) {
      tips.add('🔥 Build a 7-day streak to unlock advanced analytics');
    }

    // Add seasonal tips
    final hour = DateTime.now().hour;
    if (hour < 10) {
      tips.add('🌅 Morning sessions tend to have 20% higher focus scores');
    } else if (hour > 20) {
      tips.add('🌙 Evening sessions work better with calming ambient sounds');
    }

    return tips.take(3).toList();
  }

  Future<void> _updateStreak(bool wasCompleted) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    if (wasCompleted) {
      if (_currentStreak.lastDate == null || 
          _currentStreak.lastDate!.isBefore(todayStart)) {
        // New day, extend streak
        _currentStreak = _currentStreak.copyWith(
          days: _currentStreak.days + 1,
          lastDate: todayStart,
        );
      }
    } else {
      // Incomplete session doesn't break streak, but doesn't extend it either
    }

    await _saveData();
  }

  Future<void> _checkAchievements() async {
    final achievements = <FocusAchievement>[];

    // First session achievement
    if (_focusSessions.length == 1) {
      achievements.add(FocusAchievement(
        id: 'first_session',
        title: 'First Focus!',
        description: 'Completed your first focus session',
        icon: '🎯',
        unlockedAt: DateTime.now(),
      ));
    }

    // Streak achievements
    if (_currentStreak.days == 7) {
      achievements.add(FocusAchievement(
        id: 'week_streak',
        title: 'Focus Week!',
        description: 'Maintained focus for 7 days straight',
        icon: '🔥',
        unlockedAt: DateTime.now(),
      ));
    }

    // Session achievements
    if (_focusSessions.length == 25) {
      achievements.add(FocusAchievement(
        id: 'pomodoro_master',
        title: 'Pomodoro Master',
        description: 'Completed 25 focus sessions',
        icon: '🍅',
        unlockedAt: DateTime.now(),
      ));
    }

    // High focus score achievement
    if (_currentSession?.focusScore != null && _currentSession!.focusScore! >= 0.95) {
      achievements.add(FocusAchievement(
        id: 'perfect_focus',
        title: 'Perfect Focus',
        description: 'Achieved 95%+ focus score',
        icon: '⭐',
        unlockedAt: DateTime.now(),
      ));
    }

    // Emit achievements
    for (final achievement in achievements) {
      _achievementController.add(achievement);
    }
  }

  Future<void> _generateInsights() async {
    final insights = await getInsights();
    _insightsController.add(insights);
  }

  String _getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  Duration _getAverageSessionDuration() {
    if (_focusSessions.isEmpty) return Duration.zero;
    
    final totalMs = _focusSessions.fold(0, (total, session) => 
        total + (session.actualDuration?.inMilliseconds ?? 0));
    
    return Duration(milliseconds: totalMs ~/ _focusSessions.length);
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load sessions
    final sessionsJson = prefs.getString(_sessionsKey);
    if (sessionsJson != null) {
      final List<dynamic> sessionsList = jsonDecode(sessionsJson);
      _focusSessions = sessionsList.map((json) => FocusSession.fromMap(json)).toList();
    }
    
    // Load distractions
    final distractionsJson = prefs.getString(_distractionsKey);
    if (distractionsJson != null) {
      final List<dynamic> distractionsList = jsonDecode(distractionsJson);
      _allDistractions = distractionsList.map((json) => FocusDistraction.fromMap(Map<String, dynamic>.from(json))).toList();
    }
    
    // Load streak
    final streakJson = prefs.getString(_streaksKey);
    if (streakJson != null) {
      _currentStreak = FocusStreak.fromMap(jsonDecode(streakJson));
    }
    
    // Load goals
    final goalsJson = prefs.getString(_goalsKey);
    if (goalsJson != null) {
      _userGoals = FocusGoals.fromMap(jsonDecode(goalsJson));
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_sessionsKey, jsonEncode(_focusSessions.map((s) => s.toMap()).toList()));
    await prefs.setString(_distractionsKey, jsonEncode(_allDistractions.map((d) => d.toMap()).toList()));
    await prefs.setString(_streaksKey, jsonEncode(_currentStreak.toMap()));
    await prefs.setString(_goalsKey, jsonEncode(_userGoals.toMap()));
  }

  Future<void> _calculateStreak() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // Find sessions from today
    final todaySessions = _focusSessions
        .where((s) => s.startTime.isAfter(todayStart) && s.wasCompleted)
        .toList();

    if (todaySessions.isNotEmpty && 
        (_currentStreak.lastDate == null || 
         _currentStreak.lastDate!.isBefore(todayStart))) {
      // Extend streak
      _currentStreak = _currentStreak.copyWith(
        days: _currentStreak.days + 1,
        lastDate: todayStart,
      );
    } else if (_currentStreak.lastDate != null && 
               todayStart.difference(_currentStreak.lastDate!).inDays > 1) {
      // Streak broken
      _currentStreak = FocusStreak.empty();
    }
  }

  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _insightsController.close();
    _achievementController.close();
  }
}

// Data classes

class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration plannedDuration;
  final Duration? actualDuration;
  final String sessionType;
  final bool wasCompleted;
  final List<FocusDistraction> distractions;
  final double? focusScore;
  final double? productivityScore;
  final Map<String, dynamic> metadata;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    this.actualDuration,
    required this.sessionType,
    this.wasCompleted = false,
    this.distractions = const [],
    this.focusScore,
    this.productivityScore,
    this.metadata = const {},
  });

  FocusSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    String? sessionType,
    bool? wasCompleted,
    List<FocusDistraction>? distractions,
    double? focusScore,
    double? productivityScore,
    Map<String, dynamic>? metadata,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      sessionType: sessionType ?? this.sessionType,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      distractions: distractions ?? this.distractions,
      focusScore: focusScore ?? this.focusScore,
      productivityScore: productivityScore ?? this.productivityScore,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'plannedDuration': plannedDuration.inMilliseconds,
      'actualDuration': actualDuration?.inMilliseconds,
      'sessionType': sessionType,
      'wasCompleted': wasCompleted,
      'distractions': distractions.map((d) => d.toMap()).toList(),
      'focusScore': focusScore,
      'productivityScore': productivityScore,
      'metadata': metadata,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: map['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endTime']) : null,
      plannedDuration: Duration(milliseconds: map['plannedDuration'] ?? 0),
      actualDuration: map['actualDuration'] != null ? Duration(milliseconds: map['actualDuration']) : null,
      sessionType: map['sessionType'] ?? 'pomodoro',
      wasCompleted: map['wasCompleted'] ?? false,
      distractions: (map['distractions'] as List<dynamic>? ?? [])
          .map((d) => FocusDistraction.fromMap(d))
          .toList(),
      focusScore: map['focusScore']?.toDouble(),
      productivityScore: map['productivityScore']?.toDouble(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class FocusStreak {
  final int days;
  final DateTime? lastDate;
  final int bestStreak;

  FocusStreak({
    required this.days,
    this.lastDate,
    required this.bestStreak,
  });

  FocusStreak.empty() : days = 0, lastDate = null, bestStreak = 0;

  FocusStreak copyWith({
    int? days,
    DateTime? lastDate,
    int? bestStreak,
  }) {
    return FocusStreak(
      days: days ?? this.days,
      lastDate: lastDate ?? this.lastDate,
      bestStreak: bestStreak ?? max(this.bestStreak, days ?? this.days),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'lastDate': lastDate?.millisecondsSinceEpoch,
      'bestStreak': bestStreak,
    };
  }

  factory FocusStreak.fromMap(Map<String, dynamic> map) {
    return FocusStreak(
      days: map['days'] ?? 0,
      lastDate: map['lastDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastDate']) : null,
      bestStreak: map['bestStreak'] ?? 0,
    );
  }
}

class FocusGoals {
  final int? dailyMinutes;
  final int? weeklyMinutes;
  final int? monthlyMinutes;
  final int? dailySessions;
  final double? targetFocusScore;

  FocusGoals({
    this.dailyMinutes,
    this.weeklyMinutes,
    this.monthlyMinutes,
    this.dailySessions,
    this.targetFocusScore,
  });

  FocusGoals.defaultGoals() : 
    dailyMinutes = 60,
    weeklyMinutes = 300,
    monthlyMinutes = 1200,
    dailySessions = 3,
    targetFocusScore = 0.8;

  Map<String, dynamic> toMap() {
    return {
      'dailyMinutes': dailyMinutes,
      'weeklyMinutes': weeklyMinutes,
      'monthlyMinutes': monthlyMinutes,
      'dailySessions': dailySessions,
      'targetFocusScore': targetFocusScore,
    };
  }

  factory FocusGoals.fromMap(Map<String, dynamic> map) {
    return FocusGoals(
      dailyMinutes: map['dailyMinutes'],
      weeklyMinutes: map['weeklyMinutes'],
      monthlyMinutes: map['monthlyMinutes'],
      dailySessions: map['dailySessions'],
      targetFocusScore: map['targetFocusScore']?.toDouble(),
    );
  }
}

class FocusInsights {
  final int totalSessions;
  final Duration totalFocusTime;
  final Duration averageSessionDuration;
  final double completionRate;
  final double averageFocusScore;
  final int totalDistractions;
  final String bestProductivityDay;
  final String? bestFocusTime;
  final List<String> commonDistractions;
  final double weeklyProgress;
  final double monthlyGoalProgress;
  final List<FocusTrend> focusTrends;
  final List<String> personalizedTips;

  FocusInsights({
    required this.totalSessions,
    required this.totalFocusTime,
    required this.averageSessionDuration,
    required this.completionRate,
    required this.averageFocusScore,
    required this.totalDistractions,
    required this.bestProductivityDay,
    this.bestFocusTime,
    required this.commonDistractions,
    required this.weeklyProgress,
    required this.monthlyGoalProgress,
    required this.focusTrends,
    required this.personalizedTips,
  });

  FocusInsights.empty() : 
    totalSessions = 0,
    totalFocusTime = Duration.zero,
    averageSessionDuration = Duration.zero,
    completionRate = 0.0,
    averageFocusScore = 0.0,
    totalDistractions = 0,
    bestProductivityDay = 'Monday',
    bestFocusTime = null,
    commonDistractions = const [],
    weeklyProgress = 0.0,
    monthlyGoalProgress = 0.0,
    focusTrends = const [],
    personalizedTips = const ['Start your first focus session to unlock insights!'];
}

class FocusTrend {
  final DateTime date;
  final Duration totalFocusTime;
  final int sessionCount;
  final double averageFocusScore;
  final int distractionCount;

  FocusTrend({
    required this.date,
    required this.totalFocusTime,
    required this.sessionCount,
    required this.averageFocusScore,
    required this.distractionCount,
  });
}

class FocusRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final double priority;
  final bool actionable;

  FocusRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionable,
  });
}

enum RecommendationType {
  habit,
  technique, 
  environment,
  timing,
  goal,
}

class FocusAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  FocusAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
    };
  }
}

