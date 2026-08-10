import 'package:intl/intl.dart';

class Message {
  final String id;
  final String taskId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;
  final bool isSystem;
  final bool isSending;

  Message({
    required this.id,
    required this.taskId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.readBy = const [],
    this.isSystem = false,
    this.isSending = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Safe date parser
    DateTime safeParseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return Message(
      id: json['_id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      senderId: json['sender'] is Map ? (json['sender']['_id']?.toString() ?? '') : (json['sender']?.toString() ?? ''),
      senderName: json['sender'] is Map ? (json['sender']['name']?.toString() ?? 'Unknown') : 'Member',
      senderRole: json['sender'] is Map ? (json['sender']['role']?.toString() ?? 'member') : 'member',
      text: json['text']?.toString() ?? '',
      createdAt: safeParseDate(json['createdAt']),
      // Safe readBy parsing — skip entries missing the 'user' key
      readBy: (json['readBy'] as List?)
          ?.where((e) => e is Map && e['user'] != null)
          .map((e) => e['user'].toString())
          .toList() ?? [],
      isSystem: json['isSystem'] == true,
    );
  }

  String get formattedTime => DateFormat('HH:mm').format(createdAt.toLocal());
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt.toLocal());
}
