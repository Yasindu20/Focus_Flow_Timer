import 'package:hive/hive.dart';
import '../services/advanced_timer_service.dart';

part 'timer_session.g.dart';

@HiveType(typeId: 5)
class TimerSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final TimerType type;

  @HiveField(2)
  final int plannedDuration; // in milliseconds

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  DateTime? endTime;

  @HiveField(5)
  bool completed;

  @HiveField(6)
  final String? taskId;

  @HiveField(7)
  int? actualDuration; // in milliseconds

  @HiveField(8)
  int pausedDuration; // total time paused in milliseconds

  @HiveField(9)
  List<DateTime> pauseTimestamps;

  @HiveField(10)
  List<DateTime> resumeTimestamps;

  @HiveField(11)
  Map<String, dynamic> metadata;

  TimerSession({
    required this.id,
    required this.type,
    required this.plannedDuration,
    required this.startTime,
    this.endTime,
    this.completed = false,
    this.taskId,
    this.actualDuration,
    this.pausedDuration = 0,
    List<DateTime>? pauseTimestamps,
    List<DateTime>? resumeTimestamps,
    Map<String, dynamic>? metadata,
  })  : pauseTimestamps = pauseTimestamps ?? [],
        resumeTimestamps = resumeTimestamps ?? [],
        metadata = metadata ?? {};

  bool get isActive => !completed && endTime == null;

  Duration get duration =>
      Duration(milliseconds: actualDuration ?? plannedDuration);

  Duration get elapsedTime {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  double get completionRate {
    if (plannedDuration == 0) return 0.0;
    final elapsed = actualDuration ?? elapsedTime.inMilliseconds;
    return (elapsed / plannedDuration).clamp(0.0, 1.0);
  }

  int get interruptionCount => pauseTimestamps.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'plannedDuration': plannedDuration,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'completed': completed,
        'taskId': taskId,
        'actualDuration': actualDuration,
        'pausedDuration': pausedDuration,
        'pauseTimestamps':
            pauseTimestamps.map((t) => t.toIso8601String()).toList(),
        'resumeTimestamps':
            resumeTimestamps.map((t) => t.toIso8601String()).toList(),
        'metadata': metadata,
      };

  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      id: json['id'],
      type: TimerType.values.firstWhere((t) => t.name == json['type']),
      plannedDuration: json['plannedDuration'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      completed: json['completed'] ?? false,
      taskId: json['taskId'],
      actualDuration: json['actualDuration'],
      pausedDuration: json['pausedDuration'] ?? 0,
      pauseTimestamps: (json['pauseTimestamps'] as List?)
              ?.map((t) => DateTime.parse(t))
              .toList() ??
          [],
      resumeTimestamps: (json['resumeTimestamps'] as List?)
              ?.map((t) => DateTime.parse(t))
              .toList() ??
          [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
