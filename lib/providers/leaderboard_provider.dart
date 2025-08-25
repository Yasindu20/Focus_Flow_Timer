import 'package:flutter/foundation.dart';
import '../services/leaderboard_service.dart';
import '../models/leaderboard.dart';
import '../models/productivity_score.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _leaderboardService = LeaderboardService();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Map<LeaderboardType, Leaderboard> get leaderboards => _leaderboardService.leaderboards;
  LeaderboardEntry? get userEntry => _leaderboardService.userEntry;
  bool get isOnline => _leaderboardService.isOnline;

  LeaderboardProvider() {
    _leaderboardService.addListener(_onLeaderboardServiceChange);
  }

  void _onLeaderboardServiceChange() {
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _leaderboardService.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('LeaderboardProvider initialization error: $e');
    }
  }

  Leaderboard? getLeaderboard(LeaderboardType type) {
    return _leaderboardService.getLeaderboard(type);
  }

  Future<void> updateUserStats({
    required ProductivityScore productivityScore,
    required int totalFocusMinutes,
    required int sessionsCompleted,
    required int streakDays,
    required int tasksCompleted,
    List<String>? newAchievements,
  }) async {
    await _leaderboardService.updateUserStats(
      productivityScore: productivityScore,
      totalFocusMinutes: totalFocusMinutes,
      sessionsCompleted: sessionsCompleted,
      streakDays: streakDays,
      tasksCompleted: tasksCompleted,
      newAchievements: newAchievements,
    );
  }

  Future<void> refreshLeaderboards() async {
    await _leaderboardService.refreshLeaderboards();
  }

  int? getUserRank(LeaderboardType type) {
    return _leaderboardService.getUserRank(type);
  }

  List<LeaderboardEntry> getNearbyUsers(LeaderboardType type, {int range = 5}) {
    return _leaderboardService.getNearbyUsers(type, range: range);
  }

  List<LeaderboardEntry> getTopPerformers(LeaderboardType type, {int count = 10}) {
    return _leaderboardService.getTopPerformers(type, count: count);
  }

  bool hasImprovedRank(LeaderboardType type, int previousRank) {
    return _leaderboardService.hasImprovedRank(type, previousRank);
  }

  Map<String, dynamic> getLeaderboardInsights() {
    return _leaderboardService.getLeaderboardInsights();
  }

  Future<void> resetUserStats() async {
    await _leaderboardService.resetUserStats();
  }

  Future<void> simulateLeaderboardUpdate() async {
    await _leaderboardService.simulateLeaderboardUpdate();
  }

  @override
  void dispose() {
    _leaderboardService.removeListener(_onLeaderboardServiceChange);
    super.dispose();
  }
}