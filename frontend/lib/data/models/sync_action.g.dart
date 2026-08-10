// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncActionAdapter extends TypeAdapter<SyncAction> {
  @override
  final int typeId = 1;

  @override
  SyncAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncAction(
      id: fields[0] as String?,
      type: fields[1] as SyncActionType,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      timestamp: fields[3] as DateTime?,
      organizationId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SyncAction obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.organizationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
