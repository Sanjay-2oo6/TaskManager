import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/task.dart';
import '../../state/task_providers.dart';
import '../../state/auth_provider.dart';
import '../widgets/loading_indicator.dart';
import '../../data/services/api_client.dart';
import '../../ui/screens/proof_upload_screen.dart';
import '../../data/models/message.dart';
import '../../state/message_providers.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String? taskId; 
  final String? parentTaskId; 

  const TaskDetailScreen({super.key, this.taskId, this.parentTaskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _chatScrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adminNoteController = TextEditingController();
  final _commentController = TextEditingController();

  List<dynamic> _users = [];
  bool _isLoadingUsers = true;
  List<String> _selectedUserIds = [];
  String _status = AppConstants.statusPending;
  String _priority = AppConstants.priorityMedium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isEditing = false;
  bool _isSaving = false;
  bool _formPopulated = false; // Guard: only populate form once from server data
  
  // Admin files
  List<PlatformFile> _newAdminFiles = [];
  List<String> _selectedDependencyIds = [];
  
  // Typing state
  Timer? _typingTimer;
  bool _isLocalTyping = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.taskId == null;
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
    
    // Set active task for suppression logic if we're on the chat tab initially
    if (widget.taskId != null && _tabController.index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeChatTaskIdProvider.notifier).state = widget.taskId;
      });
    }
    
    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(taskDetailProvider(widget.taskId!).notifier).loadTask(widget.taskId!);
        ref.read(socketServiceProvider).joinChat(widget.taskId!);
        
        // IMPORTANT: Clear badge immediately when task detail screen opens
        // This ensures the badge disappears as soon as user views the task
        _markTaskAsViewed();
      });
      // TAB SELECTION LOGIC
      _tabController.addListener(() {
        if (!mounted) return;
        if (_tabController.index == 1) {
          final currentUserId = ref.read(authNotifierProvider).user?['id'] ?? '';
          
          // REST call — persists to DB regardless of socket state
          _persistMarkRead(widget.taskId!);
          
          // Socket — for live read receipts to other users
          ref.read(socketServiceProvider).emitMarkRead(widget.taskId!, currentUserId);
          ref.read(unreadCountsProvider.notifier).clear(widget.taskId!);
          ref.read(activeChatTaskIdProvider.notifier).state = widget.taskId;

          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && _chatScrollController.hasClients) {
              _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          ref.read(activeChatTaskIdProvider.notifier).state = null;
        }
      });
    }
  }

  /// Mark task as viewed - clears the notification badge both locally and on the server
  void _markTaskAsViewed() {
    if (widget.taskId == null || !mounted) return;
    
    try {
      // 1. Clear the badge in the UI immediately (optimistic)
      ref.read(unreadCountsProvider.notifier).clear(widget.taskId!);
      
      // 2. Call the REST API directly — this is guaranteed to persist even if
      //    the socket hasn't connected yet or the user logs out right after
      _persistMarkRead(widget.taskId!);

      // 3. Also emit via socket so other users get live ✓✓ read receipts
      final currentUserId = ref.read(authNotifierProvider).user?['id'] ?? '';
      if (currentUserId.isNotEmpty) {
        ref.read(socketServiceProvider).emitMarkRead(widget.taskId!, currentUserId);
      }
      
      print('✅ Task ${widget.taskId} marked as viewed - badge cleared');
    } catch (e) {
      print('⚠️ Error marking task as viewed: $e');
    }
  }

  /// Fire-and-forget REST call to persist read state in the database.
  /// Uses async/await in an isolated function so errors don't propagate.
  /// Includes retry logic to ensure persistence.
  Future<void> _persistMarkRead(String taskId) async {
    int retries = 0;
    const maxRetries = 2;
    
    while (retries < maxRetries) {
      try {
        await ApiClient().markMessagesRead(taskId);
        print('✅ REST mark-read persisted for task: $taskId (attempt ${retries + 1}/$maxRetries)');
        return; // Success - exit
      } catch (e) {
        retries++;
        if (retries < maxRetries) {
          print('⚠️ REST mark-read failed (attempt $retries/$maxRetries), retrying...: $e');
          await Future.delayed(const Duration(milliseconds: 500)); // Brief delay before retry
        } else {
          print('❌ REST mark-read failed after $maxRetries attempts: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel(); // Prevent setState-after-dispose from timer callbacks
    try {
      if (widget.taskId != null) {
        ref.read(socketServiceProvider).leaveChat(widget.taskId!);
        // Clear active task status on leave
        ref.read(activeChatTaskIdProvider.notifier).state = null;
      }
    } catch (_) {
      // Safely ignore if ref is already disposed
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _adminNoteController.dispose();
    _commentController.dispose();
    _tabController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await ApiClient().getUsers();
      if (mounted) {
        setState(() {
          _users = response.data['data'] as List<dynamic>;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingUsers = false; });
    }
  }

  void _populateForm(Task task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _selectedUserIds = List<String>.from(task.assignedTo);
    _status = task.status;
    _priority = task.priority;
    _dueDate = task.dueDate;
    _adminNoteController.text = task.adminNote ?? '';
    _selectedDependencyIds = task.dependsOn ?? [];
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDate));
      if (timePicked != null) {
        setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day, timePicked.hour, timePicked.minute));
      }
    }
  }

  Future<void> _pickAdminFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _newAdminFiles.addAll(result.files));
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an operator to assign this task.'), backgroundColor: AppTheme.primaryCoral));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final task = Task(
        id: widget.taskId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: _selectedUserIds,
        createdBy: '', status: _status, dueDate: _dueDate, priority: _priority,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        parentTaskId: widget.parentTaskId, adminNote: _adminNoteController.text.trim(),
        dependsOn: _selectedDependencyIds,
      );
      
      if (widget.taskId == null) {
        await ref.read(tasksProvider.notifier).createTask(task, multiAssignedTo: _selectedUserIds.length > 1 ? _selectedUserIds : null, adminFiles: _newAdminFiles);
      } else {
        await ref.read(taskDetailProvider(widget.taskId!).notifier).updateTask(task, adminFiles: _newAdminFiles);
      }
      if (mounted) { Navigator.pop(context); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save task: $e'), backgroundColor: AppTheme.primaryCoral));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        title: const Text('DELETE TASK?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        content: const Text('This action is permanent and will remove all data linked to this task from the database.', style: TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textDark))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryCoral),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(tasksProvider.notifier).deleteTask(widget.taskId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully.'), backgroundColor: AppTheme.sidebarDark),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete Failed: $e'), backgroundColor: AppTheme.primaryCoral),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskId != null) {
      // ref.listen in build is correct Riverpod 2 pattern — fires once per state change, not per rebuild
      ref.listen(messagesForTaskProvider(widget.taskId!), (prev, next) {
        if (_tabController.index == 1 && next.messages.length > (prev?.messages.length ?? 0)) {
          final currentUserId = ref.read(authNotifierProvider).user?['id'] ?? '';
          
          // REST call to persist read state
          _persistMarkRead(widget.taskId!);
          
          ref.read(socketServiceProvider).emitMarkRead(widget.taskId!, currentUserId);
          ref.read(unreadCountsProvider.notifier).clear(widget.taskId!);
          
          // Auto-scroll: only if near bottom or own message
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!mounted || !_chatScrollController.hasClients) return;
            // Guard: position may not be attached yet
            if (!_chatScrollController.position.hasContentDimensions) return;

            final scrollPos = _chatScrollController.position.pixels;
            final maxScroll = _chatScrollController.position.maxScrollExtent;
            final isNearBottom = (maxScroll - scrollPos) < 200;
            final isOwnMessage = next.messages.isNotEmpty && 
                next.messages.last.senderId == currentUserId;

            if (isNearBottom || isOwnMessage) {
              _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }


    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.user?['role'] == 'admin';

    if (widget.taskId != null) {
      final taskState = ref.watch(taskDetailProvider(widget.taskId!));
      if (taskState.isLoading) return const Scaffold(backgroundColor: AppTheme.backgroundLight, body: LoadingIndicator());
      if (taskState.task != null && !_isEditing && !_formPopulated) {
        _formPopulated = true;
        _populateForm(taskState.task!);
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.taskId == null ? 'CREATE TASK' : 'TASK DETAILS', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          if (widget.taskId != null && !_isEditing && isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.primaryCoral, size: 22), 
              onPressed: _deleteTask
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined), 
              onPressed: () => setState(() { _isEditing = true; _formPopulated = false; })
            ),
          ],
          if (_isEditing && isAdmin)
            IconButton(icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCoral)) : const Icon(Icons.save_rounded, color: AppTheme.primaryCoral), onPressed: _isSaving ? null : _saveTask),
        ],
        bottom: widget.taskId != null && !_isEditing ? TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryCoral,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryCoral,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'DETAILS'),
            Tab(text: 'COLLABORATION'),
          ],
        ) : null,
      ),
      body: _isEditing && isAdmin ? _buildEditForm() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    final taskState = ref.watch(taskDetailProvider(widget.taskId!));
    if (taskState.task == null) return const Center(child: Text('TASK NOT FOUND', style: TextStyle(color: AppTheme.textMuted)));
    final task = taskState.task!;
    final authState = ref.watch(authNotifierProvider);
    final isWorker = authState.user?['role'] == 'employee' || authState.user?['role'] == 'worker';
    final isAdmin = authState.user?['role'] == 'admin';

    return TabBarView(
      controller: _tabController,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.dependsOn != null && task.dependsOn!.isNotEmpty && task.status == 'waiting') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: AppTheme.primaryCoral),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SEQUENTIAL BLOCK', style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              'This task is waiting for a prerequisite task to be completed.',
                              style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // --- REJECTION FEEDBACK CARD ---
              if (task.status == 'pending' && task.history != null && task.history!.any((h) => h.action.toLowerCase().contains('reject'))) ...[
                () {
                  final lastReject = task.history!.lastWhere((h) => h.action.toLowerCase().contains('reject'));
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCoral.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.primaryCoral, size: 20),
                            const SizedBox(width: 12),
                            const Text('REJECTION FEEDBACK', style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                            const Spacer(),
                            Text(DateFormat('MMM dd').format(lastReject.timestamp), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lastReject.details ?? 'Admin rejected this submission. Please review your work and resubmit.',
                          style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                        ),
                        if (lastReject.userName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('— Reviewed by ${lastReject.userName}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  );
                }(),
              ],
              Text(task.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildThemeChip(task.status.toUpperCase(), task.status == 'completed' ? AppTheme.successGreen : AppTheme.secondaryBlue),
                  const SizedBox(width: 12),
                  _buildThemeChip(task.priority.toUpperCase(), task.priority == 'high' ? AppTheme.primaryCoral : AppTheme.secondaryBlue),
                ],
              ),
              const SizedBox(height: 32),
              _buildInfoRow(Icons.calendar_today_outlined, 'DUE DATE', DateFormat('MMM dd, yyyy • HH:mm').format(task.dueDate)),
              _buildInfoRow(
                Icons.group_outlined, 
                'ASSIGNED TEAM', 
                task.assignedToNames != null && task.assignedToNames!.isNotEmpty 
                    ? task.assignedToNames!.join(', ') 
                    : 'UNASSIGNED'
              ),
              const SizedBox(height: 32),
              const Text('Description', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
                child: Text(task.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.6)),
              ),
              
              if (task.adminFiles != null && task.adminFiles!.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text('Reference Files', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      onTap: () async {
                        final file = task.adminFiles![index];
                        if (file == 'null' || file.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: Invalid file link.'))
                          );
                          return;
                        }

                        final url = file.startsWith('http') 
                          ? file 
                          : '${AppConstants.serverUrl}/$file';

                        try {
                          final uri = Uri.parse(url);
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open file. The link may have expired — try refreshing the task.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open file. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                )),
              ],

              if (isAdmin) ...[
                const SizedBox(height: 48),
                const Text('Sub-Task Management', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TaskDetailScreen(parentTaskId: task.id)),
                    ),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('ADD SUB-TASK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryBlue,
                      side: const BorderSide(color: AppTheme.secondaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Text('Submission Logs', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildSubmissionsViewer(),
                
                const SizedBox(height: 48),
                const Text('Audit Trail', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildAuditTrail(task),
              ],

              if (isWorker && task.status != 'completed' && task.status != 'submitted') ...[
                const SizedBox(height: 48),
                if (task.dependsOn != null && task.dependsOn!.isNotEmpty && task.status == 'waiting')
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 48),
                        const SizedBox(height: 16),
                        const Text('SUBMISSION LOCKED', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        const Text('Finish prerequisite tasks first.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProofUploadScreen(taskId: task.id, userId: authState.user?['id'] ?? '')),
                      ).then((_) => ref.refresh(taskDetailProvider(task.id))),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('SUBMIT WORK PROOF', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                const SizedBox(height: 40),
              ]
            ],
          ),
        ),
        _buildChatSection(task, authState),
      ],
    );
  }

  Widget _buildChatSection(Task task, AuthState authState) {
    final messageState = ref.watch(messagesForTaskProvider(task.id));
    final currentUserId = authState.user?['id'];

    return Column(
      children: [
        Expanded(
          child: messageState.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(24),
                itemCount: messageState.messages.length,
                itemBuilder: (context, index) {
                  final msg = messageState.messages[index];
                  final isMe = msg.senderId == currentUserId;
                  return _buildChatBubble(msg, isMe);
                },
              ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final typingUser = ref.watch(typingUsersProvider)[task.id];
                    if (typingUser == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 16),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCoral),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$typingUser is typing...',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryCoral, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                          onChanged: (val) {
                            final auth = ref.read(authNotifierProvider);
                            final userName = (auth.user is Map ? auth.user!['name'] : null)?.toString() ?? 'Someone';
                            if (!_isLocalTyping && val.isNotEmpty) {
                              _isLocalTyping = true;
                              ref.read(socketServiceProvider).emitTyping(task.id, userName);
                            }
                            _typingTimer?.cancel();
                            _typingTimer = Timer(const Duration(seconds: 2), () {
                              _isLocalTyping = false;
                              ref.read(socketServiceProvider).emitStopTyping(task.id);
                            });
                          },
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _sendMessage();
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: AppTheme.textMuted),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      onPressed: () => _sendMessage(),
                      backgroundColor: AppTheme.primaryCoral,
                      elevation: 0,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final auth = ref.read(authNotifierProvider);
    final currentUserId = auth.user?['id'] ?? '';

    // Send via socket — server will echo back the confirmed message to the sender
    // and broadcast to everyone else in the room. No optimistic message needed
    // since the server is local and responds in <100ms.
    ref.read(socketServiceProvider).sendMessage(
      widget.taskId!,
      currentUserId,
      text,
    );
    _commentController.clear();
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _chatScrollController.hasClients &&
          _chatScrollController.position.hasContentDimensions) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });

    _isLocalTyping = false;
    ref.read(socketServiceProvider).emitStopTyping(widget.taskId!);
  }

  Widget _buildAuditTrail(Task task) {
    if (task.history == null || task.history!.isEmpty) {
      return const Text('No activity recorded yet.', style: TextStyle(color: AppTheme.textMuted));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: task.history!.reversed.map((entry) {
          return Material(
            color: Colors.transparent,
            child: ListTile(
            dense: true,
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getHistoryColor(entry.action),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            title: Text(entry.action.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
            subtitle: Text(
              '${entry.userName ?? "System"} • ${DateFormat('MMM dd, HH:mm').format(entry.timestamp)}\n${entry.details ?? ""}',
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
            isThreeLine: entry.details != null && entry.details!.length > 30,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getHistoryColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('approve') || a.contains('completed')) return AppTheme.successGreen;
    if (a.contains('reject')) return AppTheme.primaryCoral;
    if (a.contains('assign')) return AppTheme.secondaryBlue;
    return AppTheme.textMuted;
  }

  Widget _buildChatBubble(Message msg, bool isMe) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.sidebarDark.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ),
      );
    }

    final bool isSending = msg.isSending;
    final bool isReadByOthers = msg.readBy.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 4),
              child: Text(
                '${msg.senderName} • ${msg.senderRole.toUpperCase()}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) _buildBubbleTail(false),
              Flexible(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 26),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryCoral : AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1))
                        ],
                        border: isMe ? null : Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppTheme.textDark,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.formattedTime,
                            style: TextStyle(
                              fontSize: 10, 
                              color: isMe ? Colors.white.withValues(alpha: 0.7) : AppTheme.textMuted,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            if (isSending)
                              Icon(Icons.access_time_rounded, size: 12, color: Colors.white.withValues(alpha: 0.7))
                            else if (isReadByOthers)
                              const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF34B7F1)) // WhatsApp Blue
                            else
                              Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)) // WhatsApp Gray
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isMe) _buildBubbleTail(true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleTail(bool isMe) {
    return Transform.translate(
      offset: Offset(isMe ? -2 : 2, -10),
      child: CustomPaint(
        size: const Size(10, 10),
        painter: TailPainter(color: isMe ? AppTheme.primaryCoral : AppTheme.surfaceWhite, isMe: isMe),
      ),
    );
  }



  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildThemeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(_titleController, 'Task Title', Icons.title_rounded),
            const SizedBox(height: 24),
            _buildField(_descriptionController, 'Description', Icons.description_outlined, maxLines: 4),
            const SizedBox(height: 32),
            const Text('ASSIGNMENT & SCHEDULING', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildPickerTile(
              label: 'Assigned To',
              value: _selectedUserIds.isEmpty 
                  ? 'Select Team Members' 
                  : _selectedUserIds.length == 1 
                      ? _users.firstWhere((u) => u['_id'] == _selectedUserIds.first, orElse: () => {'name': 'Unknown'})['name']
                      : '${_selectedUserIds.length} People Selected',
              icon: Icons.group_add_outlined,
              onTap: () => _showUserPicker(),
            ),
            const SizedBox(height: 12),
            _buildPickerTile(
              label: 'Due Date',
              value: DateFormat('MMM dd, yyyy • HH:mm').format(_dueDate),
              icon: Icons.calendar_month_outlined,
              onTap: () => _selectDueDate(context),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildDropdown('Priority', _priority, ['low', 'medium', 'high'], (val) => setState(() => _priority = val!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown('Status', _status, ['pending', 'in_progress', 'submitted', 'completed'], (val) => setState(() => _status = val!))),
              ],
            ),
            const SizedBox(height: 24),
            _buildField(_adminNoteController, 'Admin (Private) Note', Icons.lock_outline_rounded, maxLines: 2),
            const SizedBox(height: 32),
            const Text('ATTACHMENTS', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildPickerTile(
              label: 'Add Files',
              value: _newAdminFiles.isEmpty ? 'Upload Reference Data' : '${_newAdminFiles.length} files selected',
              icon: Icons.upload_file_rounded,
              onTap: () => _pickAdminFiles(),
            ),
            if (_newAdminFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 24),
                child: Wrap(
                  spacing: 8,
                  children: _newAdminFiles.map((f) => Chip(
                    label: Text(f.name, style: const TextStyle(fontSize: 10)),
                    onDeleted: () => setState(() => _newAdminFiles.remove(f)),
                    backgroundColor: AppTheme.surfaceWhite,
                  )).toList(),
                ),
              ),
            const SizedBox(height: 32),
            const Text('SEQUENTIAL PIPELINE', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildPickerTile(
              label: 'Depends On (Prerequisites)',
              value: _selectedDependencyIds.isEmpty ? 'Mark as Standalone' : '${_selectedDependencyIds.length} Prerequisites Set',
              icon: Icons.alt_route_rounded,
              onTap: () => _showDependencyPicker(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isSaving 
                   ? const CircularProgressIndicator(color: Colors.white) 
                   : const Text('UPDATE TASK DETAILS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryCoral, width: 2)),
      ),
    );
  }

  Widget _buildPickerTile({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.borderLight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
          child: DropdownButton<String>(
            value: value,
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase(), style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  void _showDependencyPicker() {

    final allTasks = ref.read(tasksProvider).tasks.where((t) => t.id != widget.taskId).toList();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('SELECT PREREQUISITES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allTasks.length,
                  itemBuilder: (context, index) {
                    final t = allTasks[index];
                    final isSelected = _selectedDependencyIds.contains(t.id);
                    return ListTile(
                      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)),
                      subtitle: Text('ID: ${t.id.substring(t.id.length - 6)}', style: const TextStyle(fontSize: 10)),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primaryCoral,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              _selectedDependencyIds.add(t.id);
                            } else {
                              _selectedDependencyIds.remove(t.id);
                            }
                          });
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryCoral))),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showUserPicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('ASSIGN TEAM MEMBERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    final isSelected = _selectedUserIds.contains(u['_id']);
                    return CheckboxListTile(
                      title: Text((u is Map ? u['name'] : 'Unknown').toString(), style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                      value: isSelected,
                      activeColor: AppTheme.primaryCoral,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedUserIds.add(u['_id']);
                          } else {
                            _selectedUserIds.remove(u['_id']);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCoral, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('CONFIRM SELECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionsViewer() {
    final state = ref.watch(submissionsForTaskProvider(widget.taskId ?? ''));
    if (state.isLoading) return const CircularProgressIndicator(color: AppTheme.primaryCoral);
    if (state.submissions.isEmpty) return const Text('No submissions logged for this task.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13));
    return Column(
      children: state.submissions.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
             title: Text(s['status']?.toString().toUpperCase() ?? 'PENDING', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
             subtitle: Text('By: ${(s is Map && s['employee'] is Map) ? (s['employee']['name']?.toString() ?? 'Unknown') : 'Unknown'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
             iconColor: AppTheme.secondaryBlue,
             collapsedIconColor: AppTheme.secondaryBlue,
             children: [
               if (s['beforeFilesUrls'] != null)
                 _buildFileSection('BEFORE OPERATIONS', List<String>.from(s['beforeFilesUrls']), List<String>.from(s['beforeFileNames'] ?? [])),
               if (s['afterFilesUrls'] != null)
                 _buildFileSection('AFTER COMPLETION', List<String>.from(s['afterFilesUrls']), List<String>.from(s['afterFileNames'] ?? [])),
               const SizedBox(height: 16),
             ]
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildFileSection(String title, List<String> urls, List<String> names) {
    if (urls.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1)),
        ),
        ...List.generate(urls.length, (index) {
          final url = urls[index];
          final name = (names.length > index) ? names[index] : 'Download File';
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.image_outlined, color: AppTheme.secondaryBlue, size: 20),
            title: Text(name, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.file_download_outlined, color: AppTheme.textMuted, size: 20),
            onTap: () => launchUrl(Uri.parse(url)),
          );
        }),
      ],
    );
  }
}

class TailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  TailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

