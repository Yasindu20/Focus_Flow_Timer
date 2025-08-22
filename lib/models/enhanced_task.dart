import 'package:hive/hive.dart';
import 'task_analytics.dart';
part 'enhanced_task.g.dart';

@HiveType(typeId: 10)
class EnhancedTask extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  TaskCategory category;
  @HiveField(4)
  TaskPriority priority;
  @HiveField(5)
  DateTime createdAt;
  @HiveField(6)
  DateTime? completedAt;
  @HiveField(7)
  DateTime? dueDate;
  @HiveField(8)
  bool isCompleted;
  @HiveField(9)
  int estimatedMinutes;
  @HiveField(10)
  int? actualMinutes;
  @HiveField(11)
  double? difficultyRating;
  @HiveField(12)
  List<String> tags;
  @HiveField(13)
  List<TaskSubtask> subtasks;
  @HiveField(14)
  List<String> dependencies;
  @HiveField(15)
  TaskStatus status;
  @HiveField(16)
  String? assignedTo;
  @HiveField(17)
  String? projectId;
  @HiveField(18)
  Map<String, dynamic> metadata;
  @HiveField(19)
  TaskProgress progress;
  @HiveField(20)
  List<TaskComment> comments;
  @HiveField(21)
  List<TaskAttachment> attachments;
  @HiveField(22)
  TaskRecurrence? recurrence;
  @HiveField(23)
  TaskAIData aiData;
  @HiveField(24)
  TaskMetrics metrics;
  @HiveField(25)
  List<TaskTimeEntry> timeEntries;
  EnhancedTask({
    required this.id,
    required this.title,
    this.description = '',
    this.category = TaskCategory.general,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
    this.isCompleted = false,
    this.estimatedMinutes = 25,
    this.actualMinutes,
    this.difficultyRating,
    List<String>? tags,
    List<TaskSubtask>? subtasks,
    List<String>? dependencies,
    this.status = TaskStatus.todo,
    this.assignedTo,
    this.projectId,
    Map<String, dynamic>? metadata,
    TaskProgress? progress,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
    this.recurrence,
    TaskAIData? aiData,
    TaskMetrics? metrics,
    List<TaskTimeEntry>? timeEntries,
  })  : tags = tags ?? [],
        subtasks = subtasks ?? [],
        dependencies = dependencies ?? [],
        metadata = metadata ?? {},
        progress = progress ?? TaskProgress(),
        comments = comments ?? [],
        attachments = attachments ?? [],
        aiData = aiData ?? TaskAIData(),
        metrics = metrics ?? TaskMetrics(),
        timeEntries = timeEntries ?? [];
  // Computed properties
  double get completionPercentage {
    if (subtasks.isEmpty) {
      return isCompleted ? 100.0 : progress.percentage;
    }

    final completedSubtasks = subtasks.where((s) => s.isCompleted).length;
    return (completedSubtasks / subtasks.length) * 100;
  }

  Duration get timeSpent {
    return Duration(
      milliseconds: timeEntries
          .map((entry) => entry.duration.inMilliseconds)
          .fold(0, (a, b) => a + b),
    );
  }

  Duration get estimatedDuration => Duration(minutes: estimatedMinutes);
  Duration? get actualDuration {
    if (actualMinutes != null) {
      return Duration(minutes: actualMinutes!);
    }
    return null;
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return dueDate!.isBefore(tomorrow) && dueDate!.isAfter(now);
  }

  TaskUrgency get urgency {
    if (priority == TaskPriority.critical) return TaskUrgency.critical;
    if (isOverdue) return TaskUrgency.critical;
    if (isDueSoon && priority == TaskPriority.high) return TaskUrgency.high;
    if (isDueSoon) return TaskUrgency.medium;

    switch (priority) {
      case TaskPriority.high:
        return TaskUrgency.high;
      case TaskPriority.medium:
        return TaskUrgency.medium;
      case TaskPriority.low:
        return TaskUrgency.low;
      default:
        return TaskUrgency.low;
    }
  }

  // Methods
  void updateProgress(double percentage) {
    progress = progress.copyWith(
      percentage: percentage.clamp(0.0, 100.0),
      lastUpdated: DateTime.now(),
    );
  }

  void addTimeEntry(TaskTimeEntry entry) {
    timeEntries.add(entry);
    metrics = metrics.copyWith(
      totalTimeSpent: timeSpent,
    );
  }

  void addComment(TaskComment comment) {
    comments.add(comment);
  }

  void addSubtask(TaskSubtask subtask) {
    subtasks.add(subtask);
  }

  void completeSubtask(String subtaskId) {
    final index = subtasks.indexWhere((s) => s.id == subtaskId);
    if (index != -1) {
      subtasks[index] = subtasks[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      updateProgress(completionPercentage);
    }
  }

  void complete() {
    isCompleted = true;
    completedAt = DateTime.now();
    status = TaskStatus.done;
    updateProgress(100.0);

    // Complete all subtasks
    for (int i = 0; i < subtasks.length; i++) {
      if (!subtasks[i].isCompleted) {
        subtasks[i] = subtasks[i].copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
      }
    }
  }

  void archive() {
    status = TaskStatus.archived;
  }

  void start() {
    status = TaskStatus.inProgress;
    if (timeEntries.isEmpty) {
      addTimeEntry(TaskTimeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        description: 'Started task',
      ));
    }
  }

  void pause() {
    if (status == TaskStatus.inProgress) {
      status = TaskStatus.paused;

      // End current time entry if any
      if (timeEntries.isNotEmpty) {
        final lastEntry = timeEntries.last;
        if (lastEntry.endTime == null) {
          timeEntries[timeEntries.length - 1] = lastEntry.copyWith(
            endTime: DateTime.now(),
          );
        }
      }
    }
  }

  void resume() {
    if (status == TaskStatus.paused) {
      status = TaskStatus.inProgress;

      // Start new time entry
      addTimeEntry(TaskTimeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        description: 'Resumed task',
      ));
    }
  }

  // Serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
        'difficultyRating': difficultyRating,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'dependencies': dependencies,
        'status': status.name,
        'assignedTo': assignedTo,
        'projectId': projectId,
        'metadata': metadata,
        'progress': progress.toJson(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'recurrence': recurrence?.toJson(),
        'aiData': aiData.toJson(),
        'metrics': metrics.toJson(),
        'timeEntries': timeEntries.map((t) => t.toJson()).toList(),
      };
  factory EnhancedTask.fromJson(Map<String, dynamic> json) {
    return EnhancedTask(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.general,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      estimatedMinutes: json['estimatedMinutes'] ?? 25,
      actualMinutes: json['actualMinutes'],
      difficultyRating: json['difficultyRating']?.toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      subtasks: (json['subtasks'] as List?)
              ?.map((s) => TaskSubtask.fromJson(s))
              .toList() ??
          [],
      dependencies: List<String>.from(json['dependencies'] ?? []),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      assignedTo: json['assignedTo'],
      projectId: json['projectId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      progress: json['progress'] != null
          ? TaskProgress.fromJson(json['progress'])
          : TaskProgress(),
      comments: (json['comments'] as List?)
              ?.map((c) => TaskComment.fromJson(c))
              .toList() ??
          [],
      attachments: (json['attachments'] as List?)
              ?.map((a) => TaskAttachment.fromJson(a))
              .toList() ??
          [],
      recurrence: json['recurrence'] != null
          ? TaskRecurrence.fromJson(json['recurrence'])
          : null,
      aiData: json['aiData'] != null
          ? TaskAIData.fromJson(json['aiData'])
          : TaskAIData(),
      metrics: json['metrics'] != null
          ? TaskMetrics.fromJson(json['metrics'])
          : TaskMetrics(),
      timeEntries: (json['timeEntries'] as List?)
              ?.map((t) => TaskTimeEntry.fromJson(t))
              .toList() ??
          [],
    );
  }
  EnhancedTask copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    int? estimatedMinutes,
    int? actualMinutes,
    double? difficultyRating,
    List<String>? tags,
    List<TaskSubtask>? subtasks,
    List<String>? dependencies,
    TaskStatus? status,
    String? assignedTo,
    String? projectId,
    Map<String, dynamic>? metadata,
    TaskProgress? progress,
    TaskRecurrence? recurrence,
    TaskAIData? aiData,
    TaskMetrics? metrics,
  }) {
    return EnhancedTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      completedAt: completedAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      dependencies: dependencies ?? this.dependencies,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      projectId: projectId ?? this.projectId,
      metadata: metadata ?? this.metadata,
      progress: progress ?? this.progress,
      comments: comments,
      attachments: attachments,
      recurrence: recurrence ?? this.recurrence,
      aiData: aiData ?? this.aiData,
      metrics: metrics ?? this.metrics,
      timeEntries: timeEntries,
    );
  }
}

