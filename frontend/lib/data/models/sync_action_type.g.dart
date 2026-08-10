// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_action_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncActionTypeAdapter extends TypeAdapter<SyncActionType> {
  @override
  final int typeId = 0;

  @override
  SyncActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncActionType.submitProof;
      case 1:
        return SyncActionType.createMessage;
      case 2:
        return SyncActionType.updateSubmissionStatus;
      default:
        return SyncActionType.submitProof;
    }
  }

  @override
  void write(BinaryWriter writer, SyncActionType obj) {
    switch (obj) {
      case SyncActionType.submitProof:
        writer.writeByte(0);
        break;
      case SyncActionType.createMessage:
        writer.writeByte(1);
        break;
      case SyncActionType.updateSubmissionStatus:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
