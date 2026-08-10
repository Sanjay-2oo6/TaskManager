import 'package:flutter/material.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'member_creation_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().getUsers();
      setState(() {
        _users = response.data['data'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePassword(String userId, String name) async {
    final controller = TextEditingController();
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reset',
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SECURE RESET: $name', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textDark),
                  decoration: InputDecoration(
                    labelText: 'NEW ACCESS KEY',
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.backgroundLight,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryCoral, width: 2)),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, foregroundColor: Colors.white, elevation: 0),
                      child: const Text('UPDATE KEY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true || controller.text.length < 6) return;

    try {
      await ApiClient().updateUserPassword(userId, controller.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Synchronized'), backgroundColor: AppTheme.successGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Error'), backgroundColor: AppTheme.primaryCoral));
    }
  }

  Future<void> _deleteUser(String userId, String name) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete',
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('TERMINATE ACCESS?', style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Text('Operator "$name" will be removed from active duties immediately.', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, foregroundColor: Colors.white, elevation: 0),
                      child: const Text('TERMINATE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient().deleteUser(userId);
      if (mounted) _fetchUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Internal Error'), backgroundColor: AppTheme.primaryCoral));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Organization Control', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(onPressed: _fetchUsers, icon: const Icon(Icons.refresh_rounded, color: AppTheme.textDark)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral))
          : ListView.builder(
              padding: const EdgeInsets.all(32),
              itemCount: _users.where((u) => u['role'] != 'super_admin').length,
              itemBuilder: (context, index) {
                // Filter out super_admin users from the list
                final filteredUsers = _users.where((u) => u['role'] != 'super_admin').toList();
                final user = filteredUsers[index];
                final userId = user['_id'];
                final name = user['name'] ?? 'Unknown';
                final username = user['username'] ?? '';
                final role = user['role']?.toString().toUpperCase() ?? 'WORKER';
                final isAdmin = role == 'ADMIN';
                final isOrgAdmin = user['isOrgAdmin'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isAdmin ? AppTheme.primaryCoral.withValues(alpha: 0.1) : AppTheme.secondaryBlue.withValues(alpha: 0.1),
                        child: Icon(isAdmin ? Icons.security_rounded : Icons.person_rounded, 
                          color: isAdmin ? AppTheme.primaryCoral : AppTheme.secondaryBlue, size: 20),
                      ),
                      title: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)),
                      subtitle: Text('@$username • $role', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.key_rounded, color: AppTheme.secondaryBlue, size: 20),
                            onPressed: () => _updatePassword(userId, name),
                          ),
                          // ✅ SECURITY FIX: Only show delete button if user is admin
                          if (isOrgAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.primaryCoral, size: 20),
                              onPressed: () => _deleteUser(userId, name),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'team_mgmt_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MemberCreationScreen()),
        ).then((_) => _fetchUsers()),
        label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: AppTheme.primaryCoral,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