// Supporting Classes
@HiveType(typeId: 11)
class TaskSubtask extends HiveObject {
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
  TaskSubtask({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.estimatedMinutes = 15,
    this.actualMinutes,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
      };
  factory TaskSubtask.fromJson(Map<String, dynamic> json) {
    return TaskSubtask(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      estimatedMinutes: json['estimatedMinutes'] ?? 15,
      actualMinutes: json['actualMinutes'],
    );
  }
  TaskSubtask copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    int? estimatedMinutes,
    int? actualMinutes,
  }) {
    return TaskSubtask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
    );
  }
}

@HiveType(typeId: 12)
class TaskProgress extends HiveObject {
  @HiveField(0)
  double percentage;
  @HiveField(1)
  DateTime lastUpdated;
  @HiveField(2)
  List<ProgressCheckpoint> checkpoints;
  TaskProgress({
    this.percentage = 0.0,
    DateTime? lastUpdated,
    List<ProgressCheckpoint>? checkpoints,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        checkpoints = checkpoints ?? [];
  Map<String, dynamic> toJson() => {
        'percentage': percentage,
        'lastUpdated': lastUpdated.toIso8601String(),
        'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
      };
  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    return TaskProgress(
      percentage: json['percentage']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      checkpoints: (json['checkpoints'] as List?)
              ?.map((c) => ProgressCheckpoint.fromJson(c))
              .toList() ??
          [],
    );
  }
  TaskProgress copyWith({
    double? percentage,
    DateTime? lastUpdated,
    List<ProgressCheckpoint>? checkpoints,
  }) {
    return TaskProgress(
      percentage: percentage ?? this.percentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }
}

@HiveType(typeId: 13)
class ProgressCheckpoint extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  DateTime timestamp;
  @HiveField(2)
  double percentage;
  @HiveField(3)
  String note;
  ProgressCheckpoint({
    required this.id,
    required this.timestamp,
    required this.percentage,
    this.note = '',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'percentage': percentage,
        'note': note,
      };
  factory ProgressCheckpoint.fromJson(Map<String, dynamic> json) {
    return ProgressCheckpoint(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      percentage: json['percentage']?.toDouble() ?? 0.0,
      note: json['note'] ?? '',
    );
  }
}

@HiveType(typeId: 14)
class TaskComment extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String content;
  @HiveField(2)
  String authorId;
  @HiveField(3)
  DateTime createdAt;
  @HiveField(4)
  DateTime? editedAt;
  TaskComment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.editedAt,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'authorId': authorId,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
      };
  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'],
      content: json['content'],
      authorId: json['authorId'],
      createdAt: DateTime.parse(json['createdAt']),
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }
}

