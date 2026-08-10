import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'sync_action_type.dart';

part 'sync_action.g.dart';

@HiveType(typeId: 1)
class SyncAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SyncActionType type;

  @HiveField(2)
  final Map<String, dynamic> payload;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String organizationId;

  SyncAction({
    String? id,
    required this.type,
    required this.payload,
    DateTime? timestamp,
    required this.organizationId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory SyncAction.submitProof({
    required String taskId,
    required List<String> beforePaths,
    required List<String> afterPaths,
    required String description,
    required String organizationId,
  }) {
    return SyncAction(
      type: SyncActionType.submitProof,
      payload: {
        'taskId': taskId,
        'beforePaths': beforePaths,
        'afterPaths': afterPaths,
        'description': description,
      },
      organizationId: organizationId,
    );
  }

  factory SyncAction.createMessage({
    required String taskId,
    required String text,
    required String organizationId,
  }) {
    return SyncAction(
      type: SyncActionType.createMessage,
      payload: {
        'taskId': taskId,
        'text': text,
      },
      organizationId: organizationId,
    );
  }

  factory SyncAction.updateSubmissionStatus({
    required String submissionId,
    required String status,
    required String organizationId,
    String? feedback,
  }) {
    return SyncAction(
      type: SyncActionType.updateSubmissionStatus,
      payload: {
        'submissionId': submissionId,
        'status': status,
        if (feedback != null) 'feedback': feedback,
      },
      organizationId: organizationId,
    );
  }
}
