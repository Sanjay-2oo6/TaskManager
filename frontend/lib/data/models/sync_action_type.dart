import 'package:hive/hive.dart';

part 'sync_action_type.g.dart';

@HiveType(typeId: 0)
enum SyncActionType {
  @HiveField(0)
  submitProof,
  
  @HiveField(1)
  createMessage,
  
  @HiveField(2)
  updateSubmissionStatus,
}
