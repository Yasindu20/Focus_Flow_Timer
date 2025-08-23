import 'package:flutter/material.dart';
import 'dart:async';

import '../services/firebase_service.dart';
import '../models/daily_stats.dart';
import '../models/task_analytics.dart';
import '../models/ai_insights.dart';
import '../models/enhanced_task.dart';
import '../models/pomodoro_session.dart';

/// Firebase-powered Analytics Provider for enterprise-level insights
/// Provides real-time analytics, productivity insights, and AI-powered recommendations
class FirebaseAnalyticsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  
  // Analytics data
  DailyStats? _todayStats;
  List<DailyStats> _weeklyStats = [];
  List<DailyStats> _monthlyStats = [];
  UserAnalytics? _userAnalytics;
  ProductivityInsights? _productivityInsights;
  TaskEfficiencyAnalysis? _efficiencyAnalysis;
  InterruptionAnalysis? _interruptionAnalysis;
  PredictiveAnalytics? _predictiveAnalytics;
  ComparativeAnalytics? _comparativeAnalytics;
  
  // Real-time metrics
  Map<String, dynamic> _realtimeMetrics = {};
  Map<TaskCategory, double> _categoryPerformance = {};
  Map<String, double> _dailyTrends = {};
  Map<String, int> _weeklyTasks = {};
  
  // State management
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  
  // Subscriptions for real-time updates
  StreamSubscription<List<PomodoroSession>>? _sessionsSubscription;
  StreamSubscription<List<EnhancedTask>>? _tasksSubscription;
  Timer? _refreshTimer;

  FirebaseAnalyticsProvider({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _initializeProvider();
  }

  // Getters
  DailyStats? get todayStats => _todayStats;
  List<DailyStats> get weeklyStats => _weeklyStats;
  List<DailyStats> get monthlyStats => _monthlyStats;
  UserAnalytics? get userAnalytics => _userAnalytics;
  ProductivityInsights? get productivityInsights => _productivityInsights;
  TaskEfficiencyAnalysis? get efficiencyAnalysis => _efficiencyAnalysis;
  InterruptionAnalysis? get interruptionAnalysis => _interruptionAnalysis;
  PredictiveAnalytics? get predictiveAnalytics => _predictiveAnalytics;
  ComparativeAnalytics? get comparativeAnalytics => _comparativeAnalytics;
  
  Map<String, dynamic> get realtimeMetrics => _realtimeMetrics;
  Map<TaskCategory, double> get categoryPerformance => _categoryPerformance;
  Map<String, double> get dailyTrends => _dailyTrends;
  Map<String, int> get weeklyTasks => _weeklyTasks;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  // Quick access getters
  double get todayFocusScore => _todayStats?.averageFocusScore ?? 0.0;
  int get todaySessions => _todayStats?.completedPomodoros ?? 0;
  int get todayMinutes => (_todayStats?.totalFocusTime.inMinutes ?? 0);
  int get todayTasks => _todayStats?.tasksCompleted ?? 0;
  int get todayInterruptions => _todayStats?.interruptions ?? 0;

  // Performance indicators
  String get focusScoreText {
    final score = todayFocusScore * 100;
    if (score >= 90) return 'Outstanding';
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Needs Improvement';
    return 'Getting Started';
  }

  Color get focusScoreColor {
    final score = todayFocusScore * 100;
    if (score >= 90) return Colors.green.shade700;
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 60) return Colors.lime;
    if (score >= 50) return Colors.orange;
    if (score >= 30) return Colors.deepOrange;
    return Colors.red;
  }

  String get productivityTrend {
    if (_dailyTrends.isEmpty) return 'No data';
    
    final values = _dailyTrends.values.toList();
    if (values.length < 2) return 'Insufficient data';
    
    final recent = values.takeLast(3).toList();
    final average = recent.reduce((a, b) => a + b) / recent.length;
    final previous = values.takeLast(6).take(3).toList();
    final prevAverage = previous.isEmpty ? 0.0 : previous.reduce((a, b) => a + b) / previous.length;
    
    if (average > prevAverage * 1.1) return 'Improving';
    if (average < prevAverage * 0.9) return 'Declining';
    return 'Stable';
  }

  /// Initialize the analytics provider
  Future<void> _initializeProvider() async {
    _firebaseService.addListener(_onFirebaseServiceChanged);
    
    if (_firebaseService.isAuthenticated) {
      await _loadAnalyticsData();
      _setupRealTimeTracking();
      _setupPeriodicRefresh();
    }
  }

  /// Handle Firebase service state changes
  void _onFirebaseServiceChanged() {
    if (_firebaseService.isAuthenticated && _todayStats == null) {
      _loadAnalyticsData();
      _setupRealTimeTracking();
      _setupPeriodicRefresh();
    } else if (!_firebaseService.isAuthenticated) {
      _clearAnalyticsData();
    }
  }

  /// Load comprehensive analytics data
  Future<void> _loadAnalyticsData() async {
    if (!_firebaseService.isAuthenticated) return;

    try {
      _setLoading(true);
      _clearError();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Load analytics for different time periods
      await Future.wait([
        _loadDailyStats(today),
        _loadWeeklyStats(),
        _loadMonthlyStats(),
        _loadUserAnalytics(),
        _loadProductivityInsights(),
        _loadRealTimeMetrics(),
      ]);

      _lastUpdated = DateTime.now();
      debugPrint('✅ Analytics data loaded successfully');

    } catch (e, stack) {
      _setError('Failed to load analytics: ${e.toString()}');
      debugPrint('❌ Analytics loading failed: $e');
      debugPrint('Stack trace: $stack');
    } finally {
      _setLoading(false);
    }
  }

  /// Load today's statistics
  Future<void> _loadDailyStats(DateTime date) async {
    try {
      final sessions = await _firebaseService.getUserSessions(
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
      ).first;

      if (sessions.isEmpty) {
        _todayStats = DailyStats(
          date: date,
          completedPomodoros: 0,
          totalFocusTime: Duration.zero,
          totalBreakTime: Duration.zero,
          interruptions: 0,
          tasksCompleted: 0,
          averageFocusScore: 0.0,
        );
        return;
      }

      // Calculate statistics from sessions
      int completedPomodoros = 0;
      Duration totalFocusTime = Duration.zero;
      Duration totalBreakTime = Duration.zero;
      int totalInterruptions = 0;
      double totalFocusScore = 0.0;
      Set<String> completedTasks = {};

      for (final session in sessions) {
        if (session.sessionType == SessionType.work) {
          completedPomodoros++;
          totalFocusTime += session.duration;
          totalFocusScore += session.focusScore ?? 0.8;
        } else {
          totalBreakTime += session.duration;
        }
        totalInterruptions += session.interruptions;
        
        if (session.taskId != null) {
          completedTasks.add(session.taskId!);
        }
      }

      _todayStats = DailyStats(
        date: date,
        completedPomodoros: completedPomodoros,
        totalFocusTime: totalFocusTime,
        totalBreakTime: totalBreakTime,
        interruptions: totalInterruptions,
        tasksCompleted: completedTasks.length,
        averageFocusScore: completedPomodoros > 0 ? totalFocusScore / completedPomodoros : 0.0,
      );

    } catch (e) {
      debugPrint('❌ Failed to load daily stats: $e');
    }
  }

  /// Load weekly statistics
  Future<void> _loadWeeklyStats() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      _weeklyStats.clear();
      _weeklyTasks.clear();

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        await _loadDailyStats(date);
        if (_todayStats != null) {
          _weeklyStats.add(_todayStats!);
          _weeklyTasks[_getDayName(i)] = _todayStats!.tasksCompleted;
        }
      }

      // Restore today's stats
      await _loadDailyStats(DateTime.now());

    } catch (e) {
      debugPrint('❌ Failed to load weekly stats: $e');
    }
  }

  /// Load monthly statistics
  Future<void> _loadMonthlyStats() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      _monthlyStats.clear();

      final sessions = await _firebaseService.getUserSessions(
        startDate: monthStart,
        endDate: now.add(const Duration(days: 1)),
      ).first;

      // Group sessions by day
      final Map<String, List<PomodoroSession>> sessionsByDay = {};
      for (final session in sessions) {
        final dayKey = '${session.createdAt.year}-${session.createdAt.month}-${session.createdAt.day}';
        sessionsByDay[dayKey] ??= [];
        sessionsByDay[dayKey]!.add(session);
      }

      // Create daily stats for each day
      for (final entry in sessionsByDay.entries) {
        final daySessions = entry.value;
        final date = daySessions.first.createdAt;
        final dayDate = DateTime(date.year, date.month, date.day);

        await _loadDailyStats(dayDate);
        if (_todayStats != null) {
          _monthlyStats.add(_todayStats!);
        }
      }

    } catch (e) {
      debugPrint('❌ Failed to load monthly stats: $e');
    }
  }

  /// Load comprehensive user analytics
  Future<void> _loadUserAnalytics() async {
    try {
      _userAnalytics = await _firebaseService.getUserAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Failed to load user analytics: $e');
    }
  }

  /// Load AI-powered productivity insights
  Future<void> _loadProductivityInsights() async {
    try {
      _productivityInsights = await _firebaseService.getProductivityInsights();
    } catch (e) {
      debugPrint('❌ Failed to load productivity insights: $e');
    }
  }

  /// Load real-time metrics
  Future<void> _loadRealTimeMetrics() async {
    try {
      // Calculate real-time performance metrics
      _realtimeMetrics = {
        'daily_productivity_score': _calculateDailyProductivityScore(),
        'weekly_average_focus': _calculateWeeklyAverageFocus(),
        'task_completion_rate': _calculateTaskCompletionRate(),
        'improvement_percentage': _calculateImprovementPercentage(),
        'streak_days': _calculateStreakDays(),
        'efficiency_trend': _calculateEfficiencyTrend(),
      };

      // Calculate category performance
      await _calculateCategoryPerformance();
      
      // Calculate daily trends
      _calculateDailyTrends();

    } catch (e) {
      debugPrint('❌ Failed to load real-time metrics: $e');
    }
  }

  /// Set up real-time tracking of sessions and tasks
  void _setupRealTimeTracking() {
    _sessionsSubscription?.cancel();
    _tasksSubscription?.cancel();

    if (!_firebaseService.isAuthenticated) return;

    // Track sessions in real-time
    _sessionsSubscription = _firebaseService.getUserSessions().listen(
      (sessions) {
        _updateRealTimeMetricsFromSessions(sessions);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Real-time sessions tracking error: $error');
      },
    );

    // Track tasks in real-time
    _tasksSubscription = _firebaseService.getUserTasks().listen(
      (tasks) {
        _updateRealTimeMetricsFromTasks(tasks);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Real-time tasks tracking error: $error');
      },
    );
  }

  /// Set up periodic data refresh
  void _setupPeriodicRefresh() {
    _refreshTimer?.cancel();
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadRealTimeMetrics();
    });

    // Full refresh every hour
    Timer.periodic(const Duration(hours: 1), (_) {
      refreshAnalytics();
    });
  }

  /// Update real-time metrics from session changes
  void _updateRealTimeMetricsFromSessions(List<PomodoroSession> sessions) {
    final today = DateTime.now();
    final todaySessions = sessions.where((s) => 
      s.createdAt.day == today.day &&
      s.createdAt.month == today.month &&
      s.createdAt.year == today.year
    ).toList();

    if (todaySessions.isNotEmpty) {
      // Update today's stats in real-time
      final workSessions = todaySessions.where((s) => s.sessionType == SessionType.work);
      final totalFocusTime = workSessions.fold<Duration>(
        Duration.zero, 
        (sum, session) => sum + session.duration
      );
      
      _realtimeMetrics['sessions_today'] = workSessions.length;
      _realtimeMetrics['focus_time_today'] = totalFocusTime.inMinutes;
      _realtimeMetrics['avg_session_length'] = workSessions.isEmpty 
          ? 0 
          : totalFocusTime.inMinutes / workSessions.length;
    }
  }

  /// Update real-time metrics from task changes
  void _updateRealTimeMetricsFromTasks(List<EnhancedTask> tasks) {
    final completedToday = tasks.where((task) => 
      task.isCompleted && 
      task.completedAt != null &&
      _isSameDay(task.completedAt!, DateTime.now())
    ).length;

    _realtimeMetrics['tasks_completed_today'] = completedToday;
    _realtimeMetrics['total_active_tasks'] = tasks.where((t) => !t.isCompleted).length;
  }

  /// Public methods for refreshing analytics
  Future<void> refreshAnalytics() async {
    await _loadAnalyticsData();
  }

  Future<void> refreshDailyStats() async {
    await _loadDailyStats(DateTime.now());
    notifyListeners();
  }

  /// Export analytics data
  Future<String> exportAnalytics({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_firebaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    return await _firebaseService.exportUserData(
      format: format,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get analytics summary for a date range
  Map<String, dynamic> getAnalyticsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final stats = _weeklyStats.isNotEmpty ? _weeklyStats : [_todayStats].whereType<DailyStats>().toList();
    
    if (stats.isEmpty) {
      return {
        'total_sessions': 0,
        'total_focus_time': 0,
        'total_tasks': 0,
        'average_focus_score': 0.0,
        'total_interruptions': 0,
        'productivity_score': 0.0,
      };
    }

    final totalSessions = stats.fold<int>(0, (sum, stat) => sum + stat.completedPomodoros);
    final totalFocusTime = stats.fold<Duration>(Duration.zero, (sum, stat) => sum + stat.totalFocusTime);
    final totalTasks = stats.fold<int>(0, (sum, stat) => sum + stat.tasksCompleted);
    final totalInterruptions = stats.fold<int>(0, (sum, stat) => sum + stat.interruptions);
    final avgFocusScore = stats.fold<double>(0, (sum, stat) => sum + stat.averageFocusScore) / stats.length;

    return {
      'total_sessions': totalSessions,
      'total_focus_time': totalFocusTime.inMinutes,
      'total_tasks': totalTasks,
      'average_focus_score': avgFocusScore,
      'total_interruptions': totalInterruptions,
      'productivity_score': _calculateProductivityScore(stats),
      'days_analyzed': stats.length,
    };
  }

  /// Calculate productivity score
  double _calculateProductivityScore(List<DailyStats> stats) {
    if (stats.isEmpty) return 0.0;

    double score = 0.0;
    for (final stat in stats) {
      // Focus score weight: 40%
      score += stat.averageFocusScore * 0.4;
      
      // Session completion weight: 30%
      final sessionScore = (stat.completedPomodoros / 8).clamp(0.0, 1.0); // Assuming 8 sessions as ideal
      score += sessionScore * 0.3;
      
      // Task completion weight: 20%
      final taskScore = (stat.tasksCompleted / 5).clamp(0.0, 1.0); // Assuming 5 tasks as ideal
      score += taskScore * 0.2;
      
      // Low interruption bonus: 10%
      final interruptionPenalty = (stat.interruptions / 10).clamp(0.0, 1.0);
      score += (1 - interruptionPenalty) * 0.1;
    }

    return (score / stats.length).clamp(0.0, 1.0);
  }

  /// Helper methods for calculations
  double _calculateDailyProductivityScore() {
    return _todayStats != null ? _calculateProductivityScore([_todayStats!]) : 0.0;
  }

  double _calculateWeeklyAverageFocus() {
    if (_weeklyStats.isEmpty) return 0.0;
    return _weeklyStats.fold<double>(0, (sum, stat) => sum + stat.averageFocusScore) / _weeklyStats.length;
  }

  double _calculateTaskCompletionRate() {
    // This would require additional data about planned vs completed tasks
    return _todayStats?.tasksCompleted.toDouble() ?? 0.0;
  }

  double _calculateImprovementPercentage() {
    if (_weeklyStats.length < 2) return 0.0;
    
    final thisWeek = _weeklyStats.takeLast(3).toList();
    final lastWeek = _weeklyStats.take(_weeklyStats.length - 3).toList();
    
    if (thisWeek.isEmpty || lastWeek.isEmpty) return 0.0;
    
    final thisWeekAvg = thisWeek.fold<double>(0, (sum, stat) => sum + stat.averageFocusScore) / thisWeek.length;
    final lastWeekAvg = lastWeek.fold<double>(0, (sum, stat) => sum + stat.averageFocusScore) / lastWeek.length;
    
    return lastWeekAvg > 0 ? ((thisWeekAvg - lastWeekAvg) / lastWeekAvg) * 100 : 0.0;
  }

  int _calculateStreakDays() {
    if (_weeklyStats.isEmpty) return 0;
    
    int streak = 0;
    for (int i = _weeklyStats.length - 1; i >= 0; i--) {
      if (_weeklyStats[i].completedPomodoros > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _calculateEfficiencyTrend() {
    return productivityTrend;
  }

  Future<void> _calculateCategoryPerformance() async {
    // This would require task data with categories
    _categoryPerformance = {
      TaskCategory.coding: 0.8,
      TaskCategory.planning: 0.7,
      TaskCategory.testing: 0.75,
      TaskCategory.documentation: 0.6,
      TaskCategory.meeting: 0.5,
      TaskCategory.research: 0.85,
      TaskCategory.design: 0.9,
      TaskCategory.general: 0.65,
    };
  }

  void _calculateDailyTrends() {
    if (_weeklyStats.isEmpty) return;
    
    _dailyTrends.clear();
    for (int i = 0; i < _weeklyStats.length; i++) {
      final stat = _weeklyStats[i];
      _dailyTrends[_getDayName(i)] = _calculateProductivityScore([stat]);
    }
  }

  String _getDayName(int dayIndex) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayIndex % 7];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _clearAnalyticsData() {
    _todayStats = null;
    _weeklyStats.clear();
    _monthlyStats.clear();
    _userAnalytics = null;
    _productivityInsights = null;
    _realtimeMetrics.clear();
    _categoryPerformance.clear();
    _dailyTrends.clear();
    _weeklyTasks.clear();
    _lastUpdated = null;
    
    _sessionsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _refreshTimer?.cancel();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _refreshTimer?.cancel();
    _firebaseService.removeListener(_onFirebaseServiceChanged);
    super.dispose();
  }
}