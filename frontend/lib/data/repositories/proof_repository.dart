import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/submission.dart';
import '../models/sync_action.dart';
import '../models/sync_action_type.dart';
import '../services/sync_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:file_picker/file_picker.dart';

class ProofRepository {
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  ProofRepository(this._syncService);

  Future<void> submitProof({
    required String taskId,
    required String userId,
    required String organizationId,
    required List<PlatformFile> beforeFiles,
    required List<PlatformFile> afterFiles,
    String? description,
  }) async {
    List<String> localBeforePaths = [];
    List<String> localAfterPaths = [];

    // For web fallback since PlatformFile.path is null on Web
    List<Uint8List> webBeforeBytes = [];
    List<Uint8List> webAfterBytes = [];
    List<String> webBeforeNames = [];
    List<String> webAfterNames = [];

    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      final proofsDir =
          Directory('${appDir.path}/${AppConstants.proofsSubDir}');
      if (!await proofsDir.exists()) {
        await proofsDir.create(recursive: true);
      }

      for (var file in beforeFiles) {
        if (file.path != null && file.path!.isNotEmpty) {
          final ext = extension(file.path!);
          final target = '${proofsDir.path}/${_uuid.v4()}$ext';
          try {
            await File(file.path!).copy(target);
            localBeforePaths.add(target);
            print('✅ Before file saved: $target');
          } catch (e) {
            print('❌ Failed to copy before file: $e');
          }
        }
      }
      for (var file in afterFiles) {
        if (file.path != null && file.path!.isNotEmpty) {
          final ext = extension(file.path!);
          final target = '${proofsDir.path}/${_uuid.v4()}$ext';
          try {
            await File(file.path!).copy(target);
            localAfterPaths.add(target);
            print('✅ After file saved: $target');
          } catch (e) {
            print('❌ Failed to copy after file: $e');
          }
        }
      }
    } else {
      // On Web, extract bytes
      for (var file in beforeFiles) {
        if (file.bytes != null) {
          webBeforeBytes.add(file.bytes!);
          webBeforeNames.add(file.name);
        }
      }
      for (var file in afterFiles) {
        if (file.bytes != null) {
          webAfterBytes.add(file.bytes!);
          webAfterNames.add(file.name);
        }
      }
    }

    final submission = Submission(
      taskId: taskId,
      userId: userId,
      beforeFiles: localBeforePaths,
      afterFiles: localAfterPaths,
      beforeFileNames: webBeforeNames,
      afterFileNames: webAfterNames,
      description: description,
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
    );

    final subBox = Hive.box<Submission>(AppConstants.submissionsBox);
    await subBox.add(submission);
    print('✅ Submission saved to Hive: taskId=$taskId, beforeFiles=${localBeforePaths.length}, afterFiles=${localAfterPaths.length}');

    final syncAction = SyncAction(
      id: _uuid.v4(),
      type: SyncActionType.submitProof,
      organizationId: organizationId,
      payload: {
        'taskId': taskId,
        'description': description ?? '',
        // ✅ Use exact field names that sync_service expects
        'beforePaths': localBeforePaths,
        'afterPaths': localAfterPaths,
      },
      timestamp: DateTime.now(),
    );

    await _syncService.addToQueue(syncAction);
    print('✅ Sync action queued: ${syncAction.id}');
  }
}
