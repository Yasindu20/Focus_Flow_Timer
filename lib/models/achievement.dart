import 'package:json_annotation/json_annotation.dart';

part 'achievement.g.dart';

@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementType type;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementRarity rarity;
  final int points;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.rarity,
    required this.points,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementType? type,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    AchievementRarity? rarity,
    int? points,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
    );
  }

  double get progress => currentValue / targetValue;
  bool get isCompleted => currentValue >= targetValue;
}

@JsonEnum()
enum AchievementType {
  sessionCount,
  totalFocusTime,
  streakDays,
  tasksCompleted,
  perfectSessions,
  earlyBird,
  nightOwl,
  weekendWarrior,
  productivity,
  consistency,
  milestone,
  special
}

@JsonEnum()
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary
}

class AchievementDefinitions {
  static List<Achievement> getAllAchievements() {
    return [
      // Session Count Achievements
      Achievement(
        id: 'first_session',
        name: 'First Focus',
        description: 'Complete your first focus session',
        icon: '🎯',
        type: AchievementType.sessionCount,
        targetValue: 1,
        rarity: AchievementRarity.common,
        points: 10,
      ),
      Achievement(
        id: 'session_10',
        name: 'Getting Started',
        description: 'Complete 10 focus sessions',
        icon: '⚡',
        type: AchievementType.sessionCount,
        targetValue: 10,
        rarity: AchievementRarity.common,
        points: 50,
      ),
      Achievement(
        id: 'session_50',
        name: 'Focus Enthusiast',
        description: 'Complete 50 focus sessions',
        icon: '🔥',
        type: AchievementType.sessionCount,
        targetValue: 50,
        rarity: AchievementRarity.uncommon,
        points: 200,
      ),
      Achievement(
        id: 'session_100',
        name: 'Century Club',
        description: 'Complete 100 focus sessions',
        icon: '💯',
        type: AchievementType.sessionCount,
        targetValue: 100,
        rarity: AchievementRarity.rare,
        points: 500,
      ),
      Achievement(
        id: 'session_500',
        name: 'Focus Master',
        description: 'Complete 500 focus sessions',
        icon: '👑',
        type: AchievementType.sessionCount,
        targetValue: 500,
        rarity: AchievementRarity.epic,
        points: 2000,
      ),

      // Total Focus Time Achievements
      Achievement(
        id: 'focus_1hour',
        name: 'Hour of Power',
        description: 'Focus for a total of 1 hour',
        icon: '⏰',
        type: AchievementType.totalFocusTime,
        targetValue: 60, // minutes
        rarity: AchievementRarity.common,
        points: 25,
      ),
      Achievement(
        id: 'focus_10hours',
        name: 'Deep Diver',
        description: 'Focus for a total of 10 hours',
        icon: '🌊',
        type: AchievementType.totalFocusTime,
        targetValue: 600,
        rarity: AchievementRarity.uncommon,
        points: 150,
      ),
      Achievement(
        id: 'focus_50hours',
        name: 'Time Master',
        description: 'Focus for a total of 50 hours',
        icon: '🕰️',
        type: AchievementType.totalFocusTime,
        targetValue: 3000,
        rarity: AchievementRarity.rare,
        points: 750,
      ),
      Achievement(
        id: 'focus_100hours',
        name: 'Concentration King',
        description: 'Focus for a total of 100 hours',
        icon: '👑',
        type: AchievementType.totalFocusTime,
        targetValue: 6000,
        rarity: AchievementRarity.epic,
        points: 1500,
      ),

      // Streak Achievements
      Achievement(
        id: 'streak_3',
        name: 'Getting Consistent',
        description: 'Maintain a 3-day streak',
        icon: '📈',
        type: AchievementType.streakDays,
        targetValue: 3,
        rarity: AchievementRarity.common,
        points: 30,
      ),
      Achievement(
        id: 'streak_7',
        name: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: '🗓️',
        type: AchievementType.streakDays,
        targetValue: 7,
        rarity: AchievementRarity.uncommon,
        points: 100,
      ),
      Achievement(
        id: 'streak_30',
        name: 'Monthly Master',
        description: 'Maintain a 30-day streak',
        icon: '🏆',
        type: AchievementType.streakDays,
        targetValue: 30,
        rarity: AchievementRarity.rare,
        points: 500,
      ),
      Achievement(
        id: 'streak_100',
        name: 'Centurion',
        description: 'Maintain a 100-day streak',
        icon: '⚔️',
        type: AchievementType.streakDays,
        targetValue: 100,
        rarity: AchievementRarity.epic,
        points: 2000,
      ),

      // Task Completion Achievements
      Achievement(
        id: 'tasks_10',
        name: 'Task Tackler',
        description: 'Complete 10 tasks',
        icon: '✅',
        type: AchievementType.tasksCompleted,
        targetValue: 10,
        rarity: AchievementRarity.common,
        points: 40,
      ),
      Achievement(
        id: 'tasks_50',
        name: 'Productivity Pro',
        description: 'Complete 50 tasks',
        icon: '📋',
        type: AchievementType.tasksCompleted,
        targetValue: 50,
        rarity: AchievementRarity.uncommon,
        points: 150,
      ),
      Achievement(
        id: 'tasks_200',
        name: 'Task Master',
        description: 'Complete 200 tasks',
        icon: '🎯',
        type: AchievementType.tasksCompleted,
        targetValue: 200,
        rarity: AchievementRarity.rare,
        points: 600,
      ),

      // Perfect Session Achievements
      Achievement(
        id: 'perfect_5',
        name: 'Perfectionist',
        description: 'Complete 5 perfect sessions (no interruptions)',
        icon: '💎',
        type: AchievementType.perfectSessions,
        targetValue: 5,
        rarity: AchievementRarity.uncommon,
        points: 100,
      ),
      Achievement(
        id: 'perfect_20',
        name: 'Flawless Focus',
        description: 'Complete 20 perfect sessions',
        icon: '💠',
        type: AchievementType.perfectSessions,
        targetValue: 20,
        rarity: AchievementRarity.rare,
        points: 400,
      ),

      // Time-based Achievements
      Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Complete 10 sessions before 9 AM',
        icon: '🌅',
        type: AchievementType.earlyBird,
        targetValue: 10,
        rarity: AchievementRarity.uncommon,
        points: 120,
      ),
      Achievement(
        id: 'night_owl',
        name: 'Night Owl',
        description: 'Complete 10 sessions after 9 PM',
        icon: '🦉',
        type: AchievementType.nightOwl,
        targetValue: 10,
        rarity: AchievementRarity.uncommon,
        points: 120,
      ),
      Achievement(
        id: 'weekend_warrior',
        name: 'Weekend Warrior',
        description: 'Complete 20 weekend sessions',
        icon: '⚔️',
        type: AchievementType.weekendWarrior,
        targetValue: 20,
        rarity: AchievementRarity.uncommon,
        points: 150,
      ),

      // Productivity Achievements
      Achievement(
        id: 'productive_day',
        name: 'Productive Day',
        description: 'Complete 8+ sessions in a single day',
        icon: '🚀',
        type: AchievementType.productivity,
        targetValue: 1,
        rarity: AchievementRarity.rare,
        points: 300,
      ),
      Achievement(
        id: 'marathon_session',
        name: 'Marathon Runner',
        description: 'Complete a 2-hour focus session',
        icon: '🏃',
        type: AchievementType.milestone,
        targetValue: 120,
        rarity: AchievementRarity.rare,
        points: 400,
      ),

      // Consistency Achievements
      Achievement(
        id: 'consistent_week',
        name: 'Consistent Creator',
        description: 'Complete sessions every day for a week',
        icon: '📊',
        type: AchievementType.consistency,
        targetValue: 7,
        rarity: AchievementRarity.uncommon,
        points: 200,
      ),

      // Special/Milestone Achievements
      Achievement(
        id: 'first_week',
        name: 'Welcome Aboard',
        description: 'Use the app for 7 consecutive days',
        icon: '🎉',
        type: AchievementType.special,
        targetValue: 7,
        rarity: AchievementRarity.common,
        points: 100,
      ),
      Achievement(
        id: 'goal_crusher',
        name: 'Goal Crusher',
        description: 'Achieve 100% productivity score for a week',
        icon: '💥',
        type: AchievementType.productivity,
        targetValue: 100,
        rarity: AchievementRarity.epic,
        points: 1000,
      ),
      Achievement(
        id: 'focus_legend',
        name: 'Focus Legend',
        description: 'Reach 1000+ total focus hours',
        icon: '🌟',
        type: AchievementType.totalFocusTime,
        targetValue: 60000,
        rarity: AchievementRarity.legendary,
        points: 10000,
      ),
      Achievement(
        id: 'zen_master',
        name: 'Zen Master',
        description: 'Complete 50 meditation/break sessions',
        icon: '🧘',
        type: AchievementType.special,
        targetValue: 50,
        rarity: AchievementRarity.rare,
        points: 300,
      ),
      Achievement(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete 10 tasks in under 15 minutes each',
        icon: '⚡',
        type: AchievementType.special,
        targetValue: 10,
        rarity: AchievementRarity.uncommon,
        points: 180,
      ),
      Achievement(
        id: 'diversity_master',
        name: 'Diversity Master',
        description: 'Complete sessions in 5 different categories',
        icon: '🎨',
        type: AchievementType.special,
        targetValue: 5,
        rarity: AchievementRarity.uncommon,
        points: 150,
      ),
      Achievement(
        id: 'comeback_kid',
        name: 'Comeback Kid',
        description: 'Return after 7+ days of inactivity',
        icon: '🔄',
        type: AchievementType.special,
        targetValue: 1,
        rarity: AchievementRarity.uncommon,
        points: 100,
      ),
    ];
  }
}