import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'settings_screen.dart';
import 'organization_creation_screen.dart';
import 'organizations_list_screen.dart';
import 'platform_statistics_screen.dart';

/// Super Admin dashboard for organization management
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?['name'] ?? 'Super Admin';
    final userEmail = authState.user?['email'] ?? '';

    // Super Admin screens - pass context explicitly
    final List<Widget> screens = [
      SuperAdminOrganizationScreen(parentContext: context),
      const SettingsScreen(),
    ];

    // Super Admin navigation items
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.business_rounded, 'label': 'Organizations'},
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
                          color: AppTheme.accentPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.accentPurple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Super Admin\nPortal',
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
                        selectedTileColor: AppTheme.accentPurple.withValues(alpha: 0.2),
                        leading: Icon(
                          item['icon'],
                          color: isSelected ? AppTheme.accentPurple : Colors.white70,
                        ),
                        title: Text(
                          item['label'],
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentPurple : Colors.white70,
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

/// Organization management screen - FIXED VERSION
class SuperAdminOrganizationScreen extends StatelessWidget {
  final BuildContext parentContext;

  const SuperAdminOrganizationScreen({
    super.key,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'Organization Management',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_rounded, color: AppTheme.primaryCoral, size: 32),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Organization Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create, manage, and monitor all organizations on the platform',
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
              const Text(
                'Available Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.add_circle_outline,
                title: 'Create Organization',
                description: 'Create a new organization and assign admin',
                onTap: () => Navigator.of(parentContext).push(
                  MaterialPageRoute(
                    builder: (_) => const OrganizationCreationScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.list_rounded,
                title: 'View Organizations',
                description: 'View all organizations and their details',
                onTap: () => Navigator.of(parentContext).push(
                  MaterialPageRoute(
                    builder: (_) => const OrganizationsListScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.analytics_rounded,
                title: 'Platform Statistics',
                description: 'View platform-wide statistics and metrics',
                onTap: () => Navigator.of(parentContext).push(
                  MaterialPageRoute(
                    builder: (_) => const PlatformStatisticsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action card widget - FIXED with proper tap handling
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.surfaceWhite.withValues(alpha: 0.95)
                : AppTheme.surfaceWhite,
            border: Border.all(
              color: _isHovered
                  ? AppTheme.accentPurple.withValues(alpha: 0.6)
                  : AppTheme.borderLight,
              width: _isHovered ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? AppTheme.accentPurple : AppTheme.accentPurple,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isHovered ? AppTheme.accentPurple : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: _isHovered ? AppTheme.accentPurple : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
