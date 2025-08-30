import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus_analytics_service.dart';
import 'focus_mode_manager.dart';

/// Focus Gamification Service
/// Adds game-like elements to motivate users and make focus sessions engaging
class FocusGamificationService {
  static final FocusGamificationService _instance = FocusGamificationService._internal();
  factory FocusGamificationService() => _instance;
  FocusGamificationService._internal();

  static const String _levelKey = 'focus_level';
  static const String _xpKey = 'focus_xp';
  static const String _badgesKey = 'focus_badges';
  static const String _challengesKey = 'focus_challenges';
  static const String _avatarKey = 'focus_avatar';
  static const String _rewardsKey = 'focus_rewards';

  // Player progress
  int _level = 1;
  int _experience = 0;
  List<FocusBadge> _earnedBadges = [];
  List<FocusChallenge> _activeChallenges = [];
  FocusAvatar _avatar = FocusAvatar.defaultAvatar();
  List<FocusReward> _availableRewards = [];

  // Controllers
  final StreamController<LevelUpEvent> _levelUpController = 
      StreamController<LevelUpEvent>.broadcast();
  final StreamController<FocusBadge> _badgeController = 
      StreamController<FocusBadge>.broadcast();
  final StreamController<FocusChallenge> _challengeController = 
      StreamController<FocusChallenge>.broadcast();

  // Getters
  int get level => _level;
  int get experience => _experience;
  int get experienceToNextLevel => _getExperienceForLevel(_level + 1) - _experience;
  double get levelProgress => (_experience - _getExperienceForLevel(_level)) / 
                             (_getExperienceForLevel(_level + 1) - _getExperienceForLevel(_level));
  List<FocusBadge> get earnedBadges => List.unmodifiable(_earnedBadges);
  List<FocusChallenge> get activeChallenges => List.unmodifiable(_activeChallenges);
  FocusAvatar get avatar => _avatar;
  List<FocusReward> get availableRewards => List.unmodifiable(_availableRewards);

  Stream<LevelUpEvent> get levelUpStream => _levelUpController.stream;
  Stream<FocusBadge> get badgeStream => _badgeController.stream;
  Stream<FocusChallenge> get challengeStream => _challengeController.stream;

  /// Initialize the gamification service
  Future<void> initialize() async {
    await _loadProgress();
    await _initializeChallenges();
    await _initializeRewards();
    
    if (kDebugMode) {
      print('🎮 Focus Gamification Service initialized');
      print('   Level: $_level (XP: $_experience)');
      print('   Badges: ${_earnedBadges.length}');
      print('   Active Challenges: ${_activeChallenges.length}');
    }
  }

  /// Award experience points for focus actions
  Future<void> awardExperience(FocusAction action, {int? customAmount}) async {
    final baseXP = customAmount ?? _getBaseExperience(action);
    final multiplier = _getExperienceMultiplier();
    final totalXP = (baseXP * multiplier).round();

    final oldLevel = _level;
    _experience += totalXP;
    
    // Check for level up
    while (_experience >= _getExperienceForLevel(_level + 1)) {
      _level++;
    }

    if (_level > oldLevel) {
      await _handleLevelUp(oldLevel, _level);
    }

    await _saveProgress();
    await _checkBadgeProgress(action);
    await _updateChallengeProgress(action);

    if (kDebugMode) {
      print('🎮 Awarded ${totalXP}XP for ${action.toString()}');
      if (_level > oldLevel) print('🎉 Level up! Now level $_level');
    }
  }

