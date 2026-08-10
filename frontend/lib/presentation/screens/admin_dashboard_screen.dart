import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'task_list_screen.dart';
import 'analytics_screen.dart';
import '../../ui/screens/admin_review_screen.dart';
import 'team_management_screen.dart';

/// Admin dashboard with full task control and team management
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?['name'] ?? 'Admin';
    final userEmail = authState.user?['email'] ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Admin screens
    final List<Widget> screens = [
      const TaskListScreen(),
      const AdminReviewScreen(),
      const TeamManagementScreen(),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    // Admin navigation items
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.list_alt_rounded, 'label': 'Task Control'},
      {'icon': Icons.fact_check_rounded, 'label': 'Submissions'},
      {'icon': Icons.group_add_rounded, 'label': 'Team Management'},
      {'icon': Icons.analytics_rounded, 'label': 'Analytics'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    // Build sidebar widget
    Widget buildSidebar() {
      return Material(
        color: AppTheme.sidebarDark,
        child: SizedBox(
          width: 280,
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
                        color: AppTheme.primaryCoral.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppTheme.primaryCoral,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin\nDashboard',
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
                      selectedTileColor: AppTheme.primaryCoral.withValues(alpha: 0.2),
                      leading: Icon(
                        item['icon'],
                        color: isSelected ? AppTheme.primaryCoral : Colors.white70,
                      ),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryCoral : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          if (isMobile) {
                            Navigator.of(context).pop(); // Close drawer on mobile
                          }
                        });
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
      );
    }

    if (isMobile) {
      // Mobile: Use drawer for sidebar
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.sidebarDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            navItems[_selectedIndex]['label'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          centerTitle: false,
        ),
        drawer: Drawer(
          backgroundColor: AppTheme.sidebarDark,
          child: buildSidebar(),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      );
    } else {
      // Desktop/Tablet: Use fixed sidebar
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Row(
          children: [
            buildSidebar(),
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
}
