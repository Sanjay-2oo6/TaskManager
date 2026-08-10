import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/task_providers.dart';
import '../widgets/analytics_dashboard.dart';
import '../widgets/loading_indicator.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ANALYTICS',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: tasksState.isLoading
          ? const Center(child: LoadingIndicator())
          : tasksState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.primaryCoral, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load analytics',
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tasksState.error.toString(),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.read(tasksProvider.notifier).loadTasks(),
                  color: AppTheme.primaryCoral,
                  child: AnalyticsDashboard(tasks: tasksState.tasks),
                ),
    );
  }
}
