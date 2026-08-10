import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/task_providers.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);
    final completedTasks = tasksState.tasks.where((t) => t.status == 'completed').toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Task Archive', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppTheme.secondaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  '${completedTasks.length} Completed Tasks',
                  style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: completedTasks.isEmpty
                ? const Center(
                    child: Text(
                      'No archived records found',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: completedTasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(
                        task: completedTasks[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(taskId: completedTasks[index].id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
