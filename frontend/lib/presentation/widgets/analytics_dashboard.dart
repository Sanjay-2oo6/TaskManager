import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';

class AnalyticsDashboard extends ConsumerWidget {
  final List<Task> tasks;

  const AnalyticsDashboard({required this.tasks, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _calculateStats(tasks);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tasks',
                  stats['total'].toString(),
                  AppTheme.secondaryBlue,
                  Icons.task_alt_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  stats['completed'].toString(),
                  AppTheme.successGreen,
                  Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  stats['inProgress'].toString(),
                  Colors.orange,
                  Icons.hourglass_bottom_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  stats['pending'].toString(),
                  AppTheme.primaryCoral,
                  Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Completion Rate
          _buildProgressCard(
            'Completion Rate',
            stats['completionRate'],
            AppTheme.successGreen,
          ),
          const SizedBox(height: 24),

          // Overdue Tasks
          _buildOverdueCard(stats['overdue']),
          const SizedBox(height: 24),

          // Priority Distribution
          _buildPriorityDistribution(stats['byPriority']),
          const SizedBox(height: 24),

          // Status Breakdown
          _buildStatusBreakdown(stats['byStatus']),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String label, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCard(int overdueCount) {
    final isGood = overdueCount == 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGood
            ? AppTheme.successGreen.withValues(alpha: 0.1)
            : AppTheme.primaryCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGood
              ? AppTheme.successGreen.withValues(alpha: 0.3)
              : AppTheme.primaryCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: isGood ? AppTheme.successGreen : AppTheme.primaryCoral,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overdue Tasks',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isGood ? 'All tasks on track' : '$overdueCount tasks',
                style: TextStyle(
                  color: isGood ? AppTheme.successGreen : AppTheme.primaryCoral,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDistribution(Map<String, int> byPriority) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Distribution',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...['high', 'medium', 'low'].map((priority) {
            final count = byPriority[priority] ?? 0;
            final color = _getPriorityColor(priority);
            final total = byPriority.values.fold<int>(0, (a, b) => a + b);
            final percentage = total > 0 ? count / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(Map<String, int> byStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Breakdown',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: byStatus.entries.map((entry) {
              return Chip(
                label: Text('${entry.key}: ${entry.value}'),
                backgroundColor: _getStatusColor(entry.key).withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _getStatusColor(entry.key),
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'extreme':
        return AppTheme.primaryCoral;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.successGreen;
      default:
        return AppTheme.secondaryBlue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successGreen;
      case 'submitted':
        return AppTheme.secondaryBlue;
      case 'pending':
      case 'in_progress':
        return Colors.orange;
      case 'rejected':
        return AppTheme.primaryCoral;
      case 'waiting':
        return Colors.grey;
      default:
        return AppTheme.textMuted;
    }
  }

  Map<String, dynamic> _calculateStats(List<Task> tasks) {
    int completed = 0;
    int inProgress = 0;
    int pending = 0;
    int overdue = 0;
    final Map<String, int> byPriority = {};
    final Map<String, int> byStatus = {};

    final now = DateTime.now();

    for (final task in tasks) {
      // Count by status
      byStatus[task.status] = (byStatus[task.status] ?? 0) + 1;

      // Count by priority
      byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;

      // Count by state
      switch (task.status) {
        case 'completed':
          completed++;
          break;
        case 'submitted':
        case 'in_progress':
        case 'in-progress':
          inProgress++;
          break;
        case 'pending':
        case 'rejected':
        case 'waiting':
          pending++;
          break;
      }

      // Count overdue
      if (task.dueDate.isBefore(now) && task.status != 'completed') {
        overdue++;
      }
    }

    final total = tasks.length;
    final completionRate = total > 0 ? completed / total : 0.0;

    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'pending': pending,
      'overdue': overdue,
      'completionRate': completionRate,
      'byPriority': byPriority,
      'byStatus': byStatus,
    };
  }
}
