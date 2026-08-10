import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';
import '../../state/task_providers.dart';
import '../screens/task_detail_screen.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountsProvider)[task.id] ?? 0;
    
    Color statusColor;
    switch (task.status) {
      case 'completed': statusColor = AppTheme.successGreen; break;
      case 'submitted': statusColor = AppTheme.secondaryBlue; break;
      case 'in-progress':
      case 'in_progress': statusColor = AppTheme.secondaryBlue; break;
      case 'rejected': statusColor = AppTheme.primaryCoral; break;
      default: statusColor = AppTheme.textMuted;
    }

    final hasBeenRejected = task.status == 'pending' && 
                           task.history != null && 
                           task.history!.any((h) => h.action.toLowerCase().contains('reject'));

    return GestureDetector(
      onTap: onTap ?? () async {
        // ✅ FIX: Refresh task list when returning from detail screen
        // This ensures deleted tasks are removed from the list
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: task.id)),
        );
        // Refresh the task list after returning
        ref.read(tasksProvider.notifier).loadTasks();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildPriorityIndicator(task.priority),
                          if (task.adminFiles != null && task.adminFiles!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.attach_file_rounded, color: AppTheme.textMuted, size: 14),
                            Text('${task.adminFiles!.length}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      'Created on: ${DateFormat('dd/MM/yyyy').format(task.createdAt)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  task.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                // ✅ FIX: Display reference files on dashboard card
                if (task.adminFiles != null && task.adminFiles!.isNotEmpty)
                  _buildReferenceFilesList(task.adminFiles!, task.adminFileNames),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.borderLight, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(task.status, statusColor),
                    if (hasBeenRejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primaryCoral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.2))),
                        child: const Row(
                          children: [
                            Icon(Icons.assignment_return_rounded, color: AppTheme.primaryCoral, size: 10),
                            SizedBox(width: 4),
                            Text('REWORK', style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                    _buildInfoItem(
                      Icons.group_outlined, 
                      task.assignedToNames != null && task.assignedToNames!.isNotEmpty 
                          ? (task.assignedToNames!.length > 1 
                              ? '${task.assignedToNames![0]} +${task.assignedToNames!.length - 1}' 
                              : task.assignedToNames![0])
                          : 'Unassigned'
                    ),
                  ],
                ),
                if (task.dependsOn != null && task.dependsOn!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCoral.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: AppTheme.primaryCoral, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'LOCKED: Prerequisite task pending',
                            style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

              ],
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryCoral,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(String priority) {
    Color color = AppTheme.secondaryBlue;
    if (priority == 'high' || priority == 'extreme') color = AppTheme.primaryCoral;
    if (priority == 'low') color = AppTheme.successGreen;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          priority.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 11),
        ),
      ],
    );
  }

  // ✅ FIX: Display reference files as chips on dashboard card
  Widget _buildReferenceFilesList(List<String> fileUrls, List<String>? fileNames) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          fileUrls.length,
          (index) {
            final fileName = fileNames != null && index < fileNames.length
                ? fileNames[index]
                : 'File ${index + 1}';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.attach_file, size: 14),
                label: Text(
                  fileName.length > 15 ? '${fileName.substring(0, 12)}...' : fileName,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                side: BorderSide(color: AppTheme.secondaryBlue.withValues(alpha: 0.2)),
              ),
            );
          },
        ),
      ),
    );
  }
}
