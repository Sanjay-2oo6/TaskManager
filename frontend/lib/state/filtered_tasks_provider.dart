import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task.dart';
import 'auth_provider.dart';
import 'task_providers.dart';

/// Provider that returns tasks filtered by organization and role
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final tasksState = ref.watch(tasksProvider);

  final allTasks = tasksState.tasks;

  // Super admin sees tasks from all organizations (when viewing specific org)
  if (authState.isSuperAdmin) {
    return allTasks;
  }

  // Admin and member see only tasks from their organization
  if (!authState.hasOrganization) {
    return [];
  }

  final userOrgId = authState.organizationId;
  return allTasks
      .where((task) => task.organizationId == userOrgId)
      .toList();
});

/// Provider that returns tasks assigned to current user
final myAssignedTasksProvider = Provider<List<Task>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final filteredTasks = ref.watch(filteredTasksProvider);

  final userId = authState.user?['id']?.toString();
  if (userId == null) return [];

  return filteredTasks
      .where((task) => task.assignedTo.contains(userId))
      .toList();
});

/// Provider that returns tasks created by current user
final myCreatedTasksProvider = Provider<List<Task>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final filteredTasks = ref.watch(filteredTasksProvider);

  final userId = authState.user?['id']?.toString();
  if (userId == null) return [];

  return filteredTasks
      .where((task) => task.createdBy == userId)
      .toList();
});

/// Provider that returns tasks by status within organization
final tasksByStatusProvider = Provider.family<List<Task>, String>((ref, status) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  return filteredTasks
      .where((task) => task.status == status)
      .toList();
});

/// Provider that returns tasks by priority within organization
final tasksByPriorityProvider = Provider.family<List<Task>, String>((ref, priority) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  return filteredTasks
      .where((task) => task.priority == priority)
      .toList();
});

/// Provider that returns overdue tasks within organization
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  final now = DateTime.now();

  return filteredTasks
      .where((task) => task.dueDate.isBefore(now) && task.status != 'completed')
      .toList();
});

/// Provider that returns upcoming tasks within organization (next 7 days)
final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  final now = DateTime.now();
  final sevenDaysLater = now.add(Duration(days: 7));

  return filteredTasks
      .where((task) => 
          task.dueDate.isAfter(now) && 
          task.dueDate.isBefore(sevenDaysLater) &&
          task.status != 'completed')
      .toList();
});

/// Provider that returns task statistics for current organization
final taskStatsProvider = Provider<TaskStats>((ref) {
  final filteredTasks = ref.watch(filteredTasksProvider);

  return TaskStats(
    total: filteredTasks.length,
    pending: filteredTasks.where((t) => t.status == 'pending').length,
    inProgress: filteredTasks.where((t) => t.status == 'in_progress').length,
    completed: filteredTasks.where((t) => t.status == 'completed').length,
    overdue: ref.watch(overdueTasksProvider).length,
    upcoming: ref.watch(upcomingTasksProvider).length,
  );
});

/// Data class for task statistics
class TaskStats {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;
  final int upcoming;

  TaskStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
    required this.upcoming,
  });

  int get activeTasks => pending + inProgress;
}

/// Check if user can perform action on task (based on role and organization)
final canEditTaskProvider = Provider.family<bool, String>((ref, taskId) {
  final authState = ref.watch(authNotifierProvider);
  final tasksState = ref.watch(tasksProvider);

  // Super admin cannot edit regular tasks
  if (authState.isSuperAdmin) return false;

  // Admin can edit tasks in their organization
  if (authState.isAdmin) {
    final task = tasksState.tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => Task(
        id: '', title: '', assignedTo: [], createdBy: '', 
        status: '', dueDate: DateTime.now(), priority: '', 
        description: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ),
    );
    return task.organizationId == authState.organizationId;
  }

  // Member cannot edit tasks
  return false;
});

/// Check if user can delete task (admin only)
final canDeleteTaskProvider = Provider.family<bool, String>((ref, taskId) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAdmin;
});

/// Check if user can create task (admin and member)
final canCreateTaskProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.hasOrganization && (authState.isAdmin || authState.isMember);
});
