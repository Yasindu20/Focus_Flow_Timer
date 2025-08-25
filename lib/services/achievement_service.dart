import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievement.dart';
import '../models/pomodoro_session.dart';
import '../models/task.dart';
import 'optimized_storage_service.dart';

class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OptimizedStorageService _storage = OptimizedStorageService();

  List<Achievement> _achievements = [];
  List<Achievement> _userAchievements = [];
  bool _isInitialized = false;

  List<Achievement> get achievements => _achievements;
  List<Achievement> get userAchievements => _userAchievements;
  List<Achievement> get unlockedAchievements =>
      _userAchievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements =>
      _userAchievements.where((a) => !a.isUnlocked).toList();

  int get totalPoints => unlockedAchievements.fold(0, (total, a) => total + a.points);
  int get unlockedCount => unlockedAchievements.length;
  double get completionPercentage =>
      _achievements.isEmpty ? 0 : (unlockedCount / _achievements.length) * 100;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load all achievement definitions
      _achievements = AchievementDefinitions.getAllAchievements();
      
      // Load user's achievement progress
      await _loadUserAchievements();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Achievement service initialization error: $e');
    }
  }

  Future<void> _loadUserAchievements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Load from local storage
        await _loadFromLocal();
        return;
      }

      // Try to load from Firestore
      try {
        final doc = await _firestore
            .collection('user_achievements')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final achievementData = List<Map<String, dynamic>>.from(
              data['achievements'] ?? []);
          
          _userAchievements = achievementData
              .map((json) => Achievement.fromJson(json))
              .toList();
        } else {
          _initializeUserAchievements();
        }
      } catch (e) {
        debugPrint('Firestore load error, falling back to local: $e');
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint('Error loading user achievements: $e');
      _initializeUserAchievements();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final achievementData = await _storage.getAchievements();
      if (achievementData.isNotEmpty) {
        _userAchievements = achievementData
            .map((json) => Achievement.fromJson(json))
            .toList();
      } else {
        _initializeUserAchievements();
      }
    } catch (e) {
      debugPrint('Local load error: $e');
      _initializeUserAchievements();
    }
  }

  void _initializeUserAchievements() {
    _userAchievements = _achievements.map((achievement) => achievement.copyWith(
          currentValue: 0,
          isUnlocked: false,
        )).toList();
  }

  Future<void> updateProgress({
    required PomodoroSession session,
    Task? completedTask,
    int? streakDays,
    int? totalSessions,
    int? totalFocusMinutes,
    int? perfectSessions,
    int? tasksCompleted,
    Map<String, dynamic>? additionalData,
  }) async {
    List<Achievement> newlyUnlocked = [];

    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      if (achievement.isUnlocked) continue;

      int newValue = _calculateNewValue(
        achievement: achievement,
        session: session,
        completedTask: completedTask,
        streakDays: streakDays,
        totalSessions: totalSessions,
        totalFocusMinutes: totalFocusMinutes,
        perfectSessions: perfectSessions,
        tasksCompleted: tasksCompleted,
        additionalData: additionalData,
      );

      bool wasUpdated = false;
      bool wasUnlocked = false;

      if (newValue > achievement.currentValue) {
        wasUpdated = true;
        if (newValue >= achievement.targetValue && !achievement.isUnlocked) {
          wasUnlocked = true;
          newlyUnlocked.add(achievement);
        }
      }

      if (wasUpdated) {
        _userAchievements[i] = achievement.copyWith(
          currentValue: newValue,
          isUnlocked: wasUnlocked || achievement.isUnlocked,
          unlockedAt: wasUnlocked ? DateTime.now() : achievement.unlockedAt,
        );
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
      _notifyNewAchievements(newlyUnlocked);
    }

    notifyListeners();
  }

  int _calculateNewValue({
    required Achievement achievement,
    required PomodoroSession session,
    Task? completedTask,
    int? streakDays,
    int? totalSessions,
    int? totalFocusMinutes,
    int? perfectSessions,
    int? tasksCompleted,
    Map<String, dynamic>? additionalData,
  }) {
    switch (achievement.type) {
      case AchievementType.sessionCount:
        return totalSessions ?? achievement.currentValue + 1;

      case AchievementType.totalFocusTime:
        int sessionMinutes = session.duration ~/ 60000; // Convert ms to minutes
        return (totalFocusMinutes ?? achievement.currentValue + sessionMinutes);

      case AchievementType.streakDays:
        return streakDays ?? achievement.currentValue;

      case AchievementType.tasksCompleted:
        if (completedTask != null) {
          return tasksCompleted ?? achievement.currentValue + 1;
        }
        return achievement.currentValue;

      case AchievementType.perfectSessions:
        if (session.interruptions == 0 && session.completed) {
          return perfectSessions ?? achievement.currentValue + 1;
        }
        return achievement.currentValue;

      case AchievementType.earlyBird:
        if (session.startTime.hour < 9) {
          return achievement.currentValue + 1;
        }
        return achievement.currentValue;

      case AchievementType.nightOwl:
        if (session.startTime.hour >= 21) {
          return achievement.currentValue + 1;
        }
        return achievement.currentValue;

      case AchievementType.weekendWarrior:
        if (session.startTime.weekday >= 6) { // Saturday = 6, Sunday = 7
          return achievement.currentValue + 1;
        }
        return achievement.currentValue;

      case AchievementType.productivity:
        // Handle special productivity achievements
        if (achievement.id == 'productive_day') {
          int dailySessions = additionalData?['dailySessions'] ?? 0;
          return dailySessions >= 8 ? 1 : 0;
        }
        return achievement.currentValue;

      case AchievementType.milestone:
        if (achievement.id == 'marathon_session') {
          int sessionMinutes = session.duration ~/ 60000;
          return sessionMinutes >= 120 ? 1 : 0;
        }
        return achievement.currentValue;

      case AchievementType.consistency:
        return additionalData?['consistencyDays'] ?? achievement.currentValue;

      case AchievementType.special:
        return _calculateSpecialAchievement(achievement, session, additionalData, completedTask);
    }
  }

  int _calculateSpecialAchievement(
    Achievement achievement,
    PomodoroSession session,
    Map<String, dynamic>? additionalData, [
    Task? completedTask,
  ]) {
    switch (achievement.id) {
      case 'first_week':
        return additionalData?['consecutiveDays'] ?? 0;
      case 'goal_crusher':
        double weeklyScore = additionalData?['weeklyProductivityScore'] ?? 0.0;
        return weeklyScore >= 100 ? 1 : 0;
      case 'zen_master':
        // Track meditation/break sessions separately
        return additionalData?['meditationSessions'] ?? achievement.currentValue;
      case 'speed_demon':
        if (completedTask != null) {
          int taskDuration = additionalData?['taskDuration'] ?? 0;
          if (taskDuration <= 15) {
            return achievement.currentValue + 1;
          }
        }
        return achievement.currentValue;
      case 'diversity_master':
        Set<String> categories = Set.from(additionalData?['sessionCategories'] ?? []);
        return categories.length;
      case 'comeback_kid':
        int daysSinceLastSession = additionalData?['daysSinceLastSession'] ?? 0;
        return daysSinceLastSession >= 7 ? 1 : 0;
      default:
        return achievement.currentValue;
    }
  }

  void _notifyNewAchievements(List<Achievement> newAchievements) {
    // This would trigger notifications or achievement popups
    for (final achievement in newAchievements) {
      debugPrint('🏆 Achievement Unlocked: ${achievement.name}');
      // TODO: Implement achievement notification UI
    }
  }

  Future<void> _saveAchievements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Save to local storage
      await _storage.setAchievements(
        _userAchievements.map((a) => a.toJson()).toList(),
      );

      // Save to Firestore if user is logged in
      if (user != null) {
        try {
          await _firestore
              .collection('user_achievements')
              .doc(user.uid)
              .set({
            'achievements': _userAchievements.map((a) => a.toJson()).toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Firestore save error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }

  Achievement? getAchievementById(String id) {
    try {
      return _userAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Achievement> getAchievementsByType(AchievementType type) {
    return _userAchievements.where((a) => a.type == type).toList();
  }

  List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return _userAchievements.where((a) => a.rarity == rarity).toList();
  }

  Map<AchievementRarity, List<Achievement>> getAchievementsByRarityMap() {
    Map<AchievementRarity, List<Achievement>> rarityMap = {};
    
    for (final rarity in AchievementRarity.values) {
      rarityMap[rarity] = getAchievementsByRarity(rarity);
    }
    
    return rarityMap;
  }

  // Get achievements that are close to being unlocked (80%+ progress)
  List<Achievement> getNearlyCompleteAchievements() {
    return _userAchievements
        .where((a) => !a.isUnlocked && a.progress >= 0.8)
        .toList();
  }

  Future<void> resetAchievements() async {
    _initializeUserAchievements();
    await _saveAchievements();
    notifyListeners();
  }

  // Method to manually unlock achievement (for testing)
  Future<void> unlockAchievement(String achievementId) async {
    final index = _userAchievements.indexWhere((a) => a.id == achievementId);
    if (index != -1) {
      _userAchievements[index] = _userAchievements[index].copyWith(
        currentValue: _userAchievements[index].targetValue,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await _saveAchievements();
      notifyListeners();
    }
  }
}