import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/analytics_provider.dart';

class TeamActivityScreen extends ConsumerStatefulWidget {
  const TeamActivityScreen({super.key});

  @override
  ConsumerState<TeamActivityScreen> createState() => _TeamActivityScreenState();
}

class _TeamActivityScreenState extends ConsumerState<TeamActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(teamActivityProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Activity Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(teamActivityProvider), 
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textDark)
          )
        ],
      ),
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.primaryCoral))),
        data: (activity) {
          if (activity.isEmpty) return const Center(child: Text('No active assignments found.', style: TextStyle(color: AppTheme.textMuted)));

          return ListView.builder(
            padding: const EdgeInsets.all(32),
            itemCount: activity.length,
            itemBuilder: (context, index) {
              final user = activity[index];
              final isUserMap = user is Map;
              final List<dynamic> allTasks = (isUserMap ? user['tasks'] : null) ?? [];
              // FILTER: Hide both completed AND submitted tasks from "Active" Explorer
              final tasks = allTasks.where((t) => 
                t['status'] != 'completed' && 
                t['status'] != 'submitted' &&
                t['status'] != 'rejected' // Usually rejected means it's back to pending anyway
              ).toList();

              if (tasks.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    iconColor: AppTheme.primaryCoral,
                    collapsedIconColor: AppTheme.textMuted,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                      child: Text(
                        (isUserMap ? (user['name']?.toString() ?? 'U') : 'U')[0].toUpperCase(), 
                        style: const TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold)
                      ),
                    ),
                    title: Text(
                      (isUserMap ? user['name'] : null)?.toString() ?? 'Unknown Operator', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16)
                    ),
                    subtitle: Text(
                      '@${(isUserMap ? user['username'] : null) ?? 'operator'} • ${tasks.length} Active Tasks', 
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)
                    ),
                    children: tasks.map((task) => Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          (task is Map ? task['title'] : null)?.toString() ?? 'Untitled Task', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)
                        ),
                        subtitle: Text(
                          'Status: ${(task is Map ? task['status'] : 'pending').toString().toUpperCase()}', 
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)
                        ),
                        trailing: _buildStatusBadge((task is Map ? task['status'] : 'pending').toString()),
                      ),
                    )).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == 'submitted') color = AppTheme.successGreen;
    else if (status == 'in-progress' || status == 'in_progress') color = AppTheme.secondaryBlue;
    else if (status == 'rejected') color = AppTheme.primaryCoral;
    else color = AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

