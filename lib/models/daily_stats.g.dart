// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyStatsAdapter extends TypeAdapter<DailyStats> {
  @override
  final int typeId = 4;

  @override
  DailyStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStats(
      date: fields[0] as DateTime,
      completedSessions: fields[1] as int,
      totalMinutes: fields[2] as int,
      tasksCompleted: fields[3] as int,
      focusScore: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.completedSessions)
      ..writeByte(2)
      ..write(obj.totalMinutes)
      ..writeByte(3)
      ..write(obj.tasksCompleted)
      ..writeByte(4)
      ..write(obj.focusScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
