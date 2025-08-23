// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 30;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      estimatedMinutes: fields[6] as int,
      actualMinutes: fields[7] as int?,
      category: fields[8] as TaskCategory,
      priority: fields[9] as TaskPriority,
      tags: (fields[10] as List?)?.cast<String>(),
      completedPomodoros: fields[11] as int,
      estimatedPomodoros: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.actualMinutes)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.priority)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.completedPomodoros)
      ..writeByte(12)
      ..write(obj.estimatedPomodoros);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
