import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_provider.dart';
import '../../state/task_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/update_service.dart';
import '../../data/services/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:task_manager/main.dart' show setupPushNotifications;

import 'task_list_screen.dart';
import 'archive_screen.dart';
import 'team_activity_screen.dart';
import 'team_management_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_review_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? user;

  const HomeScreen({super.key, this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    // Start update check, notification sync, and FCM setup on boot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _syncUnreadCounts();
      _setupPushNotifications();
    });
  }

  /// Set up FCM push notifications after login
  Future<void> _setupPushNotifications() async {
    try {
      await setupPushNotifications();
    } catch (e) {
      // Non-critical — app works without push notifications
      debugPrint('⚠️ Push notification setup skipped: $e');
    }
  }

  /// Catch-up Sync: Fetch historical unread counts from the server
  Future<void> _syncUnreadCounts() async {
    try {
      final response = await ApiClient().getUnreadCounts();
      final counts = response.data['data'] as Map<String, dynamic>;
      
      if (mounted) {
        if (counts.isEmpty) {
          // Edge case: No unread messages, clear all badges
          ref.read(unreadCountsProvider.notifier).clearAll();
          print('✅ Notification Catch-up: No unread messages');
        } else {
          final typedCounts = counts.map((key, value) => MapEntry(key, (value as num).toInt()));
          ref.read(unreadCountsProvider.notifier).initialize(typedCounts);
          print('✅ Notification Catch-up: ${counts.length} tasks with unread messages');
        }
      }
    } catch (e) {
      print('⚠️ Notification sync skipped: $e');
      // Edge case: On error, don't clear existing badges, just log
    }
  }

  /// Manual refresh of unread counts (for pull-to-refresh)
  Future<void> _refreshUnreadCounts() async {
    await _syncUnreadCounts();
  }


  Future<void> _checkForUpdates() async {
    // TEMPORARY: Allow update check in browser for demo/verification purposes
    // if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final updateData = await UpdateService.checkUpdate();
    if (updateData['updateAvailable'] == true && mounted) {
      _showUpdateDialog(updateData);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> data) {
    double progress = 0;
    String status = "Ready to update";
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: AppTheme.primaryCoral),
              const SizedBox(width: 12),
              const Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${data['version'] ?? 'New'} is ready for download.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  data['releaseNotes']?.toString() ?? 'Bug fixes and performance improvements.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              if (isDownloading) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress / 100, color: AppTheme.primaryCoral, backgroundColor: AppTheme.borderLight),
                const SizedBox(height: 8),
                Center(child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ],
          ),
          actions: [
            if (!isDownloading)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('LATER', style: TextStyle(color: AppTheme.textMuted))),
            if (!isDownloading)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  final downloadUrl = (defaultTargetPlatform == TargetPlatform.android) 
                      ? data['androidUrl']?.toString() 
                      : data['desktopUrl']?.toString();
                  
                  if (downloadUrl == null || downloadUrl.isEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download URL not available'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  setDialogState(() => isDownloading = true);
                  UpdateService.performUpdate(downloadUrl, onProgress: (statusText, pctValue) {
                    setDialogState(() {
                      status = statusText;
                      progress = pctValue;
                    });
                  });
                },
                child: const Text('UPDATE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Initialize Real-time Synchronization Hub ---
    ref.watch(socketServiceProvider);

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final role = widget.user?['role']?.toString().toLowerCase() ?? 'member';
    final isAdmin = role == 'admin';
    
    // Screens loaded into the IndexedStack
    final List<Widget> screens = [
      _DashboardOverview(user: widget.user),
      const TaskListScreen(),
      const TeamActivityScreen(),
      if (isAdmin) const AdminReviewScreen(),
      if (isAdmin) const AdminDashboardScreen(),
      if (isAdmin) const TeamManagementScreen(),
      const ArchiveScreen(), 
      const SettingsScreen(),
    ];

    // Sidebar items corresponding to screens
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.list_alt_rounded, 'label': isAdmin ? 'Task Control' : 'My Tasks'},
      {'icon': Icons.explore_rounded, 'label': 'Activity'},
      if (isAdmin) {'icon': Icons.fact_check_rounded, 'label': 'Reviews'},
      if (isAdmin) {'icon': Icons.query_stats_rounded, 'label': 'Analytics'},
      if (isAdmin) {'icon': Icons.group_add_rounded, 'label': 'Organization'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Task Archive'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    // Building the Sidebar component
    Widget sidebar = Container(
      width: 250,
      color: AppTheme.sidebarDark,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // --- Branding ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.rocket_launch, color: AppTheme.primaryCoral, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'INNO\nTECH HUB',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 16, 
                      height: 1.1,
                      letterSpacing: 1
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          
          // --- Profile Summary ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.surfaceWhite.withValues(alpha: 0.1),
                  child: Text(
                    ((widget.user is Map) ? (widget.user!['name']?.toString() ?? 'O') : 'O')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (widget.user is Map) ? (widget.user!['name']?.toString() ?? 'Operator') : 'Operator',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${(widget.user is Map) ? (widget.user!['username']?.toString() ?? 'operator') : 'operator'}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- Menu Navigation ---
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final unreadCounts = ref.watch(unreadCountsProvider);
                final totalUnread = unreadCounts.values.fold(0, (sum, count) => sum + count);

                return ListView.builder(
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isSelected = _selectedIndex == index;
                    final isTasksItem = item['label'].toString() == 'Task Control' || item['label'].toString() == 'My Tasks';
                    final displayCount = isTasksItem ? totalUnread : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            if (!isDesktop) Navigator.pop(context); // Close mobile drawer automatically
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.surfaceWhite.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(left: BorderSide(color: isSelected ? AppTheme.primaryCoral : Colors.transparent, width: 4)),
                            ),
                            child: Row(
                              children: [
                                Icon(item['icon'], color: isSelected ? AppTheme.primaryCoral : Colors.white.withValues(alpha: 0.5), size: 22),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item['label'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (displayCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryCoral,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      displayCount > 99 ? '99+' : displayCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- Logout Action ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: InkWell(
              onTap: () => ref.read(authNotifierProvider.notifier).logout(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.5), size: 22),
                    const SizedBox(width: 16),
                    Text('Logout', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Render Shell Layout based on constraints
    Widget content;
    if (isDesktop) {
      content = Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Row(
          children: [
            sidebar,
            Expanded(child: IndexedStack(index: _selectedIndex, children: screens)),
          ],
        ),
      );
    } else {
      content = Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(navItems[_selectedIndex]['label']),
          centerTitle: true,
          elevation: 0,
        ),
        drawer: Drawer(child: sidebar),
        body: IndexedStack(index: _selectedIndex, children: screens),
      );
    }

    // Wrap with PopScope to prevent accidental exit on mobile/web back
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        final maxWait = const Duration(seconds: 2);
        final isWarningStillActive = _lastPressedAt != null && now.difference(_lastPressedAt!) < maxWait;

        if (!isWarningStillActive) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.sidebarDark,
              behavior: SnackBarBehavior.floating,
              duration: maxWait,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          // Explicitly exit the app
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: content,
    );
  }
}

class _DashboardOverview extends ConsumerStatefulWidget {
  final Map<String, dynamic>? user;
  const _DashboardOverview({required this.user});

  @override
  ConsumerState<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends ConsumerState<_DashboardOverview> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tasksProvider.notifier).loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final tasks = tasksState.tasks;

    final user = widget.user;
    final name = (user is Map) ? (user!['name']?.toString().split(' ')[0] ?? 'Operator') : 'Operator';

    // Stats calculations
    final total = tasks.length;
    final pending = tasks.where((t) => t.status == 'pending').length;
    final inProgress = tasks.where((t) => t.status == 'in-progress').length; // backend uses hyphen
    final completed = tasks.where((t) => t.status == 'completed').length;

    final pendingPct = total == 0 ? 0.0 : pending / total;
    final inProgressPct = total == 0 ? 0.0 : inProgress / total;
    final completedPct = total == 0 ? 0.0 : completed / total;

    return Container(
      color: AppTheme.backgroundLight,
      child: tasksState.isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $name 👋',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 32),
            
            // Main Content Row (Responsive)
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Mobile/Tablet stacked
                return Column(
                  children: [
                    _buildTaskStatusCard(completedPct, inProgressPct, pendingPct),
                    const SizedBox(height: 24),
                    _buildRecentTasksSection(tasks),
                  ],
                );
              }
              // Desktop Row
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Expanded(
                     flex: 5,
                     child: _buildRecentTasksSection(tasks),
                   ),
                   const SizedBox(width: 32),
                   Expanded(
                     flex: 3,
                     child: _buildTaskStatusCard(completedPct, inProgressPct, pendingPct),
                   ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusCard(double completed, double inProgress, double pending) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Task Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusRing('Completed', completed, AppTheme.successGreen),
              _buildStatusRing('In Progress', inProgress, AppTheme.secondaryBlue),
              _buildStatusRing('Pending', pending, AppTheme.primaryCoral),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusRing(String label, double pct, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                color: color.withValues(alpha: 0.15),
              ),
              CircularProgressIndicator(
                value: pct,
                strokeWidth: 8,
                color: color,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _buildRecentTasksSection(List<dynamic> tasks) {
    final recentTasks = tasks.where((t) => t.status != 'completed').take(3).toList();
    final role = widget.user?['role']?.toString().toLowerCase() ?? 'member';
    final isAdmin = role == 'admin' || role == 'super_admin';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vital Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              if (isAdmin)
                TextButton(
                  onPressed: () {
                    // Switch to Task Control tab and push Detail
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskListScreen()));
                  }, 
                  child: const Text('+ Add task', style: TextStyle(color: AppTheme.primaryCoral))
                )
            ],
          ),
          const SizedBox(height: 16),
          if (recentTasks.isEmpty)
             const Padding(
               padding: EdgeInsets.all(24.0),
               child: Center(child: Text('No pending tasks!', style: TextStyle(color: AppTheme.textMuted))),
             ),
          ...recentTasks.map((t) => _buildRecentTaskCard(t)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentTaskCard(dynamic task) {
    final isUrgent = task.priority == 'high' || task.priority == 'extreme';
    final accentColor = isUrgent ? AppTheme.primaryCoral : AppTheme.secondaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            width: 12, 
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark))),
                    const Icon(Icons.more_horiz, color: AppTheme.textMuted, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description ?? 'No description provided.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Priority: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Text(task.priority?.toUpperCase() ?? 'MODERATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor)),
                    const SizedBox(width: 16),
                    const Text('Status: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Text(task.status?.toUpperCase() ?? 'PENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

