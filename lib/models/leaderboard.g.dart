// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard.dart';

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

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String?,
      score: (json['score'] as num).toDouble(),
      rank: (json['rank'] as num).toInt(),
      totalFocusMinutes: (json['totalFocusMinutes'] as num).toInt(),
      sessionsCompleted: (json['sessionsCompleted'] as num).toInt(),
      streakDays: (json['streakDays'] as num).toInt(),
      lastActive: DateTime.parse(json['lastActive'] as String),
      stats:
          LeaderboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'avatar': instance.avatar,
      'score': instance.score,
      'rank': instance.rank,
      'totalFocusMinutes': instance.totalFocusMinutes,
      'sessionsCompleted': instance.sessionsCompleted,
      'streakDays': instance.streakDays,
      'lastActive': instance.lastActive.toIso8601String(),
      'stats': instance.stats,
      'achievements': instance.achievements,
    };

LeaderboardStats _$LeaderboardStatsFromJson(Map<String, dynamic> json) =>
    LeaderboardStats(
      weeklyScore: (json['weeklyScore'] as num).toDouble(),
      monthlyScore: (json['monthlyScore'] as num).toDouble(),
      weeklyMinutes: (json['weeklyMinutes'] as num).toInt(),
      monthlyMinutes: (json['monthlyMinutes'] as num).toInt(),
      perfectSessions: (json['perfectSessions'] as num).toInt(),
      averageSessionLength: (json['averageSessionLength'] as num).toDouble(),
      tasksCompleted: (json['tasksCompleted'] as num).toInt(),
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] ?? {}),
    );

Map<String, dynamic> _$LeaderboardStatsToJson(LeaderboardStats instance) =>
    <String, dynamic>{
      'weeklyScore': instance.weeklyScore,
      'monthlyScore': instance.monthlyScore,
      'weeklyMinutes': instance.weeklyMinutes,
      'monthlyMinutes': instance.monthlyMinutes,
      'perfectSessions': instance.perfectSessions,
      'averageSessionLength': instance.averageSessionLength,
      'tasksCompleted': instance.tasksCompleted,
      'categoryBreakdown': instance.categoryBreakdown,
    };

Leaderboard _$LeaderboardFromJson(Map<String, dynamic> json) => Leaderboard(
      type: $enumDecode(_$LeaderboardTypeEnumMap, json['type']),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: $enumDecode(_$LeaderboardPeriodEnumMap, json['period']),
      userEntry: json['userEntry'] == null
          ? null
          : LeaderboardEntry.fromJson(
              json['userEntry'] as Map<String, dynamic>),
      totalParticipants: (json['totalParticipants'] as num).toInt(),
    );

Map<String, dynamic> _$LeaderboardToJson(Leaderboard instance) =>
    <String, dynamic>{
      'type': _$LeaderboardTypeEnumMap[instance.type]!,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'entries': instance.entries,
      'period': _$LeaderboardPeriodEnumMap[instance.period]!,
      'userEntry': instance.userEntry,
      'totalParticipants': instance.totalParticipants,
    };

const _$LeaderboardTypeEnumMap = {
  LeaderboardType.productivity: 'productivity',
  LeaderboardType.focusTime: 'focusTime',
  LeaderboardType.streaks: 'streaks',
  LeaderboardType.sessions: 'sessions',
  LeaderboardType.tasks: 'tasks',
  LeaderboardType.consistency: 'consistency',
};

const _$LeaderboardPeriodEnumMap = {
  LeaderboardPeriod.daily: 'daily',
  LeaderboardPeriod.weekly: 'weekly',
  LeaderboardPeriod.monthly: 'monthly',
  LeaderboardPeriod.allTime: 'allTime',
};