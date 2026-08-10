import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';
import '../../state/task_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import 'task_detail_screen.dart';

import '../../state/auth_provider.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final bool showMyTasksOnly;
  
  const TaskListScreen({super.key, this.showMyTasksOnly = false});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final authState = ref.watch(authNotifierProvider);
    final isWorker = authState.user?['role'] == 'member';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Task Control', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 22)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textDark),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryCoral,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryCoral,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Submitted'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textDark),
              onPressed: () => ref.read(tasksProvider.notifier).loadTasks(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Search your task here...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),

            // Tabbed Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildCategorizedList(tasksState, isWorker, authState, 'pending'),
                  _buildCategorizedList(tasksState, isWorker, authState, 'submitted'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: !isWorker
            ? FloatingActionButton(
                heroTag: 'task_list_fab',
                onPressed: () => _navigateToTaskDetail(context, null),
                backgroundColor: AppTheme.primaryCoral,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add_rounded, size: 30),
              )
            : null,
      ),
    );
  }

  Widget _buildCategorizedList(TasksState state, bool isWorker, AuthState authState, String status) {
    if (state.isLoading) return const LoadingIndicator();
    if (state.error != null) return ErrorMessage(
      message: state.error!, 
      onRetry: () => ref.read(tasksProvider.notifier).loadTasks(),
    );

    final filtered = state.tasks.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchController.text.toLowerCase());
      
      // Strict mapping for the tabs
      bool matchesStatus = false;
      if (status == 'pending') {
        // Include 'waiting' (dependency-blocked) tasks in the pending tab
        matchesStatus = t.status == 'pending' || t.status == 'in-progress' || t.status == 'rejected' || t.status == 'waiting';
      } else if (status == 'submitted') {
        matchesStatus = t.status == 'submitted';
      } else if (status == 'completed') {
        matchesStatus = t.status == 'completed';
      }
      
      return matchesSearch && matchesStatus;
    }).toList();

    return _buildTaskList(filtered, isWorker, authState.user?['id'] ?? '');
  }

  Widget _buildTaskList(List<Task> tasks, bool isWorker, String userId) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () {
            _navigateToTaskDetail(context, task.id);
          },
        );
      },
    );
  }

  void _navigateToTaskDetail(BuildContext context, String? taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: taskId),
      ),
    ).then((_) {
      // Refresh tasks when returning from detail screen
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }
}
