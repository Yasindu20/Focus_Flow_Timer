import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  int estimatedPomodoros;

  @HiveField(7)
  int completedPomodoros;

  @HiveField(8)
  TaskPriority priority;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.priority = TaskPriority.medium,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'isCompleted': isCompleted,
    'estimatedPomodoros': estimatedPomodoros,
    'completedPomodoros': completedPomodoros,
    'priority': priority.name,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      estimatedPomodoros: json['estimatedPomodoros'] ?? 1,
      completedPomodoros: json['completedPomodoros'] ?? 0,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
    );
  }
}

@HiveType(typeId: 3)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}
