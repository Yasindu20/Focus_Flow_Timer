// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'productivity_score.dart';

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

ProductivityScore _$ProductivityScoreFromJson(Map<String, dynamic> json) =>
    ProductivityScore(
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      dailyScore: (json['dailyScore'] as num).toDouble(),
      weeklyScore: (json['weeklyScore'] as num).toDouble(),
      monthlyScore: (json['monthlyScore'] as num).toDouble(),
      metrics: ProductivityMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>),
      categoryScores: Map<String, double>.from(json['categoryScores']),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      details:
          ScoreDetails.fromJson(json['details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductivityScoreToJson(ProductivityScore instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'date': instance.date.toIso8601String(),
      'dailyScore': instance.dailyScore,
      'weeklyScore': instance.weeklyScore,
      'monthlyScore': instance.monthlyScore,
      'metrics': instance.metrics,
      'categoryScores': instance.categoryScores,
      'rank': instance.rank,
      'details': instance.details,
    };

ProductivityMetrics _$ProductivityMetricsFromJson(
        Map<String, dynamic> json) =>
    ProductivityMetrics(
      totalSessions: (json['totalSessions'] as num).toInt(),
      completedSessions: (json['completedSessions'] as num).toInt(),
      totalFocusMinutes: (json['totalFocusMinutes'] as num).toInt(),
      tasksCompleted: (json['tasksCompleted'] as num).toInt(),
      perfectSessions: (json['perfectSessions'] as num).toInt(),
      averageSessionLength: (json['averageSessionLength'] as num).toDouble(),
      consistencyScore: (json['consistencyScore'] as num).toDouble(),
      efficiencyScore: (json['efficiencyScore'] as num).toDouble(),
      streakDays: (json['streakDays'] as num).toInt(),
      interruptionCount: (json['interruptionCount'] as num).toInt(),
    );

Map<String, dynamic> _$ProductivityMetricsToJson(
        ProductivityMetrics instance) =>
    <String, dynamic>{
      'totalSessions': instance.totalSessions,
      'completedSessions': instance.completedSessions,
      'totalFocusMinutes': instance.totalFocusMinutes,
      'tasksCompleted': instance.tasksCompleted,
      'perfectSessions': instance.perfectSessions,
      'averageSessionLength': instance.averageSessionLength,
      'consistencyScore': instance.consistencyScore,
      'efficiencyScore': instance.efficiencyScore,
      'streakDays': instance.streakDays,
      'interruptionCount': instance.interruptionCount,
    };

ScoreDetails _$ScoreDetailsFromJson(Map<String, dynamic> json) => ScoreDetails(
      baseScore: (json['baseScore'] as num).toDouble(),
      consistencyBonus: (json['consistencyBonus'] as num).toDouble(),
      streakBonus: (json['streakBonus'] as num).toDouble(),
      efficiencyBonus: (json['efficiencyBonus'] as num).toDouble(),
      taskCompletionBonus: (json['taskCompletionBonus'] as num).toDouble(),
      perfectSessionBonus: (json['perfectSessionBonus'] as num).toDouble(),
      penaltyReduction: (json['penaltyReduction'] as num).toDouble(),
      components: (json['components'] as List<dynamic>)
          .map((e) => ScoreComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScoreDetailsToJson(ScoreDetails instance) =>
    <String, dynamic>{
      'baseScore': instance.baseScore,
      'consistencyBonus': instance.consistencyBonus,
      'streakBonus': instance.streakBonus,
      'efficiencyBonus': instance.efficiencyBonus,
      'taskCompletionBonus': instance.taskCompletionBonus,
      'perfectSessionBonus': instance.perfectSessionBonus,
      'penaltyReduction': instance.penaltyReduction,
      'components': instance.components,
    };

ScoreComponent _$ScoreComponentFromJson(Map<String, dynamic> json) =>
    ScoreComponent(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      description: json['description'] as String,
      type: $enumDecode(_$ComponentTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$ScoreComponentToJson(ScoreComponent instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
      'description': instance.description,
      'type': _$ComponentTypeEnumMap[instance.type]!,
    };

const _$ComponentTypeEnumMap = {
  ComponentType.base: 'base',
  ComponentType.bonus: 'bonus',
  ComponentType.penalty: 'penalty',
};