  /// Complete a focus session and award appropriate rewards
  Future<void> completeSession(FocusSession session) async {
    final duration = session.actualDuration?.inMinutes ?? 0;
    final focusScore = session.focusScore ?? 0.0;
    
    // Base XP for completing session
    await awardExperience(FocusAction.completeSession);
    
    // Bonus XP for duration
    if (duration >= 25) await awardExperience(FocusAction.longSession);
    if (duration >= 50) await awardExperience(FocusAction.extraLongSession);
    
    // Bonus XP for high focus score
    if (focusScore >= 0.8) await awardExperience(FocusAction.highFocus);
    if (focusScore >= 0.95) await awardExperience(FocusAction.perfectFocus);
    
    // Bonus XP for few distractions
    if (session.distractions.length <= 1) {
      await awardExperience(FocusAction.lowDistractions);
    }

    // Check session-specific achievements
    await _checkSessionAchievements(session);
  }

  /// Handle distraction events
  Future<void> handleDistraction(FocusDistraction distraction) async {
    // Lose small amount of XP for distractions (but never go below 0)
    final penalty = (distraction.severity * 5).round();
    _experience = max(0, _experience - penalty);
    
    await _saveProgress();
    
    if (kDebugMode) print('📱 Distraction penalty: -${penalty}XP');
  }

  /// Get all available badges and their progress
  List<FocusBadgeProgress> getBadgeProgress() {
    final allBadges = _getAllPossibleBadges();
    final progress = <FocusBadgeProgress>[];

    for (final badge in allBadges) {
      final isEarned = _earnedBadges.any((b) => b.id == badge.id);
      final currentProgress = _calculateBadgeProgress(badge);
      
      progress.add(FocusBadgeProgress(
        badge: badge,
        isEarned: isEarned,
        progress: currentProgress,
        maxProgress: badge.requirement,
      ));
    }

    return progress;
  }

  /// Unlock avatar customization item
  Future<void> unlockAvatarItem(String itemId) async {
    if (_level >= _getRequiredLevelForItem(itemId)) {
      _avatar = _avatar.copyWithUnlockedItem(itemId);
      await _saveProgress();
    }
  }

  /// Use a focus reward
  Future<bool> useReward(String rewardId) async {
    final reward = _availableRewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => FocusReward.empty(),
    );

    if (reward.id.isEmpty || reward.cost > _experience) {
      return false;
    }

    _experience -= reward.cost;
    reward.quantity = max(0, reward.quantity - 1);
    
    if (reward.quantity == 0) {
      _availableRewards.removeWhere((r) => r.id == rewardId);
    }

    await _saveProgress();
    