@HiveType(typeId: 15)
class TaskAttachment extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String fileName;
  @HiveField(2)
  String filePath;
  @HiveField(3)
  String mimeType;
  @HiveField(4)
  int fileSize;
  @HiveField(5)
  DateTime uploadedAt;
  @HiveField(6)
  String uploadedBy;
  TaskAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
    required this.uploadedBy,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'uploadedAt': uploadedAt.toIso8601String(),
        'uploadedBy': uploadedBy,
      };
  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      mimeType: json['mimeType'],
      fileSize: json['fileSize'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      uploadedBy: json['uploadedBy'],
    );
  }
}

@HiveType(typeId: 16)
class TaskRecurrence extends HiveObject {
  @HiveField(0)
  RecurrenceType type;
  @HiveField(1)
  int interval;
  @HiveField(2)
  List<int> daysOfWeek;
  @HiveField(3)
  DateTime? endDate;
  @HiveField(4)
  int? maxOccurrences;
  TaskRecurrence({
    required this.type,
    this.interval = 1,
    List<int>? daysOfWeek,
    this.endDate,
    this.maxOccurrences,
  }) : daysOfWeek = daysOfWeek ?? [];
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'interval': interval,
        'daysOfWeek': daysOfWeek,
        'endDate': endDate?.toIso8601String(),
        'maxOccurrences': maxOccurrences,
      };
  factory TaskRecurrence.fromJson(Map<String, dynamic> json) {
    return TaskRecurrence(
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecurrenceType.none,
      ),
      interval: json['interval'] ?? 1,
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'],
    );
  }
}

