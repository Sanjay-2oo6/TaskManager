import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message.dart';
import '../data/services/api_client.dart';
import 'task_providers.dart';

final messageApiServiceProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});


class MessagesState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  MessagesState({required this.messages, this.isLoading = false, this.error});

  MessagesState copyWith({List<Message>? messages, bool? isLoading, String? error}) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiClient _apiClient;
  final String taskId;

  MessagesNotifier(this._apiClient, this.taskId) : super(MessagesState(messages: []));

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.getMessages(taskId);
      final data = response.data['data'] as List;
      final messages = data.map((m) => Message.fromJson(m)).toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiClient.friendlyError(e));
    }
  }

  void addMessage(Message message) {
    // Guard: the taskId from socket may come as an ObjectId object
    // We compare both the full string and just the hex id part
    final msgTaskId = message.taskId;
    print('📥 addMessage called:');
    print('   message.taskId: $msgTaskId');
    print('   expected taskId: $taskId');
    print('   match: ${msgTaskId == taskId}');
    print('   message.text: ${message.text}');
    
    if (msgTaskId != taskId && msgTaskId != taskId.toString()) {
      print('❌ TaskId mismatch - skipping message');
      return;
    }

    // Dedup: never add the same message ID twice
    if (message.id.isNotEmpty && state.messages.any((m) => m.id == message.id)) {
      print('⚠️ Duplicate message ID - skipping');
      return;
    }

    // Remove any stuck optimistic messages with the same text+sender before appending
    // This handles the case where the optimistic replace logic might fail
    final cleaned = state.messages.where((m) =>
      !(m.isSending && m.text == message.text && m.senderId == message.senderId)
    ).toList();

    final newMessages = [...cleaned, message];
    print('✅ Adding message - new total count: ${newMessages.length}');
    state = state.copyWith(messages: newMessages);
  }


  void addOptimisticMessage(String text, String senderId, String senderName, String role) {
    final msg = Message(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      senderId: senderId,
      senderName: senderName,
      senderRole: role,
      text: text,
      createdAt: DateTime.now(),
      isSending: true,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  Future<void> markAsRead() async {
    await _apiClient.markMessagesRead(taskId);
  }


  /// Called when the socket broadcasts 'messages-read'.
  /// Updates local readBy lists so ✓✓ appears instantly for the sender.
  void updateReadBy(String targetTaskId, String readerId) {
    if (targetTaskId != taskId) return;
    final updatedMessages = state.messages.map((msg) {
      if (!msg.readBy.contains(readerId)) {
        // Create a new message with the reader added
        return Message(
          id: msg.id,
          taskId: msg.taskId,
          senderId: msg.senderId,
          senderName: msg.senderName,
          senderRole: msg.senderRole,
          text: msg.text,
          createdAt: msg.createdAt,
          readBy: [...msg.readBy, readerId],
          isSystem: msg.isSystem,
          isSending: msg.isSending,
        );
      }
      return msg;
    }).toList();
    state = state.copyWith(messages: updatedMessages);
  }
}

final messagesForTaskProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, taskId) {
  final apiService = ref.watch(messageApiServiceProvider);
  final notifier = MessagesNotifier(apiService, taskId);
  notifier.loadMessages();
  return notifier;
});
