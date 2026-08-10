import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';

/// Screen for viewing platform statistics (Super Admin only)
class PlatformStatisticsScreen extends ConsumerStatefulWidget {
  const PlatformStatisticsScreen({super.key});

  @override
  ConsumerState<PlatformStatisticsScreen> createState() =>
      _PlatformStatisticsScreenState();
}

class _PlatformStatisticsScreenState extends ConsumerState<PlatformStatisticsScreen> {
  late Future<Response> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = ApiClient().getPlatformStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'Platform Statistics',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Response>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.primaryCoral,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load statistics',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStats,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No statistics available'));
          }

          // Extract stats from response - same pattern as organizations_list_screen.dart
          final response = snapshot.data!;
          final responseBody = response.data as Map<String, dynamic>? ?? {};
          final stats = (responseBody['data'] as Map<String, dynamic>?) ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.analytics_rounded,
                        color: AppTheme.accentPurple,
                        size: 32,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Platform Metrics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'View platform-wide statistics and metrics',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Organizations section
                _buildSection(
                  title: 'Organizations',
                  icon: Icons.business_rounded,
                  stats: [
                    _buildStat(
                      'Total',
                      (stats['organizations'] as Map?)?['total']?.toString() ?? '0',
                      AppTheme.accentPurple,
                    ),
                    _buildStat(
                      'Active',
                      (stats['organizations'] as Map?)?['active']?.toString() ?? '0',
                      Colors.green,
                    ),
                    _buildStat(
                      'Inactive',
                      (stats['organizations'] as Map?)?['inactive']?.toString() ?? '0',
                      Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Users section
                _buildSection(
                  title: 'Users',
                  icon: Icons.people_rounded,
                  stats: [
                    _buildStat(
                      'Total Users',
                      (stats['users'] as Map?)?['total']?.toString() ?? '0',
                      AppTheme.secondaryBlue,
                    ),
                    _buildStat(
                      'Admins',
                      (stats['users'] as Map?)?['admins']?.toString() ?? '0',
                      Colors.orange,
                    ),
                    _buildStat(
                      'Members',
                      (stats['users'] as Map?)?['members']?.toString() ?? '0',
                      Colors.teal,
                    ),
                    _buildStat(
                      'Super Admins',
                      (stats['users'] as Map?)?['superAdmins']?.toString() ?? '0',
                      AppTheme.accentPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Platform section
                _buildSection(
                  title: 'Platform Activity',
                  icon: Icons.trending_up_rounded,
                  stats: [
                    _buildStat(
                      'Total Tasks',
                      (stats['platform'] as Map?)?['totalTasks']?.toString() ?? '0',
                      AppTheme.primaryCoral,
                    ),
                    _buildStat(
                      'Total Submissions',
                      (stats['platform'] as Map?)?['totalSubmissions']?.toString() ?? '0',
                      Colors.indigo,
                    ),
                    _buildStat(
                      'Avg Tasks/Org',
                      ((stats['platform'] as Map?)?['averageTasksPerOrg'] as num?)?.toStringAsFixed(1) ?? '0',
                      Colors.purple,
                    ),
                    _buildStat(
                      'Avg Users/Org',
                      ((stats['platform'] as Map?)?['averageUsersPerOrg'] as num?)?.toStringAsFixed(1) ?? '0',
                      Colors.pinkAccent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> stats,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.textDark, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: stats,
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
