import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'task_list_screen.dart';
import 'settings_screen.dart';

/// Member dashboard with limited access (read-only tasks, submit work)
class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  ConsumerState<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?['name'] ?? 'Member';
    final userEmail = authState.user?['email'] ?? '';

    // Member screens
    final List<Widget> screens = [
      const TaskListScreen(showMyTasksOnly: true),
      const SettingsScreen(),
    ];

    // Member navigation items
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.assignment_rounded, 'label': 'My Tasks'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: AppTheme.sidebarDark,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.secondaryBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'My\nTasks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                // Navigation
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppTheme.secondaryBlue.withValues(alpha: 0.2),
                        leading: Icon(
                          item['icon'],
                          color: isSelected ? AppTheme.secondaryBlue : Colors.white70,
                        ),
                        title: Text(
                          item['label'],
                          style: TextStyle(
                            color: isSelected ? AppTheme.secondaryBlue : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedIndex = index);
                        },
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white24),
                // User info and logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).logout();
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }
}
