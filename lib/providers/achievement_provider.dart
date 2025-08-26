import 'package:flutter/foundation.dart';
import '../services/achievement_service.dart';
import '../models/achievement.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<Achievement> get achievements => _achievementService.achievements;
  List<Achievement> get userAchievements => _achievementService.userAchievements;
  List<Achievement> get unlockedAchievements => _achievementService.unlockedAchievements;
  List<Achievement> get lockedAchievements => _achievementService.lockedAchievements;
  int get totalPoints => _achievementService.totalPoints;
  int get unlockedCount => _achievementService.unlockedCount;
  double get completionPercentage => _achievementService.completionPercentage;

  AchievementProvider() {
    _achievementService.addListener(_onAchievementServiceChange);
  }

  void _onAchievementServiceChange() {
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _achievementService.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AchievementProvider initialization error: $e');
    }
  }

  Future<void> updateProgress({
    required dynamic session,
    dynamic completedTask,
    int? streakDays,
    int? totalSessions,
    int? totalFocusMinutes,
    int? perfectSessions,
    int? tasksCompleted,
    Map<String, dynamic>? additionalData,
  }) async {
    await _achievementService.updateProgress(
      session: session,
      completedTask: completedTask,
      streakDays: streakDays,
      totalSessions: totalSessions,
      totalFocusMinutes: totalFocusMinutes,
      perfectSessions: perfectSessions,
      tasksCompleted: tasksCompleted,
      additionalData: additionalData,
    );
  }

  Achievement? getAchievementById(String id) {
    return _achievementService.getAchievementById(id);
  }

  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievementService.getAchievementsByType(type);
  }

  List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return _achievementService.getAchievementsByRarity(rarity);
  }

  Map<AchievementRarity, List<Achievement>> getAchievementsByRarityMap() {
    return _achievementService.getAchievementsByRarityMap();
  }

  List<Achievement> getNearlyCompleteAchievements() {
    return _achievementService.getNearlyCompleteAchievements();
  }

  Future<void> resetAchievements() async {
    await _achievementService.resetAchievements();
  }

  Future<void> unlockAchievement(String achievementId) async {
    await _achievementService.unlockAchievement(achievementId);
  }

  @override
  void dispose() {
    _achievementService.removeListener(_onAchievementServiceChange);
    super.dispose();
  }
}