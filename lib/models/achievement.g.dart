// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

T $enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              'Unknown enum value: $source'))
      .key;
}

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      targetValue: (json['targetValue'] as num).toInt(),
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      rarity: $enumDecode(_$AchievementRarityEnumMap, json['rarity']),
      points: (json['points'] as num).toInt(),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'targetValue': instance.targetValue,
      'currentValue': instance.currentValue,
      'isUnlocked': instance.isUnlocked,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'rarity': _$AchievementRarityEnumMap[instance.rarity]!,
      'points': instance.points,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.sessionCount: 'sessionCount',
  AchievementType.totalFocusTime: 'totalFocusTime',
  AchievementType.streakDays: 'streakDays',
  AchievementType.tasksCompleted: 'tasksCompleted',
  AchievementType.perfectSessions: 'perfectSessions',
  AchievementType.earlyBird: 'earlyBird',
  AchievementType.nightOwl: 'nightOwl',
  AchievementType.weekendWarrior: 'weekendWarrior',
  AchievementType.productivity: 'productivity',
  AchievementType.consistency: 'consistency',
  AchievementType.milestone: 'milestone',
  AchievementType.special: 'special',
};

const _$AchievementRarityEnumMap = {
  AchievementRarity.common: 'common',
  AchievementRarity.uncommon: 'uncommon',
  AchievementRarity.rare: 'rare',
  AchievementRarity.epic: 'epic',
  AchievementRarity.legendary: 'legendary',
};