    if (kDebugMode) print('🎁 Used reward: ${reward.name} (-${reward.cost}XP)');
    return true;
  }

  /// Generate daily challenges
  Future<void> generateDailyChallenges() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // Remove expired challenges
    _activeChallenges.removeWhere((c) => c.expiresAt.isBefore(today));
    
    // Check if we need new challenges for today
    final hasActiveChallenge = _activeChallenges.any((c) => 
        c.createdAt.isAfter(todayStart));
    
    if (!hasActiveChallenge) {
      final newChallenges = _createDailyChallenges();
      _activeChallenges.addAll(newChallenges);
      
      for (final challenge in newChallenges) {
        _challengeController.add(challenge);
      }
      
      await _saveProgress();
    }
  }

  // Private methods

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    _level = prefs.getInt(_levelKey) ?? 1;
    _experience = prefs.getInt(_xpKey) ?? 0;
    
    final badgesJson = prefs.getString(_badgesKey);
    if (badgesJson != null) {
      final List<dynamic> badgesList = jsonDecode(badgesJson);
      _earnedBadges = badgesList.map((json) => FocusBadge.fromMap(json)).toList();
    }
    
    final challengesJson = prefs.getString(_challengesKey);
    if (challengesJson != null) {
      final List<dynamic> challengesList = jsonDecode(challengesJson);
      _activeChallenges = challengesList.map((json) => FocusChallenge.fromMap(json)).toList();
    }
    
    final avatarJson = prefs.getString(_avatarKey);
    if (avatarJson != null) {
      _avatar = FocusAvatar.fromMap(jsonDecode(avatarJson));
    }
    
    final rewardsJson = prefs.getString(_rewardsKey);
    if (rewardsJson != null) {
      final List<dynamic> rewardsList = jsonDecode(rewardsJson);
      _availableRewards = rewardsList.map((json) => FocusReward.fromMap(json)).toList();
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_levelKey, _level);
    await prefs.setInt(_xpKey, _experience);
    await prefs.setString(_badgesKey, jsonEncode(_earnedBadges.map((b) => b.toMap()).toList()));
    await prefs.setString(_challengesKey, jsonEncode(_activeChallenges.map((c) => c.toMap()).toList()));
    await prefs.setString(_avatarKey, jsonEncode(_avatar.toMap()));
    await prefs.setString(_rewardsKey, jsonEncode(_availableRewards.map((r) => r.toMap()).toList()));
  }

  int _getExperienceForLevel(int level) {
    // Exponential XP curve: Level n requires n^2 * 100 total XP
    return level * level * 100;
  }

  int _getBaseExperience(FocusAction action) {
    switch (action) {
      case FocusAction.startSession:
        return 10;
      case FocusAction.completeSession:
        return 50;
      case FocusAction.longSession:
        return 25;
      case FocusAction.extraLongSession:
        return 50;
      case FocusAction.highFocus:
        return 30;
      case FocusAction.perfectFocus:
        return 100;
      case FocusAction.lowDistractions:
        return 20;
      case FocusAction.streakDay:
        return 15;
      case FocusAction.challengeComplete:
        return 75;
      case FocusAction.badgeEarned:
        return 25;
    }
  }

  double _getExperienceMultiplier() {
    // Slight bonus for higher levels
    return 1.0 + (_level * 0.05);
  }

  Future<void> _handleLevelUp(int oldLevel, int newLevel) async {
    final levelUpEvent = LevelUpEvent(
      oldLevel: oldLevel,
      newLevel: newLevel,
      rewardsUnlocked: _getRewardsForLevel(newLevel),
      featuresUnlocked: _getFeaturesForLevel(newLevel),
    );

    _levelUpController.add(levelUpEvent);
    
    // Add level-based rewards
    _availableRewards.addAll(levelUpEvent.rewardsUnlocked);
    
    if (kDebugMode) {
      print('🎉 Level up! $oldLevel → $newLevel');
      print('   New rewards: ${levelUpEvent.rewardsUnlocked.length}');
      print('   New features: ${levelUpEvent.featuresUnlocked.length}');
    }
  }

  List<FocusReward> _getRewardsForLevel(int level) {
    final rewards = <FocusReward>[];
    
    switch (level) {
      case 3:
        rewards.add(FocusReward(
          id: 'break_extension',
          name: '5-Minute Break Extension',
          description: 'Extend your break by 5 minutes',
          type: RewardType.breakExtension,
          cost: 100,
          quantity: 3,
        ));
        break;
      case 5:
        rewards.add(FocusReward(
          id: 'ambient_unlock',
          name: 'Premium Ambient Sounds',
          description: 'Unlock coffee shop and library sounds',
          type: RewardType.featureUnlock,
          cost: 200,
          quantity: 1,
        ));
        break;
      case 10:
        rewards.add(FocusReward(
          id: 'streak_protection',
          name: 'Streak Protection',
          description: 'Protect your streak from one missed day',
          type: RewardType.streakProtection,
          cost: 500,
          quantity: 1,
        ));
        break;
    }
    
    return rewards;
  }

  List<String> _getFeaturesForLevel(int level) {
    switch (level) {
      case 2:
        return ['Focus Analytics Dashboard'];
      case 3:
        return ['Custom Session Durations'];
      case 5:
        return ['Premium Ambient Sounds', 'Session History Export'];
      case 7:
        return ['Advanced App Blocking'];
      case 10:
        return ['AI Focus Insights', 'Streak Protection'];
      case 15:
        return ['Custom Avatar Accessories'];
      case 20:
        return ['Master Focus Mode', 'Unlimited Session Types'];
      default:
        return [];
    }
  }

  Future<void> _checkBadgeProgress(FocusAction action) async {
    final newBadges = <FocusBadge>[];
    
    // Get analytics data
    final analytics = FocusAnalyticsService();
    final sessions = analytics.focusSessions;
    final streak = analytics.currentStreak;

    // Session count badges
    if (sessions.length == 1 && !_hasBadge('first_session')) {
      newBadges.add(_createBadge('first_session', 'First Focus', 'Complete your first focus session', '🎯'));
    }
    if (sessions.length == 10 && !_hasBadge('ten_sessions')) {
      newBadges.add(_createBadge('ten_sessions', 'Getting Focused', 'Complete 10 focus sessions', '🔟'));
    }
    if (sessions.length == 50 && !_hasBadge('fifty_sessions')) {
      newBadges.add(_createBadge('fifty_sessions', 'Focus Warrior', 'Complete 50 focus sessions', '⚔️'));
    }
    if (sessions.length == 100 && !_hasBadge('hundred_sessions')) {
      newBadges.add(_createBadge('hundred_sessions', 'Focus Master', 'Complete 100 focus sessions', '🏆'));
    }

    // Streak badges
    if (streak.days == 3 && !_hasBadge('three_day_streak')) {
      newBadges.add(_createBadge('three_day_streak', 'Consistency', 'Maintain a 3-day focus streak', '🔥'));
    }
    if (streak.days == 7 && !_hasBadge('week_streak')) {
      newBadges.add(_createBadge('week_streak', 'Dedicated', 'Maintain a 7-day focus streak', '📅'));
    }
    if (streak.days == 30 && !_hasBadge('month_streak')) {
      newBadges.add(_createBadge('month_streak', 'Unstoppable', 'Maintain a 30-day focus streak', '💪'));
    }

    // Special achievement badges
    final todaysSessions = sessions.where((s) => 
        s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    
    if (todaysSessions.length >= 8 && !_hasBadge('marathon_day')) {
      newBadges.add(_createBadge('marathon_day', 'Marathon Day', 'Complete 8+ sessions in one day', '🏃‍♂️'));
    }

    // Focus score badges
    final perfectSessions = sessions.where((s) => (s.focusScore ?? 0.0) >= 0.95).length;
    if (perfectSessions >= 5 && !_hasBadge('perfectionist')) {
      newBadges.add(_createBadge('perfectionist', 'Perfectionist', 'Achieve 95%+ focus score 5 times', '⭐'));
    }

    // Award new badges
    for (final badge in newBadges) {
      _earnedBadges.add(badge);
      _badgeController.add(badge);
      await awardExperience(FocusAction.badgeEarned);
    }

    if (newBadges.isNotEmpty) {
      await _saveProgress();
    }
  }

  Future<void> _updateChallengeProgress(FocusAction action) async {
    bool challengeCompleted = false;
    
    for (final challenge in _activeChallenges) {
      if (challenge.isCompleted) continue;
      
      bool progressMade = false;
      
      switch (challenge.type) {
        case ChallengeType.sessionCount:
          if (action == FocusAction.completeSession) {
            challenge.currentProgress++;
            progressMade = true;
          }
          break;
        case ChallengeType.totalTime:
          if (action == FocusAction.completeSession) {
            final session = FocusAnalyticsService().currentSession;
            if (session?.actualDuration != null) {
              challenge.currentProgress += session!.actualDuration!.inMinutes;
              progressMade = true;
            }
          }
          break;
        case ChallengeType.perfectSessions:
          if (action == FocusAction.perfectFocus) {
            challenge.currentProgress++;
            progressMade = true;
          }
          break;
        case ChallengeType.streakDays:
          final streak = FocusAnalyticsService().currentStreak;
          challenge.currentProgress = streak.days;
          progressMade = true;
          break;
      }

      if (progressMade && challenge.currentProgress >= challenge.targetProgress) {
        challenge.isCompleted = true;
        challengeCompleted = true;
        await awardExperience(FocusAction.challengeComplete);
        
        // Award challenge completion bonus
        _experience += challenge.bonusXP;
        
        _challengeController.add(challenge);
        
        if (kDebugMode) print('✅ Challenge completed: ${challenge.name}');
      }
    }

    if (challengeCompleted) {
      await _saveProgress();
    }
  }

  bool _hasBadge(String badgeId) {
    return _earnedBadges.any((badge) => badge.id == badgeId);
  }

  FocusBadge _createBadge(String id, String name, String description, String icon) {
    return FocusBadge(
      id: id,
      name: name,
      description: description,
      icon: icon,
      earnedAt: DateTime.now(),
      rarity: BadgeRarity.common,
    );
  }

  List<FocusBadge> _getAllPossibleBadges() {
    return [
      FocusBadge(id: 'first_session', name: 'First Focus', description: 'Complete your first focus session', icon: '🎯', earnedAt: null, rarity: BadgeRarity.common),
      FocusBadge(id: 'ten_sessions', name: 'Getting Focused', description: 'Complete 10 focus sessions', icon: '🔟', earnedAt: null, rarity: BadgeRarity.common),
      FocusBadge(id: 'fifty_sessions', name: 'Focus Warrior', description: 'Complete 50 focus sessions', icon: '⚔️', earnedAt: null, rarity: BadgeRarity.rare),
      FocusBadge(id: 'hundred_sessions', name: 'Focus Master', description: 'Complete 100 focus sessions', icon: '🏆', earnedAt: null, rarity: BadgeRarity.epic),
      FocusBadge(id: 'three_day_streak', name: 'Consistency', description: 'Maintain a 3-day focus streak', icon: '🔥', earnedAt: null, rarity: BadgeRarity.common),
      FocusBadge(id: 'week_streak', name: 'Dedicated', description: 'Maintain a 7-day focus streak', icon: '📅', earnedAt: null, rarity: BadgeRarity.uncommon),
      FocusBadge(id: 'month_streak', name: 'Unstoppable', description: 'Maintain a 30-day focus streak', icon: '💪', earnedAt: null, rarity: BadgeRarity.legendary),
      FocusBadge(id: 'marathon_day', name: 'Marathon Day', description: 'Complete 8+ sessions in one day', icon: '🏃‍♂️', earnedAt: null, rarity: BadgeRarity.rare),
      FocusBadge(id: 'perfectionist', name: 'Perfectionist', description: 'Achieve 95%+ focus score 5 times', icon: '⭐', earnedAt: null, rarity: BadgeRarity.epic),
    ];
  }

  int _calculateBadgeProgress(FocusBadge badge) {
    final analytics = FocusAnalyticsService();
    final sessions = analytics.focusSessions;
    final streak = analytics.currentStreak;
    
    switch (badge.id) {
      case 'first_session':
        return sessions.isNotEmpty ? 1 : 0;
      case 'ten_sessions':
        return min(sessions.length, 10);
      case 'fifty_sessions':
        return min(sessions.length, 50);
      case 'hundred_sessions':
        return min(sessions.length, 100);
      case 'three_day_streak':
        return min(streak.days, 3);
      case 'week_streak':
        return min(streak.days, 7);
      case 'month_streak':
        return min(streak.days, 30);
      case 'marathon_day':
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todaysSessions = sessions.where((s) => s.startTime.isAfter(todayStart)).length;
        return min(todaysSessions, 8);
      case 'perfectionist':
        final perfectSessions = sessions.where((s) => (s.focusScore ?? 0.0) >= 0.95).length;
        return min(perfectSessions, 5);
      default:
        return 0;
    }
  }

  Future<void> _checkSessionAchievements(FocusSession session) async {
    // Check for time-based achievements
    final duration = session.actualDuration?.inMinutes ?? 0;
    
    if (duration >= 120 && !_hasBadge('marathon_session')) {
      final badge = _createBadge('marathon_session', 'Marathon Session', 'Complete a 2+ hour focus session', '🏃‍♀️');
      _earnedBadges.add(badge);
      _badgeController.add(badge);
      await awardExperience(FocusAction.badgeEarned);
    }
    
    // Check for distraction resistance
    if (session.distractions.isEmpty && duration >= 25 && !_hasBadge('distraction_free')) {
      final badge = _createBadge('distraction_free', 'Zen Master', 'Complete a session with zero distractions', '🧘‍♂️');
      _earnedBadges.add(badge);
      _badgeController.add(badge);
      await awardExperience(FocusAction.badgeEarned);
    }
  }

  Future<void> _initializeChallenges() async {
    if (_activeChallenges.isEmpty) {
      await generateDailyChallenges();
    }
  }

  List<FocusChallenge> _createDailyChallenges() {
    final challenges = <FocusChallenge>[];
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    
    // Random selection of 2-3 daily challenges
    final possibleChallenges = [
      FocusChallenge(
        id: 'daily_sessions_${today.day}',
        name: 'Daily Focus',
        description: 'Complete 3 focus sessions today',
        type: ChallengeType.sessionCount,
        targetProgress: 3,
        currentProgress: 0,
        bonusXP: 100,
        createdAt: today,
        expiresAt: tomorrow,
      ),
      FocusChallenge(
        id: 'daily_time_${today.day}',
        name: 'Time Master',
        description: 'Focus for 90 minutes total today',
        type: ChallengeType.totalTime,
        targetProgress: 90,
        currentProgress: 0,
        bonusXP: 150,
        createdAt: today,
        expiresAt: tomorrow,
      ),
      FocusChallenge(
        id: 'perfect_focus_${today.day}',
        name: 'Perfect Focus',
        description: 'Achieve 90%+ focus score in a session',
        type: ChallengeType.perfectSessions,
        targetProgress: 1,
        currentProgress: 0,
        bonusXP: 200,
        createdAt: today,
        expiresAt: tomorrow,
      ),
    ];

    // Randomly select 2 challenges
    possibleChallenges.shuffle();
    challenges.addAll(possibleChallenges.take(2));
    
    return challenges;
  }

  Future<void> _initializeRewards() async {
    if (_availableRewards.isEmpty) {
      // Add starter rewards based on current level
      _availableRewards.addAll(_getRewardsForLevel(_level));
    }
  }

  int _getRequiredLevelForItem(String itemId) {
    // Avatar customization level requirements
    final levelRequirements = {
      'hat_cap': 5,
      'hat_beanie': 8,
      'glasses_round': 3,
      'glasses_square': 6,
      'background_forest': 10,
      'background_space': 15,
      'pet_cat': 12,
      'pet_dog': 12,
      'accessory_coffee': 7,
    };
    
    return levelRequirements[itemId] ?? 999;
  }

  /// Dispose resources
  void dispose() {
    _levelUpController.close();
    _badgeController.close();
    _challengeController.close();
  }
}

