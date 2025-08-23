import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 0)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime? endTime;

  @HiveField(3)
  final int duration; // in minutes

  @HiveField(4)
  final SessionType type;

  @HiveField(5)
  final bool completed;

  @HiveField(6)
  final String? taskId;

  PomodoroSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.type,
    required this.completed,
    this.taskId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'duration': duration,
    'type': type.name,
    'completed': completed,
    'taskId': taskId,
  };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'],
      type: SessionType.values.firstWhere((e) => e.name == json['type']),
      completed: json['completed'],
      taskId: json['taskId'],
    );
  }
}

@HiveType(typeId: 1)
enum SessionType {
  @HiveField(0)
  work,
  @HiveField(1)
  shortBreak,
  @HiveField(2)
  longBreak,
}
