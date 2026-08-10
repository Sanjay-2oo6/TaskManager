// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubmissionAdapter extends TypeAdapter<Submission> {
  @override
  final int typeId = 2;

  @override
  Submission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Submission(
      taskId: fields[0] as String,
      userId: fields[1] as String,
      beforeFiles: (fields[2] as List).cast<String>(),
      afterFiles: (fields[3] as List).cast<String>(),
      description: fields[4] as String?,
      status: fields[6] as String,
      createdAt: fields[5] as DateTime,
      beforeFileNames: (fields[7] as List).cast<String>(),
      afterFileNames: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Submission obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.beforeFiles)
      ..writeByte(3)
      ..write(obj.afterFiles)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.beforeFileNames)
      ..writeByte(8)
      ..write(obj.afterFileNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