// Gamification data classes

enum FocusAction {
  startSession,
  completeSession,
  longSession,
  extraLongSession,
  highFocus,
  perfectFocus,
  lowDistractions,
  streakDay,
  challengeComplete,
  badgeEarned,
}

class LevelUpEvent {
  final int oldLevel;
  final int newLevel;
  final List<FocusReward> rewardsUnlocked;
  final List<String> featuresUnlocked;

  LevelUpEvent({
    required this.oldLevel,
    required this.newLevel,
    required this.rewardsUnlocked,
    required this.featuresUnlocked,
  });
}

class FocusBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime? earnedAt;
  final BadgeRarity rarity;
  final int requirement;

  FocusBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.earnedAt,
    required this.rarity,
    this.requirement = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'earnedAt': earnedAt?.millisecondsSinceEpoch,
      'rarity': rarity.index,
      'requirement': requirement,
    };
  }

  factory FocusBadge.fromMap(Map<String, dynamic> map) {
    return FocusBadge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      earnedAt: map['earnedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['earnedAt']) : null,
      rarity: BadgeRarity.values[map['rarity'] ?? 0],
      requirement: map['requirement'] ?? 1,
    );
  }
}

enum BadgeRarity { common, uncommon, rare, epic, legendary }

class FocusBadgeProgress {
  final FocusBadge badge;
  final bool isEarned;
  final int progress;
  final int maxProgress;

