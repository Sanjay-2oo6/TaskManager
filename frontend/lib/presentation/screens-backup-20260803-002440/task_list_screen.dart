import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/task_providers.dart';
import '../../core/theme/app_theme.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final bool showMyTasksOnly;

  const TaskListScreen({
    super.key,
    this.showMyTasksOnly = false,
  });

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks on screen init
    Future.microtask(() {
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(tasksProvider);

    if (taskState.isLoading && taskState.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskState.error != null && taskState.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.primaryCoral),
            const SizedBox(height: 16),
            Text(taskState.error ?? 'Failed to load tasks'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(tasksProvider.notifier).loadTasks();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (taskState.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              widget.showMyTasksOnly ? 'No tasks assigned to you' : 'No tasks available',
              style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(tasksProvider.notifier).loadTasks();
      },
      child: ListView.builder(
        itemCount: taskState.tasks.length,
        itemBuilder: (context, index) {
          final task = taskState.tasks[index];
          return _TaskCard(task: task);
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Status: ${task.statusLabel} ï¿½ Priority: ${task.priorityLabel}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Due: ${task.dueDateFormatted}',
              style: TextStyle(
                fontSize: 12,
                color: task.isOverdue ? AppTheme.primaryCoral : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Assigned to: ${task.assignedToDisplay}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: _buildStatusChip(task.status),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(taskId: task.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColors = {
      'pending': AppTheme.primaryCoral,
      'in-progress': AppTheme.secondaryBlue,
      'submitted': Colors.orange,
      'completed': Colors.green,
      'rejected': Colors.red,
      'waiting': Colors.grey,
    };

    return Chip(
      label: Text(
        _getStatusLabel(status),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: statusColors[status] ?? Colors.grey,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getStatusLabel(String status) {
    const labels = {
      'pending': 'Pending',
      'in-progress': 'In Progress',
      'submitted': 'Submitted',
      'completed': 'Completed',
      'rejected': 'Rejected',
      'waiting': 'Waiting',
    };
    return labels[status] ?? status;
  }
}