@HiveType(typeId: 17)
class TaskAIData extends HiveObject {
  @HiveField(0)
  double complexityScore;
  @HiveField(1)
  double confidenceLevel;
  @HiveField(2)
  List<String> suggestedTags;
  @HiveField(3)
  List<String> relatedTaskIds;
  @HiveField(4)
  Map<String, double> categoryProbabilities;
  @HiveField(5)
  List<String> optimizationTips;
  @HiveField(6)
  DateTime? lastAnalyzed;
  TaskAIData({
    this.complexityScore = 0.5,
    this.confidenceLevel = 0.7,
    List<String>? suggestedTags,
    List<String>? relatedTaskIds,
    Map<String, double>? categoryProbabilities,
    List<String>? optimizationTips,
    this.lastAnalyzed,
  })  : suggestedTags = suggestedTags ?? [],
        relatedTaskIds = relatedTaskIds ?? [],
        categoryProbabilities = categoryProbabilities ?? {},
        optimizationTips = optimizationTips ?? [];
  Map<String, dynamic> toJson() => {
        'complexityScore': complexityScore,
        'confidenceLevel': confidenceLevel,
        'suggestedTags': suggestedTags,
        'relatedTaskIds': relatedTaskIds,
        'categoryProbabilities': categoryProbabilities,
        'optimizationTips': optimizationTips,
        'lastAnalyzed': lastAnalyzed?.toIso8601String(),
      };
  factory TaskAIData.fromJson(Map<String, dynamic> json) {
    return TaskAIData(
      complexityScore: json['complexityScore']?.toDouble() ?? 0.5,
      confidenceLevel: json['confidenceLevel']?.toDouble() ?? 0.7,
      suggestedTags: List<String>.from(json['suggestedTags'] ?? []),
      relatedTaskIds: List<String>.from(json['relatedTaskIds'] ?? []),
      categoryProbabilities:
          Map<String, double>.from(json['categoryProbabilities'] ?? {}),
      optimizationTips: List<String>.from(json['optimizationTips'] ?? []),
      lastAnalyzed: json['lastAnalyzed'] != null
          ? DateTime.parse(json['lastAnalyzed'])
          : null,
    );
  }
}

