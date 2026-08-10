import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task.dart';
import '../services/api_client.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task> getTask(String id);
  Future<dynamic> createTask(Task task, {List<String>? multiAssignedTo, List<PlatformFile>? adminFiles});
  Future<Task> updateTask(String id, Task task, {List<PlatformFile>? adminFiles, List<String>? filesToDelete});
  Future<void> deleteTask(String id);
  Future<dynamic> getSubmissionsByTaskId(String taskId);
}

class TaskRepositoryImpl implements TaskRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const String _tasksCacheKey = 'cached_tasks';
  static const String _lastFetchKey = 'last_tasks_fetch';
  static const Duration _cacheDuration = Duration(minutes: 5);

  TaskRepositoryImpl(this._apiClient, this._prefs);

  @override
  Future<List<Task>> getTasks() async {
    try {
      final response = await _apiClient.getTasks();
      final data = response.data['data'] as List;
      final tasks = data.map((task) => Task.fromJson(task)).toList();
      
      // ✅ FIX: Deduplicate tasks by ID to prevent showing the same task multiple times
      final uniqueTasks = <String, Task>{};
      for (final task in tasks) {
        uniqueTasks[task.id] = task;
      }
      final deduplicatedTasks = uniqueTasks.values.toList();
      
      await _cacheTasks(deduplicatedTasks);
      return deduplicatedTasks;
    } catch (e) {
      final cachedTasks = await _getCachedTasks();
      if (cachedTasks != null) return cachedTasks;
      rethrow;
    }
  }

  @override
  Future<Task> getTask(String id) async {
    final response = await _apiClient.getTask(id);
    return Task.fromJson(response.data['data']);
  }

  @override
  Future<dynamic> createTask(Task task, {List<String>? multiAssignedTo, List<PlatformFile>? adminFiles}) async {
    final formData = FormData.fromMap({
      'title': task.title,
      'description': task.description ?? '',
      'dueDate': task.dueDate.toIso8601String(),
      'priority': task.priority,
      'assignedTo': json.encode(task.assignedTo),
      if (task.adminNote != null && task.adminNote!.isNotEmpty) 'adminNote': task.adminNote,
      if (task.parentTaskId != null) 'parentTaskId': task.parentTaskId,
      if (task.dependsOn != null && task.dependsOn!.isNotEmpty) 'dependsOn': json.encode(task.dependsOn),
    });

    // Support both web (bytes) and mobile (path) file uploads
    if (adminFiles != null) {
      for (var file in adminFiles) {
        if (file.bytes != null) {
          formData.files.add(MapEntry(
            'adminFiles',
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        } else if (file.path != null) {
          formData.files.add(MapEntry(
            'adminFiles',
            await MultipartFile.fromFile(file.path!, filename: file.name),
          ));
        }
      }
    }

    final response = await _apiClient.createTask(formData);
    final data = response.data['data'];
    await _invalidateCache();
    
    if (data is List) {
      return data.map((t) => Task.fromJson(t)).toList();
    }
    return Task.fromJson(data);
  }

  @override
  Future<Task> updateTask(String id, Task task, {List<PlatformFile>? adminFiles, List<String>? filesToDelete}) async {
    final formData = FormData.fromMap({
      'title': task.title,
      'description': task.description ?? '',
      'assignedTo': json.encode(task.assignedTo),
      'status': task.status,
      'dueDate': task.dueDate.toIso8601String(),
      'priority': task.priority,
      if (task.adminNote != null && task.adminNote!.isNotEmpty) 'adminNote': task.adminNote,
      if (task.dependsOn != null && task.dependsOn!.isNotEmpty) 'dependsOn': json.encode(task.dependsOn),
      // ✅ NEW: Pass files to delete
      if (filesToDelete != null && filesToDelete.isNotEmpty) 'filesToDelete': json.encode(filesToDelete),
    });

    // Support both web (bytes) and mobile (path) file uploads
    if (adminFiles != null) {
      for (var file in adminFiles) {
        if (file.bytes != null) {
          formData.files.add(MapEntry(
            'adminFiles',
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        } else if (file.path != null) {
          formData.files.add(MapEntry(
            'adminFiles',
            await MultipartFile.fromFile(file.path!, filename: file.name),
          ));
        }
      }
    }

    final response = await _apiClient.updateTask(id, formData);
    await _invalidateCache();
    return Task.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _apiClient.deleteTask(id);
    await _invalidateCache();
  }

  @override
  Future<dynamic> getSubmissionsByTaskId(String taskId) async {
    final response = await _apiClient.getSubmissionsByTaskId(taskId);
    return response.data['data'];
  }

  Future<List<Task>?> _getCachedTasks() async {
    final lastFetchStr = _prefs.getString(_lastFetchKey);
    if (lastFetchStr == null) return null;
    final lastFetch = DateTime.parse(lastFetchStr);
    if (DateTime.now().difference(lastFetch) > _cacheDuration) return null;
    final cachedData = _prefs.getString(_tasksCacheKey);
    if (cachedData == null) return null;
    try {
      final tasksJson = json.decode(cachedData) as List;
      return tasksJson.map((task) => Task.fromJson(task)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheTasks(List<Task> tasks) async {
    final tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
    await _prefs.setString(_tasksCacheKey, tasksJson);
    await _prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
  }

  Future<void> _invalidateCache() async {
    await _prefs.remove(_tasksCacheKey);
    await _prefs.remove(_lastFetchKey);
  }
}
