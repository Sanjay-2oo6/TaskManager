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
  final Function()? onReconnect;  // ✅ ADD: Callback when reconnecting
  
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
    this.onReconnect,  // ✅ ADD: Optional callback
  });

  Future<void> connect() async {
    // Read the JWT from storage and pass it in the socket handshake
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    print('🔌 Socket connecting to: ${AppConstants.baseUrl}');
    print('   Token present: ${token.isNotEmpty}');
    print('   Token (first 20 chars): ${token.length > 20 ? token.substring(0, 20) : token}...');

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
      print('   Connected: ${_socket!.connected}');
      print('   Disconnected: ${_socket!.disconnected}');
      print('   Server confirmed connection');
      // Auto-rejoin the active room if we were previously in one (Healing Logic)
      if (_currentTaskId != null) {
        print('🩹 Healing: Auto-rejoining room task_$_currentTaskId');
        joinChat(_currentTaskId!);
      }
    });

    _socket!.onConnectError((data) {
      print('❌ Socket Connection Error: $data');
      print('   Error data type: ${data.runtimeType}');
      if (data is Map) {
        print('   Error details: ${data.toString()}');
      }
    });
    _socket!.on('connect_timeout', (data) => print('❌ Socket Connection Timeout: $data'));
    _socket!.on('error', (data) {
      print('❌ Socket Error: $data');
      print('   Error type: ${data.runtimeType}');
    });
    _socket!.onReconnect((_) => print('🔄 Socket Reconnecting...'));
    _socket!.on('reconnect_attempt', (data) => print('🔄 Socket Reconnect Attempt: $data'));

    // ✅ FIX #6: Handle reconnection - trigger message catch-up
    _socket!.on('connect', (_) {
      if (onReconnect != null) {
        print('🔗 Socket reconnected - triggering message catch-up');
        onReconnect!();
      }
    });

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
      print('💬 Real-time Pulse: New Chat Message Received');
      print('   Data: $data');
      print('   Type: ${data.runtimeType}');
      if (data is Map) {
        print('   taskId: ${data['taskId']}');
        print('   sender: ${data['sender']}');
        print('   text: ${data['text']}');
      }
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
    print('🚪 joinChat called for taskId: $taskId');
    print('   socket: $_socket');
    print('   connected: ${_socket?.connected}');
    
    if (_socket == null || !_socket!.connected) {
      print('⚠️ joinChat: Socket not ready, skipping');
      return;
    }
    
    _currentTaskId = taskId;
    print('📨 Emitting join-task event for: $taskId');
    _socket!.emit('join-task', taskId);
    print('✅ join-task emitted');
  }

  void leaveChat(String taskId) {
    if (_currentTaskId == taskId) _currentTaskId = null;
    _socket?.emit('leave-task', taskId);
  }

  /// senderId is kept as a parameter for API compatibility but is ignored by the server.
  void sendMessage(String taskId, String senderId, String text) {
    print('📤 sendMessage called:');
    print('   taskId: $taskId');
    print('   senderId: $senderId');
    print('   text: $text');
    print('   socket: $_socket');
    print('   connected: ${_socket?.connected}');
    
    if (_socket == null) {
      print('❌ Socket is NULL - connect() may not have completed');
      return;
    }
    
    if (!_socket!.connected) {
      print('❌ Socket NOT CONNECTED');
      print('   Socket ID: ${_socket!.id}');
      print('   Disconnected: ${_socket!.disconnected}');
      return;
    }
    
    print('✅ Socket connected, emitting send-message');
    _socket!.emit('send-message', {
      'taskId': taskId,
      'text': text,
    });
    print('✅ Emitted send-message to server');
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
