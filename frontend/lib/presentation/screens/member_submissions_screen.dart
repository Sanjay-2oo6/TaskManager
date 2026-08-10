import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';

/// Screen showing member's own submissions (pending, approved, rejected)
class MemberSubmissionsScreen extends ConsumerStatefulWidget {
  const MemberSubmissionsScreen({super.key});

  @override
  ConsumerState<MemberSubmissionsScreen> createState() => _MemberSubmissionsScreenState();
}

class _MemberSubmissionsScreenState extends ConsumerState<MemberSubmissionsScreen> {
  List<dynamic> _submissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      final role = authState.user?['role']?.toString().toLowerCase() ?? 'member';
      
      // Members fetch their own submissions, admins fetch all
      late final response;
      if (role == 'admin' || role == 'super_admin') {
        response = await ApiClient().getAllSubmissions();
      } else {
        // Members fetch their own submissions history
        response = await ApiClient().getMySubmissions();
      }
      
      if (response.statusCode == 200) {
        setState(() {
          _submissions = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load submissions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.primaryCoral;
      case 'pending':
        return Colors.orange;
      default:
        return AppTheme.textMuted;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: AppTheme.successGreen);
      case 'rejected':
        return const Icon(Icons.cancel, color: AppTheme.primaryCoral);
      case 'pending':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: AppTheme.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?['_id'] ?? authState.user?['id'];

    // Filter submissions to show only current user's submissions
    final mySubmissions = _submissions.where((sub) {
      final empId = sub['employee']?['_id'] ?? sub['employee'];
      return empId == userId;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Submissions', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.primaryCoral),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubmissions,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : mySubmissions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
                          SizedBox(height: 16),
                          Text('No submissions yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Complete tasks and submit your work to see them here', 
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12), 
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSubmissions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: mySubmissions.length,
                        itemBuilder: (context, index) {
                          final submission = mySubmissions[index];
                          final status = submission['status'] ?? 'pending';
                          final taskTitle = submission['task']?['title'] ?? submission['taskTitle'] ?? 'Unknown Task';
                          final createdAt = submission['createdAt'] != null
                              ? DateTime.parse(submission['createdAt'])
                              : null;
                          final feedback = submission['adminFeedback'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _getStatusIcon(status),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          taskTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textDark,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _getStatusColor(status)),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (createdAt != null)
                                        Text(
                                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (feedback != null && feedback.toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(color: AppTheme.borderLight),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.feedback_outlined, size: 16, color: AppTheme.secondaryBlue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Admin Feedback:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: AppTheme.secondaryBlue,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                feedback.toString(),
                                                style: const TextStyle(
                                                  color: AppTheme.textDark,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (submission['description'] != null && submission['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Your Notes: ${submission['description']}',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
