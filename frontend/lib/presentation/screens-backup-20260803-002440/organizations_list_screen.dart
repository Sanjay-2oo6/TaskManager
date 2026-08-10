import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';

/// Screen for viewing all organizations (Super Admin only)
class OrganizationsListScreen extends ConsumerStatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  ConsumerState<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends ConsumerState<OrganizationsListScreen> {
  late Future<Response> _organizationsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  void _loadOrganizations() {
    setState(() {
      _organizationsFuture = ApiClient().getAllOrganizations();
    });
  }

  void _refreshList() {
    _loadOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'All Organizations',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search organizations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Organizations list
          Expanded(
            child: FutureBuilder<Response>(
              future: _organizationsFuture,
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
                          'Failed to load organizations',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrganizations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No organizations found'),
                  );
                }

                // Extract organizations from response
                final response = snapshot.data!;
                final responseBody = response.data as Map<String, dynamic>? ?? {};
                final orgsData = (responseBody['data'] as List?) ?? [];

                if (orgsData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No organizations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter organizations
                final filtered = orgsData.where((org) {
                  final orgMap = org as Map<String, dynamic>;
                  final name = (orgMap['name'] as String? ?? '').toLowerCase();
                  final slug = (orgMap['slug'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery) || slug.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final org = filtered[index] as Map<String, dynamic>;
                    return _OrganizationCard(
                      organization: org,
                      onRefresh: _refreshList,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Organization card widget with Edit/Delete/Toggle actions
class _OrganizationCard extends StatefulWidget {
  final Map<String, dynamic> organization;
  final VoidCallback onRefresh;

  const _OrganizationCard({
    required this.organization,
    required this.onRefresh,
  });

  @override
  State<_OrganizationCard> createState() => _OrganizationCardState();
}

class _OrganizationCardState extends State<_OrganizationCard> {
  late Map<String, dynamic> _organization;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _organization = Map.from(widget.organization);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: _organization['name'] as String?);
    final memberLimitController = TextEditingController(
      text: (_organization['memberLimit'] as int? ?? 10).toString(),
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Organization'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organization Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Member Limit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: memberLimitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                nameController.dispose();
                memberLimitController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await ApiClient().updateOrganization(
                          _organization['_id'] as String,
                          {
                            'name': nameController.text.trim(),
                            'memberLimit': int.tryParse(memberLimitController.text) ?? 10,
                          },
                        );
                        if (mounted) {
                          nameController.dispose();
                          memberLimitController.dispose();
                          Navigator.pop(context);
                          setState(() {
                            _organization['name'] = nameController.text.trim();
                            _organization['memberLimit'] =
                                int.tryParse(memberLimitController.text) ?? 10;
                          });
                          widget.onRefresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Organization updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${ApiClient.friendlyError(e)}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Ensure disposal even if dialog dismissed by back button
      nameController.dispose();
      memberLimitController.dispose();
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    final name = _organization['name'] as String? ?? 'Unknown';
    final slug = _organization['slug'] as String? ?? '';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Organization?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "$name" (@$slug)?',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This will delete the organization and all associated data.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await ApiClient().deleteOrganization(
                          _organization['_id'] as String,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          widget.onRefresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Organization deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${ApiClient.friendlyError(e)}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient().toggleOrganization(_organization['_id'] as String);
      if (mounted) {
        setState(() {
          _organization['isActive'] = !(_organization['isActive'] as bool? ?? false);
        });
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Organization ${(_organization['isActive'] as bool?) ?? false ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${ApiClient.friendlyError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _organization['name'] as String? ?? 'Unknown';
    final slug = _organization['slug'] as String? ?? '';
    final isActive = _organization['isActive'] as bool? ?? false;
    final memberCount = _organization['memberCount'] as int? ?? 0;
    final memberLimit = _organization['memberLimit'] as int? ?? -1;
    final createdAt = _organization['createdAt'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppTheme.accentPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and slug
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$slug',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberLimit == -1
                            ? '$memberCount / Unlimited'
                            : '$memberCount / $memberLimit',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Created',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle status button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleStatus,
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.toggle_on),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _showEditDialog(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
