import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/sync_action.dart';
import '../models/sync_action_type.dart';
import '../../core/constants/app_constants.dart';
import 'api_client.dart';

class SyncService {
  final _logger = Logger();
  late Box<SyncAction> _syncBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Future<void> init() async {
    _syncBox = await Hive.openBox<SyncAction>('sync_queue');

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _logger.i('🔗 Internet restored. Syncing queue...');
        processQueue();
      }
    });

    if (await _isOnline()) {
      processQueue();
    }
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> addToQueue(SyncAction action) async {
    await _syncBox.put(action.id, action);
    _logger.i('📦 Action queued: ${action.type} (${action.id})');
    if (await _isOnline()) {
      processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing || _syncBox.isEmpty) return;
    _isProcessing = true;

    _logger.i('🔄 Syncing ${_syncBox.length} actions...');
    final actions = List<SyncAction>.from(_syncBox.values)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final action in actions) {
      try {
        _logger.i('📦 Processing: ${action.type} (${action.id})');
        final success = await _performSync(action);
        if (success) {
          await _syncBox.delete(action.id);
          _logger.i('✅ Synced: ${action.id}');
        } else {
          _logger.w('⏸️  Sync paused for: ${action.id}');
          break;
        }
      } catch (e, stackTrace) {
        _logger.e('❌ Sync error for ${action.id}: $e\n$stackTrace');
        break;
      }
    }
    _isProcessing = false;
    _logger.i('🏁 Sync completed. ${_syncBox.length} items remaining in queue');
  }

  Future<bool> _performSync(SyncAction action) async {
    try {
      switch (action.type) {
        case SyncActionType.submitProof:
          return await _syncSubmitProof(action);
        case SyncActionType.createMessage:
          return await _syncCreateMessage(action);
        case SyncActionType.updateSubmissionStatus:
          return await _syncUpdateSubmissionStatus(action);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _logger.e('Auth error - stopping sync queue');
        return false;
      } else if (e.response?.statusCode == 404) {
        _logger.w('Resource not found - skipping action');
        await _syncBox.delete(action.id);
        return true;
      } else {
        _logger.e('Network error: ${e.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Unexpected sync error: $e');
      return false;
    }
  }

  Future<bool> _syncSubmitProof(SyncAction action) async {
    try {
      final payload = action.payload;
      final taskId = payload['taskId'];
      final beforePaths = List<String>.from(payload['beforePaths'] ?? []);
      final afterPaths = List<String>.from(payload['afterPaths'] ?? []);
      final description = payload['description'] ?? '';

      _logger.i('📤 Syncing submission - Task: $taskId, Before files: ${beforePaths.length}, After files: ${afterPaths.length}');

      final formData = FormData.fromMap({
        'taskId': taskId,
        'organizationId': action.organizationId,
        'description': description,
      });

      // ✅ File validation and addition
      int beforeCount = 0;
      for (String path in beforePaths) {
        if (path.isEmpty) continue;
        final f = File(path);
        if (f.existsSync()) {
          try {
            formData.files.add(MapEntry(
              'beforeFiles',
              await MultipartFile.fromFile(path, filename: path.split('/').last),
            ));
            beforeCount++;
            _logger.i('✅ Added before file: ${path.split('/').last}');
          } catch (e) {
            _logger.e('❌ Failed to add before file: $e');
          }
        } else {
          _logger.w('⚠️ Before file not found: $path');
        }
      }

      int afterCount = 0;
      for (String path in afterPaths) {
        if (path.isEmpty) continue;
        final f = File(path);
        if (f.existsSync()) {
          try {
            formData.files.add(MapEntry(
              'afterFiles',
              await MultipartFile.fromFile(path, filename: path.split('/').last),
            ));
            afterCount++;
            _logger.i('✅ Added after file: ${path.split('/').last}');
          } catch (e) {
            _logger.e('❌ Failed to add after file: $e');
          }
        } else {
          _logger.w('⚠️ After file not found: $path');
        }
      }

      _logger.i('✅ Files ready: $beforeCount before, $afterCount after');

      _logger.i('📡 Sending POST to: ${AppConstants.apiBaseUrl}/submissions');
      final response = await ApiClient().createSubmission(formData);
      
      _logger.i('📥 Response status: ${response.statusCode}');
      _logger.i('📥 Response body: ${response.data}');
      
      if (response.statusCode == 201) {
        _logger.i('✅ Submission synced successfully: ${response.data}');
        return true;
      } else {
        _logger.e('❌ Submission sync failed with status ${response.statusCode}: ${response.data}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Submission sync error: $e');
      _logger.e('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> _syncCreateMessage(SyncAction action) async {
    final payload = action.payload;
    final taskId = payload['taskId'];
    final text = payload['text'];

    try {
      final response = await ApiClient().addTaskComment(taskId, text);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _logger.e('Message sync failed: $e');
      return false;
    }
  }

  Future<bool> _syncUpdateSubmissionStatus(SyncAction action) async {
    final payload = action.payload;
    final submissionId = payload['submissionId'];
    final status = payload['status'];
    final feedback = payload['feedback'];

    final response = await ApiClient().updateSubmissionStatus(submissionId, status, feedback: feedback);
    return response.statusCode == 200;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  int get queueLength => _syncBox.length;
  bool get isProcessing => _isProcessing;
}
