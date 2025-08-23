import 'package:hive/hive.dart';

part 'daily_stats.g.dart';

@HiveType(typeId: 4)
class DailyStats extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  int completedSessions;

  @HiveField(2)
  int totalMinutes;

  @HiveField(3)
  int tasksCompleted;

  @HiveField(4)
  double focusScore;

  DailyStats({
    required this.date,
    this.completedSessions = 0,
    this.totalMinutes = 0,
    this.tasksCompleted = 0,
    this.focusScore = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'completedSessions': completedSessions,
    'totalMinutes': totalMinutes,
    'tasksCompleted': tasksCompleted,
    'focusScore': focusScore,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date']),
      completedSessions: json['completedSessions'] ?? 0,
      totalMinutes: json['totalMinutes'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      focusScore: (json['focusScore'] ?? 0.0).toDouble(),
    );
  }
}