  FocusBadgeProgress({
    required this.badge,
    required this.isEarned,
    required this.progress,
    required this.maxProgress,
  });

  double get progressPercentage => maxProgress > 0 ? progress / maxProgress : 0.0;
}

class FocusChallenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final int targetProgress;
  int currentProgress;
  final int bonusXP;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool isCompleted;

  FocusChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetProgress,
    this.currentProgress = 0,
    required this.bonusXP,
    required this.createdAt,
    required this.expiresAt,
    this.isCompleted = false,
  });

  double get progressPercentage => targetProgress > 0 ? currentProgress / targetProgress : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'targetProgress': targetProgress,
      'currentProgress': currentProgress,
      'bonusXP': bonusXP,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  factory FocusChallenge.fromMap(Map<String, dynamic> map) {
    return FocusChallenge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: ChallengeType.values[map['type'] ?? 0],
      targetProgress: map['targetProgress'] ?? 0,
      currentProgress: map['currentProgress'] ?? 0,
      bonusXP: map['bonusXP'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] ?? 0),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

enum ChallengeType { sessionCount, totalTime, perfectSessions, streakDays }

class FocusReward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final int cost;
  int quantity;

  FocusReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.quantity,
  });

  FocusReward.empty() : 
    id = '',
    name = '',
    description = '',
    type = RewardType.featureUnlock,
    cost = 0,
    quantity = 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'cost': cost,
      'quantity': quantity,
    };
  }

  factory FocusReward.fromMap(Map<String, dynamic> map) {
    return FocusReward(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: RewardType.values[map['type'] ?? 0],
      cost: map['cost'] ?? 0,
      quantity: map['quantity'] ?? 0,
    );
  }
}

