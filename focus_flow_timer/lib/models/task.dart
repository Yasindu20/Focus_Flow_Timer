import 'package:hive/hive.dart';
import 'enhanced_task.dart';

part 'task.g.dart';

/// Legacy Task class - bridges to EnhancedTask for backward compatibility
@HiveType(typeId: 30)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  bool isCompleted;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  DateTime? completedAt;
  
  @HiveField(6)
  int estimatedMinutes;
  
  @HiveField(7)
  int? actualMinutes;
  
  @HiveField(8)
  TaskCategory category;
  
  @HiveField(9)
  TaskPriority priority;
  
  @HiveField(10)
  List<String> tags;
  
  @HiveField(11)
  int completedPomodoros;
  
  @HiveField(12)
  int estimatedPomodoros;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.estimatedMinutes = 25,
    this.actualMinutes,
    this.category = TaskCategory.general,
    this.priority = TaskPriority.medium,
    List<String>? tags,
    this.completedPomodoros = 0,
    int? estimatedPomodoros,
  }) : tags = tags ?? [],
       estimatedPomodoros = estimatedPomodoros ?? ((estimatedMinutes / 25).ceil());

  /// Convert legacy Task to EnhancedTask
  EnhancedTask toEnhancedTask() {
    return EnhancedTask(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      createdAt: createdAt,
      completedAt: completedAt,
      isCompleted: isCompleted,
      estimatedMinutes: estimatedMinutes,
      actualMinutes: actualMinutes,
      tags: tags,
    );
  }

  /// Create Task from EnhancedTask
  factory Task.fromEnhancedTask(EnhancedTask enhanced) {
    return Task(
      id: enhanced.id,
      title: enhanced.title,
      description: enhanced.description,
      category: enhanced.category,
      priority: enhanced.priority,
      createdAt: enhanced.createdAt,
      completedAt: enhanced.completedAt,
      isCompleted: enhanced.isCompleted,
      estimatedMinutes: enhanced.estimatedMinutes,
      actualMinutes: enhanced.actualMinutes,
      tags: enhanced.tags,
      completedPomodoros: enhanced.metrics.pomodoroSessionsCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
        'category': category.name,
        'priority': priority.name,
        'tags': tags,
        'completedPomodoros': completedPomodoros,
        'estimatedPomodoros': estimatedPomodoros,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      estimatedMinutes: json['estimatedMinutes'] ?? 25,
      actualMinutes: json['actualMinutes'],
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.general,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      completedPomodoros: json['completedPomodoros'] ?? 0,
      estimatedPomodoros: json['estimatedPomodoros'],
    );
  }

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    int? estimatedMinutes,
    int? actualMinutes,
    TaskCategory? category,
    TaskPriority? priority,
    List<String>? tags,
    int? completedPomodoros,
    int? estimatedPomodoros,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
    );
  }
}