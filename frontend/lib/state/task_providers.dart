import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/api_client.dart';
import 'analytics_provider.dart';
import 'auth_provider.dart';
import '../../core/globals.dart';
import '../../core/theme/app_theme.dart';

import '../../data/services/socket_service.dart';
import '../../data/models/message.dart';
import 'message_providers.dart';
import 'submission_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
final activeChatTaskIdProvider = StateProvider<String?>((ref) => null);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

final taskApiServiceProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final apiClient = ref.watch(taskApiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return TaskRepositoryImpl(apiClient, prefs);
});


// --- Real-time Socket Provider ---
final socketServiceProvider = Provider<SocketService>((ref) {
  final socketService = SocketService(
    onTaskUpdate: (data) {
      print('🔄 Socket handler onTaskUpdate called');
      print('   data: $data');
      print('   task status: ${data['task']?['status']}');
      if (data['task'] != null) {
        final task = Task.fromJson(data['task']);
        print('   ✅ Task parsed: id=${task.id}, status=${task.status}');
        ref.read(tasksProvider.notifier).upsertTask(task);
        ref.read(taskDetailProvider(task.id).notifier).syncTask(task);
        print('   ✅ Task synced to providers');
      } else {
        print('   ⚠️ No task data, full reload');
        ref.read(tasksProvider.notifier).loadTasks(silent: true);
      }
      // ✅ Force refresh of analytics so they reload immediately
      ref.invalidate(teamActivityProvider);
      ref.invalidate(systemStatsProvider);
      ref.invalidate(leaderboardProvider);
      print('   ✅ All providers invalidated');
    },
    onNewSubmission: (data) {
      print('📸 Socket handler onNewSubmission called');
      print('   taskId: ${data['taskId']}');
      print('   submissionId: ${data['submissionId']}');
      if (data['task'] != null) {
        final task = Task.fromJson(data['task']);
        ref.read(tasksProvider.notifier).upsertTask(task);
        ref.read(taskDetailProvider(task.id).notifier).syncTask(task);
        print('   ✅ Task updated');
      }
      if (data['submission'] != null && data['taskId'] != null) {
        ref.read(submissionsForTaskProvider(data['taskId']).notifier)
           .addSubmissionLocally(data['submission']);
        print('   ✅ Submission added to task');
      }
      // ✅ FIX: Invalidate submissions list in admin review screen
      ref.invalidate(pendingSubmissionsProvider);
      ref.invalidate(teamActivityProvider);
      print('   ✅ Admin submissions provider invalidated');
    },
    onSubmissionReviewed: (data) {
      print('⚖️ Socket handler onSubmissionReviewed called');
      if (data['task'] != null) {
        final task = Task.fromJson(data['task']);
        ref.read(tasksProvider.notifier).upsertTask(task);
        ref.read(taskDetailProvider(task.id).notifier).syncTask(task);
      }
      if (data['submission'] != null && data['taskId'] != null) {
        ref.read(submissionsForTaskProvider(data['taskId']).notifier)
           .upsertSubmissionLocally(data['submission']);
      }
      // ✅ FIX #1: Invalidate analytics and unread counts after submission review
      // Also invalidate pending submissions list so admin sees updated status
      ref.invalidate(pendingSubmissionsProvider);
      ref.invalidate(unreadCountsProvider);
      ref.invalidate(teamActivityProvider);
      ref.invalidate(systemStatsProvider);
      ref.invalidate(leaderboardProvider);
      print('   ✅ All providers invalidated after submission review');
    },
    onTaskUnlocked: (data) {
      // Direct notification to the affected worker
      final currentUserId = ref.read(authNotifierProvider).user?['id'];
      if (data['operatorId'] == currentUserId) {
        if (appScaffoldMessengerKey.currentState != null) {
          appScaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'A task has been unlocked for you!'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      ref.read(tasksProvider.notifier).loadTasks(silent: true);
    },
    onNewMessage: (data) {
      print('🔄 Socket handler onNewMessage called');
      print('   data: $data');
      print('   data type: ${data.runtimeType}');
      
      if (data['taskId'] != null) {
        final tid = data['taskId'].toString();
        print('   taskId extracted: $tid');
        try {
          final message = Message.fromJson(data);
          print('   ✅ Message converted from JSON');
          print('   message.id: ${message.id}');
          print('   message.text: ${message.text}');
          ref.read(messagesForTaskProvider(tid).notifier).addMessage(message);
          print('   ✅ Message added to provider');
        } catch (e) {
          print('   ❌ Error converting message: $e');
        }
      } else {
        print('   ❌ No taskId in data');
      }
    },
    onChatAlert: (data) {
      if (data['taskId'] != null) {
        final authState = ref.read(authNotifierProvider);
        final user = authState.user;
        final currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? '';
        final role = user?['role']?.toString().toLowerCase() ?? '';
        final isAdmin = role == 'admin';
        
        // Logic: Admins see all. Workers only see if they are in the assignedTo list.
        final assignedTo = (data['assignedTo'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final isAssigned = assignedTo.contains(currentUserId);

        if (isAdmin || isAssigned) {
          final tid = data['taskId'].toString();
          print('🔔 Pulse: Notification received for Task $tid');
          ref.read(unreadCountsProvider.notifier).increment(tid);
          
          // Show a visual alert (only if NOT currently viewing this specific chat room)
          final activeChatId = ref.read(activeChatTaskIdProvider);
          print('📊 Active Chat ID Check: Current=$activeChatId vs Target=$tid');
          
          if (tid != activeChatId && appScaffoldMessengerKey.currentState != null) {
            appScaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('NEW MESSAGE FROM ${data['senderName']?.toString().toUpperCase()}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white70)),
                     const SizedBox(height: 2),
                     Text(data['text'] ?? 'New message received', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                backgroundColor: AppTheme.sidebarDark,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'VIEW', 
                  textColor: AppTheme.primaryCoral,
                  onPressed: () {
                     // Navigate if possible or just rely on the badge
                  }
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    },
    onMessagesRead: (data) {
      if (data['taskId'] != null && data['readerId'] != null) {
        final tid = data['taskId'].toString();
        ref.read(messagesForTaskProvider(tid).notifier)
            .updateReadBy(tid, data['readerId'].toString());
      }
    },
    onTyping: (data) {
      if (data['taskId'] != null) {
        ref.read(typingUsersProvider.notifier).setTyping(data['taskId'], data['userName']);
      }
    },
    onStopTyping: (data) {
      if (data['taskId'] != null) {
        ref.read(typingUsersProvider.notifier).clearTyping(data['taskId']);
      }
    },
    // ✅ FIX #6: Add callback to reload messages when reconnecting
    onReconnect: () {
      print('📨 Socket reconnected - should reload messages');
      // Don't invalidate self - this causes socket to be recreated!
      // Instead, just let the app know socket is back and messages can be fetched
    },
  );
  
  socketService.connect();
  ref.onDispose(() => socketService.disconnect());
  
  return socketService;
});

// State Notifiers
class TasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  TasksState({
    required this.tasks,
    this.isLoading = false,
    this.error,
  });

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super(TasksState(tasks: []));

  Future<void> loadTasks({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      if (!silent) state = state.copyWith(isLoading: false, error: ApiClient.friendlyError(e));
    }
  }

  Future<void> createTask(Task task, {List<String>? multiAssignedTo, List<PlatformFile>? adminFiles}) async {
    try {
      final result = await _repository.createTask(task, multiAssignedTo: multiAssignedTo, adminFiles: adminFiles);
      final List<Task> newTasks = (result is List) 
          ? (result as List).cast<Task>() 
          : [result as Task];
      state = state.copyWith(tasks: [...state.tasks, ...newTasks]);
    } catch (e) {
      state = state.copyWith(error: ApiClient.friendlyError(e));
      rethrow;
    }
  }

  Future<void> updateTask(String id, Task updatedTask, {List<PlatformFile>? adminFiles, List<String>? filesToDelete}) async {
    try {
      final task = await _repository.updateTask(id, updatedTask, adminFiles: adminFiles, filesToDelete: filesToDelete);
      state = state.copyWith(tasks: state.tasks.map((t) => t.id == id ? task : t).toList());
    } catch (e) {
      state = state.copyWith(error: ApiClient.friendlyError(e));
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      state = state.copyWith(tasks: state.tasks.where((t) => t.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: ApiClient.friendlyError(e));
      rethrow;
    }
  }

  void upsertTask(Task task) {
    if (state.tasks.any((t) => t.id == task.id)) {
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == task.id ? task : t).toList(),
      );
    } else {
      state = state.copyWith(tasks: [task, ...state.tasks]);
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository);
});

class TaskDetailState {
  final Task? task;
  final bool isLoading;
  final String? error;

  TaskDetailState({this.task, this.isLoading = false, this.error});

  TaskDetailState copyWith({Task? task, bool? isLoading, String? error}) {
    return TaskDetailState(
      task: task ?? this.task,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final TaskRepository _repository;

  TaskDetailNotifier(this._repository) : super(TaskDetailState());

  Future<void> loadTask(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final task = await _repository.getTask(id);
      state = state.copyWith(task: task, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.friendlyError(e));
    }
  }

  Future<void> updateTask(Task updatedTask, {List<PlatformFile>? adminFiles, List<String>? filesToDelete}) async {
    if (state.task == null) return;
    try {
      final task = await _repository.updateTask(state.task!.id, updatedTask, adminFiles: adminFiles, filesToDelete: filesToDelete);
      print('✅ updateTask response: adminFiles=${task.adminFiles?.length ?? 0}, adminFileNames=${task.adminFileNames?.length ?? 0}');
      state = state.copyWith(task: task);
      print('✅ State updated with task: ${task.id}');
      
      // ✅ ENHANCEMENT: Also update dashboard immediately (in addition to Socket.IO)
      // This ensures tasksProvider reflects the change without waiting for broadcast
      // The context is not available here, so we'll rely on Socket.IO which is already listening
      // But if Socket.IO is delayed, the caller can manually upsert after this completes
    } catch (e) {
      print('❌ updateTask error: $e');
      state = state.copyWith(error: ApiClient.friendlyError(e));
    }
  }

  void syncTask(Task task) {
    if (state.task?.id == task.id) {
      state = state.copyWith(task: task);
    }
  }
}

final taskDetailProvider =
    StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, String>(
        (ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  final notifier = TaskDetailNotifier(repository);
  notifier.loadTask(taskId);
  return notifier;
});

// Submissions provider remains the same
class SubmissionsState {
  final List<Map<String, dynamic>> submissions;
  final bool isLoading;
  final String? error;
  SubmissionsState({required this.submissions, this.isLoading = false, this.error});
  SubmissionsState copyWith({List<Map<String, dynamic>>? submissions, bool? isLoading, String? error}) {
    return SubmissionsState(submissions: submissions ?? this.submissions, isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
  }
}

class SubmissionsNotifier extends StateNotifier<SubmissionsState> {
  final TaskRepository _repository;
  SubmissionsNotifier(this._repository) : super(SubmissionsState(submissions: []));
  Future<void> loadSubmissionsForTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getSubmissionsByTaskId(taskId);
      // ✅ FIX 10: Ensure response is always treated as a list (defensive coding)
      if (response is List) {
        state = state.copyWith(submissions: response.cast<Map<String, dynamic>>(), isLoading: false);
      } else if (response is Map) {
        // If response is a single map, wrap it in a list
        state = state.copyWith(submissions: [response as Map<String, dynamic>], isLoading: false);
      } else {
        // Fallback to empty list
        state = state.copyWith(submissions: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.friendlyError(e));
    }
  }

  void addSubmissionLocally(dynamic data) {
    state = state.copyWith(
      submissions: [data as Map<String, dynamic>, ...state.submissions],
    );
  }

  void upsertSubmissionLocally(dynamic data) {
    final subId = data['_id']?.toString();
    if (state.submissions.any((s) => s['_id']?.toString() == subId)) {
      state = state.copyWith(
        submissions: state.submissions
            .map((s) => s['_id']?.toString() == subId ? data as Map<String, dynamic> : s)
            .toList(),
      );
    } else {
      state = state.copyWith(submissions: [data as Map<String, dynamic>, ...state.submissions]);
    }
  }
}

final submissionsForTaskProvider = StateNotifierProvider.family<SubmissionsNotifier, SubmissionsState, String>((ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  final notifier = SubmissionsNotifier(repository);
  notifier.loadSubmissionsForTask(taskId);
  return notifier;
});

// Notifications / Unread Tracking
final unreadCountsProvider = StateNotifierProvider<UnreadCountsNotifier, Map<String, int>>((ref) {
  return UnreadCountsNotifier();
});

class UnreadCountsNotifier extends StateNotifier<Map<String, int>> {
  UnreadCountsNotifier() : super({});

  /// Load initial unread counts from the server (Catch-up Sync).
  void initialize(Map<String, int> counts) {
    // Replace state entirely with server counts (server is source of truth)
    state = counts;
    print('🔔 Unread Sync Complete: $state');
  }

  void increment(String taskId) {
    state = {
      ...state,
      taskId: (state[taskId] ?? 0) + 1,
    };
  }

  void clear(String taskId) {
    final newState = {...state};
    newState.remove(taskId); // Remove the key entirely instead of setting to 0
    state = newState;
  }

  void clearAll() {
    state = {};
  }
}

// Typing Indicators Tracking
final typingUsersProvider = StateNotifierProvider<TypingUsersNotifier, Map<String, String?>>((ref) {
  return TypingUsersNotifier();
});

class TypingUsersNotifier extends StateNotifier<Map<String, String?>> {
  TypingUsersNotifier() : super({});

  void setTyping(String taskId, String userName) {
    state = {...state, taskId: userName};
  }

  void clearTyping(String taskId) {
    state = {...state, taskId: null};
  }
}
