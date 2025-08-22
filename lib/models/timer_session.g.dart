// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerSessionAdapter extends TypeAdapter<TimerSession> {
  @override
  final int typeId = 5;

  @override
  TimerSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerSession(
      id: fields[0] as String,
      type: fields[1] as TimerType,
      plannedDuration: fields[2] as int,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      completed: fields[5] as bool,
      taskId: fields[6] as String?,
      actualDuration: fields[7] as int?,
      pausedDuration: fields[8] as int,
      pauseTimestamps: (fields[9] as List?)?.cast<DateTime>(),
      resumeTimestamps: (fields[10] as List?)?.cast<DateTime>(),
      metadata: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, TimerSession obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.plannedDuration)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.taskId)
      ..writeByte(7)
      ..write(obj.actualDuration)
      ..writeByte(8)
      ..write(obj.pausedDuration)
      ..writeByte(9)
      ..write(obj.pauseTimestamps)
      ..writeByte(10)
      ..write(obj.resumeTimestamps)
      ..writeByte(11)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
