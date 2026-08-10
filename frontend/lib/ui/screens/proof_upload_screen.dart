import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/proof_repository.dart';
import '../../data/services/sync_service.dart';
import '../../presentation/widgets/offline_banner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../state/task_providers.dart';
import 'package:url_launcher/url_launcher.dart';

final syncServiceProvider = Provider((ref) => SyncService());
final proofRepositoryProvider = Provider((ref) => ProofRepository(ref.watch(syncServiceProvider)));

class ProofUploadScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String userId;

  const ProofUploadScreen({super.key, required this.taskId, required this.userId});

  @override
  ConsumerState<ProofUploadScreen> createState() => _ProofUploadScreenState();
}

class _ProofUploadScreenState extends ConsumerState<ProofUploadScreen> {
  List<PlatformFile> _beforeFiles = [];
  List<PlatformFile> _afterFiles = [];
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickFiles(bool isBefore) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true, 
      withData: true 
    );
    if (result != null) {
      setState(() {
        if (isBefore) {
          _beforeFiles.addAll(result.files);
        } else {
          _afterFiles.addAll(result.files);
        }
      });
    }
  }

  Future<void> _submitProof() async {
    // Guard: require at least one file
    if (_beforeFiles.isEmpty && _afterFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least one before or after photo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(proofRepositoryProvider).submitProof(
        taskId: widget.taskId,
        userId: widget.userId,
        organizationId: ref.read(authNotifierProvider).user?['organizationId'] ?? '',
        beforeFiles: _beforeFiles,
        afterFiles: _afterFiles,
        description: _descriptionController.text,
      );

      if (mounted) {
        setState(() {
          _beforeFiles = [];
          _afterFiles = [];
          _descriptionController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission sent successfully!'), backgroundColor: AppTheme.successGreen),
        );
        Navigator.pop(context); // Close Upload Screen
        Navigator.pop(context); // Close Detail Screen
      }
    } catch (e) {
      if (mounted) {
        // Clean error message
        String msg = 'Submission failed. Please try again.';
        try {
          final dynamic err = e;
          final serverMsg = err?.response?.data?['message'];
          if (serverMsg != null) msg = serverMsg.toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.primaryCoral),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Submit Work Proof', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: _DropzoneSection(
                          title: 'Before Photos',
                          subtitle: 'Drag & drop or browse',
                          files: _beforeFiles,
                          onAdd: () => _pickFiles(true),
                          onRemove: (file) => setState(() => _beforeFiles.remove(file)),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _DropzoneSection(
                          title: 'After Photos',
                          subtitle: 'Provide proof of execution',
                          files: _afterFiles,
                          onAdd: () => _pickFiles(false),
                          onRemove: (file) => setState(() => _afterFiles.remove(file)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Consumer(
                    builder: (context, ref, child) {
                      final taskState = ref.watch(taskDetailProvider(widget.taskId));
                      final task = taskState.task;
                      if (task != null && task.adminFiles != null && task.adminFiles!.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin Reference Files', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)),
                            const SizedBox(height: 12),
                            ...List.generate(task.adminFiles!.length, (index) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: const Icon(Icons.attach_file_rounded, color: AppTheme.secondaryBlue),
                                  title: Text(task.adminFileNames?[index] ?? 'Attachment ${index + 1}', style: const TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                                  trailing: const Icon(Icons.file_download_outlined, color: AppTheme.textMuted),
                                  onTap: () {
                                    final file = task.adminFiles![index];
                                    if (file == 'null' || file.isEmpty) return;
                                    final url = file.startsWith('http') ? file : '${AppConstants.serverUrl}/$file';
                                    launchUrl(Uri.parse(url));
                                  },
                                ),
                              ),
                            )),
                            const SizedBox(height: 32),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const Text('Submission Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'Add optional comments about the execution...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceWhite,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryCoral, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitProof,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCoral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SUBMIT COMPLETED WORK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropzoneSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PlatformFile> files;
  final VoidCallback onAdd;
  final Function(PlatformFile) onRemove;

  const _DropzoneSection({
    required this.title,
    required this.subtitle,
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)),
        const SizedBox(height: 12),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.secondaryBlue.withValues(alpha: 0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.secondaryBlue, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Click to upload', style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...files.map((file) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.image_rounded, color: AppTheme.secondaryBlue, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                  onPressed: () => onRemove(file),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          )),
        ]
      ],
    );
  }
}
