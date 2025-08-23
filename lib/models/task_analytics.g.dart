// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_analytics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskCompletionDataAdapter extends TypeAdapter<TaskCompletionData> {
  @override
  final int typeId = 56;

  @override
  TaskCompletionData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskCompletionData(
      taskId: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      category: fields[4] as TaskCategory,
      priority: fields[5] as TaskPriority,
      estimatedDuration: fields[6] as Duration,
      timeSpent: fields[7] as Duration,
      startTime: fields[8] as DateTime,
      completedAt: fields[9] as DateTime,
      completed: fields[10] as bool,
      difficultyRating: fields[11] as double,
      interruptions: fields[12] as int?,
      complexityScore: fields[13] as double,
      context: (fields[14] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskCompletionData obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.estimatedDuration)
      ..writeByte(7)
      ..write(obj.timeSpent)
      ..writeByte(8)
      ..write(obj.startTime)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.completed)
      ..writeByte(11)
      ..write(obj.difficultyRating)
      ..writeByte(12)
      ..write(obj.interruptions)
      ..writeByte(13)
      ..write(obj.complexityScore)
      ..writeByte(14)
      ..write(obj.context);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCompletionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserAnalyticsAdapter extends TypeAdapter<UserAnalytics> {
  @override
  final int typeId = 57;

  @override
  UserAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAnalytics(
      userId: fields[0] as String,
      totalTasksCompleted: fields[1] as int,
      totalTimeSpent: fields[2] as Duration,
      averageSessionLength: fields[3] as Duration,
      productivityScore: fields[4] as double,
      focusScore: fields[5] as double,
      estimationAccuracy: fields[6] as double,
      preferredWorkingHours: (fields[7] as List).cast<int>(),
      mostProductiveDay: fields[8] as int,
      categoryPerformance:
          (fields[9] as Map).cast<TaskCategory, CategoryPerformance>(),
      recentTrend: fields[10] as ProductivityTrendDirection,
      lastUpdated: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserAnalytics obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalTasksCompleted)
      ..writeByte(2)
      ..write(obj.totalTimeSpent)
      ..writeByte(3)
      ..write(obj.averageSessionLength)
      ..writeByte(4)
      ..write(obj.productivityScore)
      ..writeByte(5)
      ..write(obj.focusScore)
      ..writeByte(6)
      ..write(obj.estimationAccuracy)
      ..writeByte(7)
      ..write(obj.preferredWorkingHours)
      ..writeByte(8)
      ..write(obj.mostProductiveDay)
      ..writeByte(9)
      ..write(obj.categoryPerformance)
      ..writeByte(10)
      ..write(obj.recentTrend)
      ..writeByte(11)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryPerformanceAdapter extends TypeAdapter<CategoryPerformance> {
  @override
  final int typeId = 58;

  @override
  CategoryPerformance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryPerformance(
      category: fields[0] as TaskCategory,
      totalTasks: fields[1] as int,
      completedTasks: fields[2] as int,
      averageTime: fields[3] as Duration,
      estimationAccuracy: fields[4] as double,
      productivityScore: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryPerformance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.totalTasks)
      ..writeByte(2)
      ..write(obj.completedTasks)
      ..writeByte(3)
      ..write(obj.averageTime)
      ..writeByte(4)
      ..write(obj.estimationAccuracy)
      ..writeByte(5)
      ..write(obj.productivityScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryPerformanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductivityRecommendationAdapter
    extends TypeAdapter<ProductivityRecommendation> {
  @override
  final int typeId = 59;

  @override
  ProductivityRecommendation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductivityRecommendation(
      type: fields[0] as RecommendationType,
      title: fields[1] as String,
      description: fields[2] as String,
      impact: fields[3] as RecommendationImpact,
      effort: fields[4] as RecommendationEffort,
    );
  }

  @override
  void write(BinaryWriter writer, ProductivityRecommendation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.impact)
      ..writeByte(4)
      ..write(obj.effort);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductivityRecommendationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductivityPatternAdapter extends TypeAdapter<ProductivityPattern> {
  @override
  final int typeId = 60;

  @override
  ProductivityPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductivityPattern(
      type: fields[0] as PatternType,
      description: fields[1] as String,
      strength: fields[2] as double,
      confidence: fields[3] as double,
      data: (fields[4] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductivityPattern obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.strength)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductivityPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductivityTrendDirectionAdapter
    extends TypeAdapter<ProductivityTrendDirection> {
  @override
  final int typeId = 50;

  @override
  ProductivityTrendDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProductivityTrendDirection.increasing;
      case 1:
        return ProductivityTrendDirection.decreasing;
      case 2:
        return ProductivityTrendDirection.stable;
      default:
        return ProductivityTrendDirection.increasing;
    }
  }

  @override
  void write(BinaryWriter writer, ProductivityTrendDirection obj) {
    switch (obj) {
      case ProductivityTrendDirection.increasing:
        writer.writeByte(0);
        break;
      case ProductivityTrendDirection.decreasing:
        writer.writeByte(1);
        break;
      case ProductivityTrendDirection.stable:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductivityTrendDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecommendationTypeAdapter extends TypeAdapter<RecommendationType> {
  @override
  final int typeId = 51;

  @override
  RecommendationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecommendationType.focusTime;
      case 1:
        return RecommendationType.estimation;
      case 2:
        return RecommendationType.scheduling;
      case 3:
        return RecommendationType.breaks;
      case 4:
        return RecommendationType.taskSize;
      default:
        return RecommendationType.focusTime;
    }
  }

  @override
  void write(BinaryWriter writer, RecommendationType obj) {
    switch (obj) {
      case RecommendationType.focusTime:
        writer.writeByte(0);
        break;
      case RecommendationType.estimation:
        writer.writeByte(1);
        break;
      case RecommendationType.scheduling:
        writer.writeByte(2);
        break;
      case RecommendationType.breaks:
        writer.writeByte(3);
        break;
      case RecommendationType.taskSize:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecommendationImpactAdapter extends TypeAdapter<RecommendationImpact> {
  @override
  final int typeId = 52;

  @override
  RecommendationImpact read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecommendationImpact.low;
      case 1:
        return RecommendationImpact.medium;
      case 2:
        return RecommendationImpact.high;
      default:
        return RecommendationImpact.low;
    }
  }

  @override
  void write(BinaryWriter writer, RecommendationImpact obj) {
    switch (obj) {
      case RecommendationImpact.low:
        writer.writeByte(0);
        break;
      case RecommendationImpact.medium:
        writer.writeByte(1);
        break;
      case RecommendationImpact.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationImpactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecommendationEffortAdapter extends TypeAdapter<RecommendationEffort> {
  @override
  final int typeId = 53;

  @override
  RecommendationEffort read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecommendationEffort.low;
      case 1:
        return RecommendationEffort.medium;
      case 2:
        return RecommendationEffort.high;
      default:
        return RecommendationEffort.low;
    }
  }

  @override
  void write(BinaryWriter writer, RecommendationEffort obj) {
    switch (obj) {
      case RecommendationEffort.low:
        writer.writeByte(0);
        break;
      case RecommendationEffort.medium:
        writer.writeByte(1);
        break;
      case RecommendationEffort.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationEffortAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ComparisonTypeAdapter extends TypeAdapter<ComparisonType> {
  @override
  final int typeId = 54;

  @override
  ComparisonType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ComparisonType.timeOfDay;
      case 1:
        return ComparisonType.dayOfWeek;
      case 2:
        return ComparisonType.taskCategory;
      case 3:
        return ComparisonType.teamAverage;
      case 4:
        return ComparisonType.historical;
      default:
        return ComparisonType.timeOfDay;
    }
  }

  @override
  void write(BinaryWriter writer, ComparisonType obj) {
    switch (obj) {
      case ComparisonType.timeOfDay:
        writer.writeByte(0);
        break;
      case ComparisonType.dayOfWeek:
        writer.writeByte(1);
        break;
      case ComparisonType.taskCategory:
        writer.writeByte(2);
        break;
      case ComparisonType.teamAverage:
        writer.writeByte(3);
        break;
      case ComparisonType.historical:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternTypeAdapter extends TypeAdapter<PatternType> {
  @override
  final int typeId = 55;

  @override
  PatternType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PatternType.time;
      case 1:
        return PatternType.category;
      case 2:
        return PatternType.duration;
      case 3:
        return PatternType.estimation;
      default:
        return PatternType.time;
    }
  }

  @override
  void write(BinaryWriter writer, PatternType obj) {
    switch (obj) {
      case PatternType.time:
        writer.writeByte(0);
        break;
      case PatternType.category:
        writer.writeByte(1);
        break;
      case PatternType.duration:
        writer.writeByte(2);
        break;
      case PatternType.estimation:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
