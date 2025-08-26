import 'package:flutter/foundation.dart';
import '../services/productivity_score_service.dart';
import '../models/productivity_score.dart';

class ProductivityScoreProvider extends ChangeNotifier {
  final ProductivityScoreService _scoreService = ProductivityScoreService();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  ProductivityScore? get currentScore => _scoreService.currentScore;
  List<ProductivityScore> get weeklyScores => _scoreService.weeklyScores;
  List<ProductivityScore> get monthlyScores => _scoreService.monthlyScores;
  List<double> get weeklyTrend => _scoreService.weeklyTrend;
  List<double> get monthlyTrend => _scoreService.monthlyTrend;
  double get averageWeeklyScore => _scoreService.averageWeeklyScore;
  double get averageMonthlyScore => _scoreService.averageMonthlyScore;

  ProductivityScoreProvider() {
    _scoreService.addListener(_onScoreServiceChange);
  }

  void _onScoreServiceChange() {
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _scoreService.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ProductivityScoreProvider initialization error: $e');
    }
  }

  Future<void> calculateAndUpdateScore({
    required List todaySessions,
    required List completedTasks,
    required int streakDays,
    required Map<String, List> categorizedSessions,
  }) async {
    await _scoreService.calculateAndUpdateScore(
      todaySessions: todaySessions.cast(),
      completedTasks: completedTasks.cast(),
      streakDays: streakDays,
      categorizedSessions: categorizedSessions.cast(),
    );
  }

  Map<String, dynamic> getProductivityInsights() {
    return _scoreService.getProductivityInsights();
  }

  Map<String, dynamic> getScoreBreakdown() {
    return _scoreService.getScoreBreakdown();
  }

  Future<void> resetScores() async {
    await _scoreService.resetScores();
  }

  @override
  void dispose() {
    _scoreService.removeListener(_onScoreServiceChange);
    super.dispose();
  }
}