@HiveType(typeId: 18)
class TaskMetrics extends HiveObject {
  @HiveField(0)
  Duration totalTimeSpent;
  @HiveField(1)
  int pomodoroSessionsCompleted;
  @HiveField(2)
  double estimationAccuracy;
  @HiveField(3)
  int interruptions;
  @HiveField(4)
  double focusScore;
  @HiveField(5)
  DateTime? lastWorkedOn;
  TaskMetrics({
    Duration? totalTimeSpent,
    this.pomodoroSessionsCompleted = 0,
    this.estimationAccuracy = 0.0,
    this.interruptions = 0,
    this.focusScore = 0.0,
    this.lastWorkedOn,
  }) : totalTimeSpent = totalTimeSpent ?? Duration.zero;
  Map<String, dynamic> toJson() => {
        'totalTimeSpent': totalTimeSpent.inMilliseconds,
        'pomodoroSessionsCompleted': pomodoroSessionsCompleted,
        'estimationAccuracy': estimationAccuracy,
        'interruptions': interruptions,
        'focusScore': focusScore,
        'lastWorkedOn': lastWorkedOn?.toIso8601String(),
      };
  factory TaskMetrics.fromJson(Map<String, dynamic> json) {
    return TaskMetrics(
      totalTimeSpent: Duration(milliseconds: json['totalTimeSpent'] ?? 0),
      pomodoroSessionsCompleted: json['pomodoroSessionsCompleted'] ?? 0,
      estimationAccuracy: json['estimationAccuracy']?.toDouble() ?? 0.0,
      interruptions: json['interruptions'] ?? 0,
      focusScore: json['focusScore']?.toDouble() ?? 0.0,
      lastWorkedOn: json['lastWorkedOn'] != null
          ? DateTime.parse(json['lastWorkedOn'])
          : null,
    );
  }
  TaskMetrics copyWith({
    Duration? totalTimeSpent,
    int? pomodoroSessionsCompleted,
    double? estimationAccuracy,
    int? interruptions,
    double? focusScore,
    DateTime? lastWorkedOn,
  }) {
    return TaskMetrics(
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      pomodoroSessionsCompleted:
          pomodoroSessionsCompleted ?? this.pomodoroSessionsCompleted,
      estimationAccuracy: estimationAccuracy ?? this.estimationAccuracy,
      interruptions: interruptions ?? this.interruptions,
      focusScore: focusScore ?? this.focusScore,
      lastWorkedOn: lastWorkedOn ?? this.lastWorkedOn,
    );
  }
}

@HiveType(typeId: 19)
class TaskTimeEntry extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  DateTime startTime;
  @HiveField(2)
  DateTime? endTime;
  @HiveField(3)
  String description;
  @HiveField(4)
  bool isPomodoroSession;
  @HiveField(5)
  Map<String, dynamic> metadata;
  TaskTimeEntry({
    required this.id,
    required this.startTime,
    this.endTime,
    this.description = '',
    this.isPomodoroSession = false,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isActive => endTime == null;
  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'description': description,
        'isPomodoroSession': isPomodoroSession,
        'metadata': metadata,
      };
  factory TaskTimeEntry.fromJson(Map<String, dynamic> json) {
    return TaskTimeEntry(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      description: json['description'] ?? '',
      isPomodoroSession: json['isPomodoroSession'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  TaskTimeEntry copyWith({
    DateTime? endTime,
    String? description,
    bool? isPomodoroSession,
    Map<String, dynamic>? metadata,
  }) {
    return TaskTimeEntry(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      isPomodoroSession: isPomodoroSession ?? this.isPomodoroSession,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Enums
@HiveType(typeId: 20)
enum TaskCategory {
  @HiveField(0)
  general,
  @HiveField(1)
  coding,
  @HiveField(2)
  writing,
  @HiveField(3)
  meeting,
  @HiveField(4)
  research,
  @HiveField(5)
  design,
  @HiveField(6)
  planning,
  @HiveField(7)
  review,
  @HiveField(8)
  testing,
  @HiveField(9)
  documentation,
  @HiveField(10)
  communication,
  @HiveField(11)
  maintenance,
  @HiveField(12)
  learning,
}

@HiveType(typeId: 21)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  critical,
}

@HiveType(typeId: 22)
enum TaskStatus {
  @HiveField(0)
  todo,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  paused,
  @HiveField(3)
  blocked,
  @HiveField(4)
  review,
  @HiveField(5)
  done,
  @HiveField(6)
  archived,
}

@HiveType(typeId: 23)
enum TaskUrgency {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  critical,
}

@HiveType(typeId: 24)
enum RecurrenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  yearly,
  @HiveField(5)
  custom,
}
