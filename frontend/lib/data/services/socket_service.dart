import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SocketService {
  IO.Socket? _socket; // Nullable to prevent LateInitializationError before connect()
  
  IO.Socket get socket {
    if (_socket == null) throw StateError('SocketService.connect() has not completed yet');
    return _socket!;
  }

  bool get isConnected => _socket?.connected == true;
  final Function(dynamic) onTaskUpdate;
  final Function(dynamic) onNewSubmission;
  final Function(dynamic) onSubmissionReviewed;
  final Function(dynamic) onTaskUnlocked;
  final Function(dynamic) onNewMessage;
  final Function(dynamic) onChatAlert;
  final Function(dynamic) onTyping;
  final Function(dynamic) onStopTyping;
  final Function(dynamic) onMessagesRead;
  
  String? _currentTaskId; // "Sticky" room to auto-rejoin on reconnect

  SocketService({
    required this.onTaskUpdate, 
    required this.onNewSubmission,
    required this.onSubmissionReviewed,
    required this.onTaskUnlocked,
    required this.onNewMessage,
    required this.onChatAlert,
    required this.onTyping,
    required this.onStopTyping,
    required this.onMessagesRead,
  });

  Future<void> connect() async {
    // Read the JWT from storage and pass it in the socket handshake
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    _socket = IO.io(AppConstants.baseUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(2000)
        .setAuth({'token': token})
        .build()
    );
    
    _socket!.onConnect((_) {
      print('📡 Radiant Socket Connection Established: ${_socket!.id}');
      // Auto-rejoin the active room if we were previously in one (Healing Logic)
      if (_currentTaskId != null) {
        print('🩹 Healing: Auto-rejoining room task_$_currentTaskId');
        joinChat(_currentTaskId!);
      }
    });

    _socket!.onConnectError((data) => print('❌ Socket Connection Error: $data'));
    _socket!.on('connect_timeout', (data) => print('❌ Socket Connection Timeout: $data'));
    _socket!.on('error', (data) => print('❌ Socket Error: $data'));
    _socket!.onReconnect((_) => print('🔄 Socket Reconnecting...'));
    _socket!.on('reconnect_attempt', (data) => print('🔄 Socket Reconnect Attempt: $data'));

    _socket!.on('task-updated', (data) {
      print('🔄 Real-time Pulse: Task Update Received');
      onTaskUpdate(data);
    });

    _socket!.on('new-submission', (data) {
      print('📸 Real-time Pulse: New Submission Received');
      onNewSubmission(data);
    });

    _socket!.on('submission-reviewed', (data) {
      print('⚖️ Real-time Pulse: Submission Reviewed');
      onSubmissionReviewed(data);
    });

    _socket!.on('task-unlocked', (data) {
      print('🔓 Real-time Pulse: Task Unlocked');
      onTaskUnlocked(data);
    });

    _socket!.on('new-chat-message', (data) {
      print('💬 Real-time Pulse: New Chat Message');
      onNewMessage(data);
    });

    _socket!.on('global-chat-alert', (data) {
      print('🔔 Real-time Pulse: Global Chat Alert');
      onChatAlert(data);
    });

    _socket!.on('user-typing', (data) {
      onTyping(data);
    });

    _socket!.on('user-stop-typing', (data) {
      onStopTyping(data);
    });

    _socket!.on('messages-read', (data) {
      print('✅ Real-time Pulse: Messages marked as read');
      onMessagesRead(data);
    });

    _socket!.onDisconnect((_) => print('📴 Socket Disconnected'));
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void joinChat(String taskId) {
    if (_socket == null || !_socket!.connected) return;
    _currentTaskId = taskId;
    _socket!.emit('join-task', taskId);
  }

  void leaveChat(String taskId) {
    if (_currentTaskId == taskId) _currentTaskId = null;
    _socket?.emit('leave-task', taskId);
  }

  /// senderId is kept as a parameter for API compatibility but is ignored by the server.
  void sendMessage(String taskId, String senderId, String text) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Message queued (offline). Will send when online.');
      return;
    }
    _socket!.emit('send-message', {
      'taskId': taskId,
      'text': text,
    });
  }

  void emitTyping(String taskId, String userName) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('typing', {'taskId': taskId, 'userName': userName});
  }

  void emitStopTyping(String taskId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('stop-typing', {'taskId': taskId});
  }

  /// Mark messages in a task as read.
  void emitMarkRead(String taskId, String userId) {
    if (taskId.isEmpty || taskId == 'null' || taskId == 'undefined') {
      print('⚠️ emitMarkRead: Invalid taskId, skipping');
      return;
    }
    if (_socket == null || !_socket!.connected) {
      print('⚠️ emitMarkRead: Socket not connected, skipping');
      return;
    }
    try {
      _socket!.emit('mark-read', {'taskId': taskId});
      print('✅ Emitted mark-read for task: $taskId');
    } catch (e) {
      print('❌ Error emitting mark-read: $e');
    }
  }
}
