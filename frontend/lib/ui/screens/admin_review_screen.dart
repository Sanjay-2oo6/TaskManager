import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../state/task_providers.dart';
import '../../state/submission_providers.dart';

class AdminReviewScreen extends ConsumerWidget {
  const AdminReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(pendingSubmissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Submission Control', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: Column(
        children: [
          Expanded(
            child: submissionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral)),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.primaryCoral, size: 48),
                    const SizedBox(height: 12),
                    const Text('Failed to load submissions', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Check your connection and try again', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(pendingSubmissionsProvider),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (submissions) => RefreshIndicator(
                onRefresh: () => ref.refresh(pendingSubmissionsProvider.future),
                color: AppTheme.primaryCoral,
                backgroundColor: AppTheme.surfaceWhite,
                child: submissions.isEmpty
                    ? const Center(child: Text('No submissions awaiting review', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(32),
                        itemCount: submissions.length,
                        itemBuilder: (context, index) =>
                            _ReviewCard(submission: submissions[index]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final SubmissionReview submission;
  const _ReviewCard({required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(24),
            title: Text(submission.taskTitle.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16)),
            subtitle: Text('Submitted By: ${submission.employeeName}', 
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          
          _buildFileSection('BEFORE OPERATIONS', submission.beforeFilesUrls, submission.beforeFileNames),
          const SizedBox(height: 16),
          _buildFileSection('AFTER COMPLETION', submission.afterFilesUrls, submission.afterFileNames),
          
          if (submission.description != null && submission.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Notes: ${submission.description}', 
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.5)),
            ),
            
          const Divider(color: AppTheme.borderLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _updateStatus(context, ref, 'rejected'),
                  child: const Text('REJECT', style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, ref, 'approved'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('AUTHORIZE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection(String title, List<String> urls, List<String> names) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1)),
        ),
        _FileList(urls: urls, fileNames: names),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    String? feedback;

    if (status == 'rejected') {
      feedback = await _showRejectionDialog(context);
      if (feedback == null || feedback.trim().isEmpty) return; // Cancelled or empty
    }

    try {
      final Map<String, dynamic> body = {
        'status': status,
      };
      
      // Only include feedback if it's provided and not empty
      if (feedback != null && feedback.trim().isNotEmpty) {
        body['adminFeedback'] = feedback.trim();
      }
      
      final response = await ApiClient().updateSubmissionStatus(
        submission.id, 
        status, 
        feedback: feedback?.trim(),
      );
      
      if (response.statusCode == 200 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Submission $status!'),
              backgroundColor: status == 'approved' ? AppTheme.successGreen : AppTheme.primaryCoral),
        );
        // ✅ FIX #1 (PHASE 1): Invalidate both submissions AND tasks + task detail
        // When approval/rejection happens, the backend emits task-updated event,
        // but we also invalidate here to ensure immediate UI refresh for members viewing the task
        ref.invalidate(pendingSubmissionsProvider);
        ref.invalidate(tasksProvider);
        if (submission.taskId.isNotEmpty) {
          ref.invalidate(taskDetailProvider(submission.taskId));
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Extract clean message, don't leak Dio internals
        String msg = 'Failed to update submission. Please try again.';
        try {
          final dynamic err = e;
          final serverMsg = err?.response?.data?['message'];
          if (serverMsg != null) msg = serverMsg.toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.primaryCoral),
        );
      }
    }
  }

  Future<String?> _showRejectionDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejection Reason', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please explain why this submission is being rejected so the worker can correct it.', 
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Image too blurry, or missing before-photo...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('CONFIRM REJECTION'),
          ),
        ],
      ),
    );
  }
}


class _FileList extends StatelessWidget {
  final List<String> urls;
  final List<String> fileNames;
  const _FileList({required this.urls, required this.fileNames});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text('No evidence attached.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      );
    }
    return Column(
      children: List.generate(urls.length, (index) {
        final url = urls[index];
        final name = (fileNames.length > index) ? fileNames[index] : 'Download File';
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: const Icon(Icons.image_outlined, color: AppTheme.secondaryBlue, size: 20),
          title: Text(name, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.file_download_outlined, color: AppTheme.textMuted, size: 20),
          onTap: () async {
            final uri = Uri.parse(url);
            try {
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open file'), backgroundColor: Colors.red),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid file URL'), backgroundColor: Colors.red),
                );
              }
            }
          },
        );
      }),
    );
  }
}
