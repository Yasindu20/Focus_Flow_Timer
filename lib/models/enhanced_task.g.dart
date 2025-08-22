// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnhancedTaskAdapter extends TypeAdapter<EnhancedTask> {
  @override
  final int typeId = 10;

  @override
  EnhancedTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnhancedTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as TaskCategory,
      priority: fields[4] as TaskPriority,
      createdAt: fields[5] as DateTime,
      completedAt: fields[6] as DateTime?,
      dueDate: fields[7] as DateTime?,
      isCompleted: fields[8] as bool,
      estimatedMinutes: fields[9] as int,
      actualMinutes: fields[10] as int?,
      difficultyRating: fields[11] as double?,
      tags: (fields[12] as List?)?.cast<String>(),
      subtasks: (fields[13] as List?)?.cast<TaskSubtask>(),
      dependencies: (fields[14] as List?)?.cast<String>(),
      status: fields[15] as TaskStatus,
      assignedTo: fields[16] as String?,
      projectId: fields[17] as String?,
      metadata: (fields[18] as Map?)?.cast<String, dynamic>(),
      progress: fields[19] as TaskProgress?,
      comments: (fields[20] as List?)?.cast<TaskComment>(),
      attachments: (fields[21] as List?)?.cast<TaskAttachment>(),
      recurrence: fields[22] as TaskRecurrence?,
      aiData: fields[23] as TaskAIData?,
      metrics: fields[24] as TaskMetrics?,
      timeEntries: (fields[25] as List?)?.cast<TaskTimeEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, EnhancedTask obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.estimatedMinutes)
      ..writeByte(10)
      ..write(obj.actualMinutes)
      ..writeByte(11)
      ..write(obj.difficultyRating)
      ..writeByte(12)
      ..write(obj.tags)
      ..writeByte(13)
      ..write(obj.subtasks)
      ..writeByte(14)
      ..write(obj.dependencies)
      ..writeByte(15)
      ..write(obj.status)
      ..writeByte(16)
      ..write(obj.assignedTo)
      ..writeByte(17)
      ..write(obj.projectId)
      ..writeByte(18)
      ..write(obj.metadata)
      ..writeByte(19)
      ..write(obj.progress)
      ..writeByte(20)
      ..write(obj.comments)
      ..writeByte(21)
      ..write(obj.attachments)
      ..writeByte(22)
      ..write(obj.recurrence)
      ..writeByte(23)
      ..write(obj.aiData)
      ..writeByte(24)
      ..write(obj.metrics)
      ..writeByte(25)
      ..write(obj.timeEntries);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskSubtaskAdapter extends TypeAdapter<TaskSubtask> {
  @override
  final int typeId = 11;

  @override
  TaskSubtask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskSubtask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      estimatedMinutes: fields[6] as int,
      actualMinutes: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskSubtask obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.estimatedMinutes)
      ..writeByte(7)
      ..write(obj.actualMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskSubtaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskProgressAdapter extends TypeAdapter<TaskProgress> {
  @override
  final int typeId = 12;

  @override
  TaskProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskProgress(
      percentage: fields[0] as double,
      lastUpdated: fields[1] as DateTime?,
      checkpoints: (fields[2] as List?)?.cast<ProgressCheckpoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.percentage)
      ..writeByte(1)
      ..write(obj.lastUpdated)
      ..writeByte(2)
      ..write(obj.checkpoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgressCheckpointAdapter extends TypeAdapter<ProgressCheckpoint> {
  @override
  final int typeId = 13;

  @override
  ProgressCheckpoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressCheckpoint(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      percentage: fields[2] as double,
      note: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressCheckpoint obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.percentage)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressCheckpointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskCommentAdapter extends TypeAdapter<TaskComment> {
  @override
  final int typeId = 14;

  @override
  TaskComment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskComment(
      id: fields[0] as String,
      content: fields[1] as String,
      authorId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      editedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskComment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.authorId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.editedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskAttachmentAdapter extends TypeAdapter<TaskAttachment> {
  @override
  final int typeId = 15;

  @override
  TaskAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskAttachment(
      id: fields[0] as String,
      fileName: fields[1] as String,
      filePath: fields[2] as String,
      mimeType: fields[3] as String,
      fileSize: fields[4] as int,
      uploadedAt: fields[5] as DateTime,
      uploadedBy: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TaskAttachment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.mimeType)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.uploadedAt)
      ..writeByte(6)
      ..write(obj.uploadedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskRecurrenceAdapter extends TypeAdapter<TaskRecurrence> {
  @override
  final int typeId = 16;

  @override
  TaskRecurrence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskRecurrence(
      type: fields[0] as RecurrenceType,
      interval: fields[1] as int,
      daysOfWeek: (fields[2] as List?)?.cast<int>(),
      endDate: fields[3] as DateTime?,
      maxOccurrences: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskRecurrence obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.daysOfWeek)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.maxOccurrences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRecurrenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskAIDataAdapter extends TypeAdapter<TaskAIData> {
  @override
  final int typeId = 17;

  @override
  TaskAIData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskAIData(
      complexityScore: fields[0] as double,
      confidenceLevel: fields[1] as double,
      suggestedTags: (fields[2] as List?)?.cast<String>(),
      relatedTaskIds: (fields[3] as List?)?.cast<String>(),
      categoryProbabilities: (fields[4] as Map?)?.cast<String, double>(),
      optimizationTips: (fields[5] as List?)?.cast<String>(),
      lastAnalyzed: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskAIData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.complexityScore)
      ..writeByte(1)
      ..write(obj.confidenceLevel)
      ..writeByte(2)
      ..write(obj.suggestedTags)
      ..writeByte(3)
      ..write(obj.relatedTaskIds)
      ..writeByte(4)
      ..write(obj.categoryProbabilities)
      ..writeByte(5)
      ..write(obj.optimizationTips)
      ..writeByte(6)
      ..write(obj.lastAnalyzed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAIDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskMetricsAdapter extends TypeAdapter<TaskMetrics> {
  @override
  final int typeId = 18;

  @override
  TaskMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskMetrics(
      totalTimeSpent: fields[0] as Duration?,
      pomodoroSessionsCompleted: fields[1] as int,
      estimationAccuracy: fields[2] as double,
      interruptions: fields[3] as int,
      focusScore: fields[4] as double,
      lastWorkedOn: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskMetrics obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.totalTimeSpent)
      ..writeByte(1)
      ..write(obj.pomodoroSessionsCompleted)
      ..writeByte(2)
      ..write(obj.estimationAccuracy)
      ..writeByte(3)
      ..write(obj.interruptions)
      ..writeByte(4)
      ..write(obj.focusScore)
      ..writeByte(5)
      ..write(obj.lastWorkedOn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTimeEntryAdapter extends TypeAdapter<TaskTimeEntry> {
  @override
  final int typeId = 19;

  @override
  TaskTimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskTimeEntry(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      description: fields[3] as String,
      isPomodoroSession: fields[4] as bool,
      metadata: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskTimeEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isPomodoroSession)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTimeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskCategoryAdapter extends TypeAdapter<TaskCategory> {
  @override
  final int typeId = 20;

  @override
  TaskCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskCategory.general;
      case 1:
        return TaskCategory.coding;
      case 2:
        return TaskCategory.writing;
      case 3:
        return TaskCategory.meeting;
      case 4:
        return TaskCategory.research;
      case 5:
        return TaskCategory.design;
      case 6:
        return TaskCategory.planning;
      case 7:
        return TaskCategory.review;
      case 8:
        return TaskCategory.testing;
      case 9:
        return TaskCategory.documentation;
      case 10:
        return TaskCategory.communication;
      case 11:
        return TaskCategory.maintenance;
      case 12:
        return TaskCategory.learning;
      default:
        return TaskCategory.general;
    }
  }

  @override
  void write(BinaryWriter writer, TaskCategory obj) {
    switch (obj) {
      case TaskCategory.general:
        writer.writeByte(0);
        break;
      case TaskCategory.coding:
        writer.writeByte(1);
        break;
      case TaskCategory.writing:
        writer.writeByte(2);
        break;
      case TaskCategory.meeting:
        writer.writeByte(3);
        break;
      case TaskCategory.research:
        writer.writeByte(4);
        break;
      case TaskCategory.design:
        writer.writeByte(5);
        break;
      case TaskCategory.planning:
        writer.writeByte(6);
        break;
      case TaskCategory.review:
        writer.writeByte(7);
        break;
      case TaskCategory.testing:
        writer.writeByte(8);
        break;
      case TaskCategory.documentation:
        writer.writeByte(9);
        break;
      case TaskCategory.communication:
        writer.writeByte(10);
        break;
      case TaskCategory.maintenance:
        writer.writeByte(11);
        break;
      case TaskCategory.learning:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 21;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      case 3:
        return TaskPriority.critical;
      default:
        return TaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
      case TaskPriority.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 22;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.todo;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.paused;
      case 3:
        return TaskStatus.blocked;
      case 4:
        return TaskStatus.review;
      case 5:
        return TaskStatus.done;
      case 6:
        return TaskStatus.archived;
      default:
        return TaskStatus.todo;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.todo:
        writer.writeByte(0);
        break;
      case TaskStatus.inProgress:
        writer.writeByte(1);
        break;
      case TaskStatus.paused:
        writer.writeByte(2);
        break;
      case TaskStatus.blocked:
        writer.writeByte(3);
        break;
      case TaskStatus.review:
        writer.writeByte(4);
        break;
      case TaskStatus.done:
        writer.writeByte(5);
        break;
      case TaskStatus.archived:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskUrgencyAdapter extends TypeAdapter<TaskUrgency> {
  @override
  final int typeId = 23;

  @override
  TaskUrgency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskUrgency.low;
      case 1:
        return TaskUrgency.medium;
      case 2:
        return TaskUrgency.high;
      case 3:
        return TaskUrgency.critical;
      default:
        return TaskUrgency.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskUrgency obj) {
    switch (obj) {
      case TaskUrgency.low:
        writer.writeByte(0);
        break;
      case TaskUrgency.medium:
        writer.writeByte(1);
        break;
      case TaskUrgency.high:
        writer.writeByte(2);
        break;
      case TaskUrgency.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskUrgencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 24;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.none;
      case 1:
        return RecurrenceType.daily;
      case 2:
        return RecurrenceType.weekly;
      case 3:
        return RecurrenceType.monthly;
      case 4:
        return RecurrenceType.yearly;
      case 5:
        return RecurrenceType.custom;
      default:
        return RecurrenceType.none;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.none:
        writer.writeByte(0);
        break;
      case RecurrenceType.daily:
        writer.writeByte(1);
        break;
      case RecurrenceType.weekly:
        writer.writeByte(2);
        break;
      case RecurrenceType.monthly:
        writer.writeByte(3);
        break;
      case RecurrenceType.yearly:
        writer.writeByte(4);
        break;
      case RecurrenceType.custom:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
