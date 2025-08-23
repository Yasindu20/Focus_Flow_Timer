import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/task_analytics.dart';
import '../models/enhanced_task.dart';

class FirebaseAnalyticsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  UserAnalytics? _currentAnalytics;
  Map<String, dynamic>? _productivityInsights;
  List<EnhancedTask> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Getters
  UserAnalytics? get currentAnalytics => _currentAnalytics;
  Map<String, dynamic>? get productivityInsights => _productivityInsights;
  List<EnhancedTask> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  // Calculate and load user analytics
  Future<void> loadAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    bool force = false,
  }) async {
    // Skip if already loading or recently loaded (unless forced)
    if (_isLoading || (!force && _lastUpdated != null && 
        DateTime.now().difference(_lastUpdated!).inMinutes < 5)) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final analytics = await _firebaseService.calculateUserAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      _currentAnalytics = analytics;
      _lastUpdated = DateTime.now();
      
      debugPrint('Analytics loaded successfully');
    } catch (e) {
      _setError('Failed to load analytics: ${e.toString()}');
      debugPrint('Analytics loading error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load productivity insights
  Future<void> loadProductivityInsights({bool force = false}) async {
    if (_isLoading || (!force && _productivityInsights != null && 
        _lastUpdated != null && DateTime.now().difference(_lastUpdated!).inHours < 1)) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final insights = await _firebaseService.generateProductivityInsights();
      _productivityInsights = insights;
      
      debugPrint('Productivity insights loaded successfully');
    } catch (e) {
      _setError('Failed to load insights: ${e.toString()}');
      debugPrint('Insights loading error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load task recommendations
  Future<void> loadTaskRecommendations({bool force = false}) async {
    if (_isLoading || (!force && _recommendations.isNotEmpty && 
        _lastUpdated != null && DateTime.now().difference(_lastUpdated!).inHours < 2)) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final recommendations = await _firebaseService.getTaskRecommendations();
      _recommendations = recommendations;
      
      debugPrint('Task recommendations loaded: ${recommendations.length} tasks');
    } catch (e) {
      _setError('Failed to load recommendations: ${e.toString()}');
      debugPrint('Recommendations loading error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get productivity score for display
  double get productivityScore {
    return _currentAnalytics?.productivityScore ?? 0.0;
  }

  // Get focus score for display
  double get focusScore {
    return _currentAnalytics?.focusScore ?? 0.0;
  }

  // Get estimation accuracy for display
  double get estimationAccuracy {
    return _currentAnalytics?.estimationAccuracy ?? 0.0;
  }

  // Get total tasks completed
  int get totalTasksCompleted {
    return _currentAnalytics?.totalTasksCompleted ?? 0;
  }

  // Get total time spent (in hours)
  double get totalHoursSpent {
    final milliseconds = _currentAnalytics?.totalTimeSpent.inMilliseconds ?? 0;
    return milliseconds / (1000 * 60 * 60);
  }

  // Get average session length (in minutes)
  double get averageSessionMinutes {
    final milliseconds = _currentAnalytics?.averageSessionLength.inMilliseconds ?? 0;
    return milliseconds / (1000 * 60);
  }

  // Get productivity trend
  ProductivityTrendDirection get productivityTrend {
    return _currentAnalytics?.recentTrend ?? ProductivityTrendDirection.stable;
  }

  // Get insights list
  List<String> get insights {
    return _productivityInsights?['insights']?.cast<String>() ?? [];
  }

  // Get suggestions list
  List<String> get suggestions {
    return _productivityInsights?['suggestions']?.cast<String>() ?? [];
  }

  // Get achievements list
  List<String> get achievements {
    return _productivityInsights?['achievements']?.cast<String>() ?? [];
  }

  // Get trends data
  List<Map<String, dynamic>> get trends {
    return _productivityInsights?['trends']?.cast<Map<String, dynamic>>() ?? [];
  }

  // Get category performance
  Map<TaskCategory, CategoryPerformance> get categoryPerformance {
    return _currentAnalytics?.categoryPerformance ?? {};
  }

  // Get best performing category
  TaskCategory? get bestCategory {
    final performance = categoryPerformance;
    if (performance.isEmpty) return null;

    TaskCategory? bestCategory;
    double bestScore = 0;

    for (final entry in performance.entries) {
      if (entry.value.productivityScore > bestScore) {
        bestScore = entry.value.productivityScore;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  // Get preferred working hours
  List<int> get preferredWorkingHours {
    return _currentAnalytics?.preferredWorkingHours ?? [];
  }

  // Get most productive day
  int get mostProductiveDay {
    return _currentAnalytics?.mostProductiveDay ?? 1;
  }

  // Get top recommendations (first 3)
  List<EnhancedTask> get topRecommendations {
    return _recommendations.take(3).toList();
  }

  // Export analytics data
  Future<Map<String, dynamic>?> exportAnalytics({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final exportResult = await _firebaseService.exportUserData(
        format: format,
        startDate: startDate,
        endDate: endDate,
      );

      return exportResult;
    } catch (e) {
      _setError('Failed to export analytics: ${e.toString()}');
      debugPrint('Export error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh all analytics data
  Future<void> refreshAll() async {
    await Future.wait([
      loadAnalytics(force: true),
      loadProductivityInsights(force: true),
      loadTaskRecommendations(force: true),
    ]);
  }

  // Get analytics for a specific date range
  Future<UserAnalytics?> getAnalyticsForPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _firebaseService.calculateUserAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error getting period analytics: $e');
      return null;
    }
  }

  // Get weekly analytics
  Future<UserAnalytics?> getWeeklyAnalytics() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return getAnalyticsForPeriod(startOfWeek, endOfWeek);
  }

  // Get monthly analytics
  Future<UserAnalytics?> getMonthlyAnalytics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    
    return getAnalyticsForPeriod(startOfMonth, endOfMonth);
  }

  // Get yearly analytics
  Future<UserAnalytics?> getYearlyAnalytics() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    return getAnalyticsForPeriod(startOfYear, endOfYear);
  }

  // Get productivity score trend (last 7 days)
  List<double> getProductivityTrend({int days = 7}) {
    // This would ideally fetch daily scores from the backend
    // For now, generate mock trend data
    final scores = <double>[];
    final baseScore = productivityScore;
    
    for (int i = 0; i < days; i++) {
      // Add some variation to the base score
      final variation = (i % 3 - 1) * 0.1; // -0.1 to +0.1
      scores.add((baseScore + variation).clamp(0.0, 1.0));
    }
    
    return scores;
  }

  // Get category distribution for charts
  Map<String, double> getCategoryDistribution() {
    final distribution = <String, double>{};
    final performance = categoryPerformance;
    
    for (final entry in performance.entries) {
      distribution[entry.key.name] = entry.value.totalTasks.toDouble();
    }
    
    return distribution;
  }

  // Get time distribution by hour
  Map<int, double> getTimeDistributionByHour() {
    // This would come from the analytics data
    // For now, return mock data based on preferred hours
    final distribution = <int, double>{};
    
    for (final hour in preferredWorkingHours) {
      distribution[hour] = (totalHoursSpent / preferredWorkingHours.length);
    }
    
    return distribution;
  }

  // Get completion rate by category
  Map<String, double> getCompletionRateByCategory() {
    final rates = <String, double>{};
    final performance = categoryPerformance;
    
    for (final entry in performance.entries) {
      final totalTasks = entry.value.totalTasks;
      final completedTasks = entry.value.completedTasks;
      
      if (totalTasks > 0) {
        rates[entry.key.name] = completedTasks / totalTasks;
      }
    }
    
    return rates;
  }

  // Clear all cached data
  void clearCache() {
    _currentAnalytics = null;
    _productivityInsights = null;
    _recommendations.clear();
    _lastUpdated = null;
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Initialize analytics on provider creation
  Future<void> initialize() async {
    if (_firebaseService.isAuthenticated) {
      await loadAnalytics();
      await loadTaskRecommendations();
    }
  }

  // Check if data needs refresh
  bool get needsRefresh {
    return _lastUpdated == null || 
           DateTime.now().difference(_lastUpdated!).inMinutes > 30;
  }

  // Auto-refresh if data is stale
  Future<void> autoRefreshIfNeeded() async {
    if (needsRefresh && !_isLoading) {
      await refreshAll();
    }
  }
}

// Extension to get day name from number
extension DayName on int {
  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(this - 1) % 7];
  }
}

// Extension to format category name
extension CategoryName on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.general:
        return 'General';
      case TaskCategory.coding:
        return 'Coding';
      case TaskCategory.writing:
        return 'Writing';
      case TaskCategory.meeting:
        return 'Meeting';
      case TaskCategory.research:
        return 'Research';
      case TaskCategory.design:
        return 'Design';
      case TaskCategory.planning:
        return 'Planning';
      case TaskCategory.review:
        return 'Review';
      case TaskCategory.testing:
        return 'Testing';
      case TaskCategory.documentation:
        return 'Documentation';
      case TaskCategory.communication:
        return 'Communication';
      case TaskCategory.maintenance:
        return 'Maintenance';
      case TaskCategory.learning:
        return 'Learning';
    }
  }
}