enum RewardType { breakExtension, featureUnlock, streakProtection, avatarItem }

class FocusAvatar {
  final String hat;
  final String glasses;
  final String background;
  final String pet;
  final String accessory;
  final List<String> unlockedItems;

  FocusAvatar({
    required this.hat,
    required this.glasses,
    required this.background,
    required this.pet,
    required this.accessory,
    required this.unlockedItems,
  });

  FocusAvatar.defaultAvatar() : 
    hat = 'none',
    glasses = 'none',
    background = 'default',
    pet = 'none',
    accessory = 'none',
    unlockedItems = ['default'];

  FocusAvatar copyWithUnlockedItem(String itemId) {
    final newUnlocked = List<String>.from(unlockedItems);
    if (!newUnlocked.contains(itemId)) {
      newUnlocked.add(itemId);
    }
    
    return FocusAvatar(
      hat: hat,
      glasses: glasses,
      background: background,
      pet: pet,
      accessory: accessory,
      unlockedItems: newUnlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hat': hat,
      'glasses': glasses,
      'background': background,
      'pet': pet,
      'accessory': accessory,
      'unlockedItems': unlockedItems,
    };
  }

  factory FocusAvatar.fromMap(Map<String, dynamic> map) {
    return FocusAvatar(
      hat: map['hat'] ?? 'none',
      glasses: map['glasses'] ?? 'none',
      background: map['background'] ?? 'default',
      pet: map['pet'] ?? 'none',
      accessory: map['accessory'] ?? 'none',
      unlockedItems: List<String>.from(map['unlockedItems'] ?? ['default']),
    );
  }
}