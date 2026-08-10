import 'dart:convert';

class HistoryEntry {
  final String action;
  final String? userName;
  final DateTime timestamp;
  final String? details;

  HistoryEntry({
    required this.action,
    this.userName,
    required this.timestamp,
    this.details,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      action: json['action']?.toString() ?? 'Action',
      userName: (json['user'] is Map) ? json['user']['name']?.toString() : (json['userName']?.toString() ?? json['user']?.toString()),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'].toString()) : DateTime.now(),
      details: json['details']?.toString(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final List<String> assignedTo;
  final List<String>? assignedToNames;
  final List<String>? assignedToUsernames;
  final String createdBy;
  final String? createdByName;
  final String status;
  final DateTime dueDate;
  final String priority;
  final String description;
  final List<String>? adminFiles;
  final List<String>? adminFileNames;
  final String? adminNote;
  final List<String>? dependsOn;
  final List<String>? dependsOnNames; // Populated titles
  final String? parentTaskId;
  final String? organizationId; // Multi-tenant support
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<HistoryEntry>? history;

  Task({
    required this.id,
    required this.title,
    required this.assignedTo,
    this.assignedToNames,
    this.assignedToUsernames,
    required this.createdBy,
    this.createdByName,
    required this.status,
    required this.dueDate,
    required this.priority,
    required this.description,
    this.adminFiles,
    this.adminFileNames,
    this.adminNote,
    this.dependsOn,
    this.dependsOnNames,
    this.parentTaskId,
    this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.history,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // assignedTo may be a list of IDs (strings) or populated objects (Maps)
    final assignedToRaw = json['assignedTo'] as List? ?? [];

    // Primary: use stored assignedToNames. Fallback: extract from populated objects.
    List<String>? resolveNames() {
      final stored = (json['assignedToNames'] as List?)
          ?.map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (stored != null && stored.isNotEmpty) return stored;
      // Derive from populated assignedTo user objects
      final derived = assignedToRaw
          .whereType<Map>()
          .map((u) => u['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      return derived.isNotEmpty ? derived : null;
    }

    List<String>? resolveUsernames() {
      final stored = (json['assignedToUsernames'] as List?)
          ?.map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (stored != null && stored.isNotEmpty) return stored;
      final derived = assignedToRaw
          .whereType<Map>()
          .map((u) => u['username']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      return derived.isNotEmpty ? derived : null;
    }

    // Safe date parser — returns fallback on any parse error
    DateTime safeParseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return fallback;
      }
    }

    return Task(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      assignedTo: assignedToRaw.map((e) => e is Map ? (e['_id']?.toString() ?? '') : e.toString()).toList(),
      assignedToNames: resolveNames(),
      assignedToUsernames: resolveUsernames(),
      createdBy: (json['createdBy'] is Map) ? (json['createdBy']['_id']?.toString() ?? '') : (json['createdBy']?.toString() ?? ''),
      createdByName: (json['createdBy'] is Map) ? json['createdBy']['name']?.toString() : (json['createdByName']?.toString() ?? json['createdBy']?.toString()),
      status: json['status']?.toString() ?? 'pending',
      dueDate: safeParseDate(json['dueDate'], DateTime.now()),
      priority: json['priority']?.toString() ?? 'medium',
      description: json['description']?.toString() ?? '',
      adminFiles: (json['adminFiles'] as List?)
          ?.map((e) => e.toString())
          .where((s) => s != 'null' && s.isNotEmpty)
          .toList(),
      adminFileNames: (json['adminFileNames'] as List?)?.map((e) => e.toString()).toList(),
      adminNote: json['adminNote']?.toString() ?? '',
      dependsOn: (json['dependsOn'] as List?)?.map((e) => e is Map ? (e['_id']?.toString() ?? '') : e.toString()).toList(),
      dependsOnNames: (json['dependsOn'] as List?)?.map((e) => e is Map ? (e['title']?.toString() ?? '') : e.toString()).toList(),
      parentTaskId: json['parentTaskId'] is Map ? json['parentTaskId']['_id'] : json['parentTaskId']?.toString(),
      organizationId: json['organizationId']?.toString(),
      createdAt: safeParseDate(json['createdAt'], DateTime.now()),
      updatedAt: safeParseDate(json['updatedAt'], DateTime.now()),
      history: (json['history'] as List?)?.map((e) => HistoryEntry.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,  // ✅ Don't double-encode - return list directly
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'adminNote': adminNote,
      'dependsOn': dependsOn,  // ✅ Return list, not JSON string
      'parentTaskId': parentTaskId,
      'organizationId': organizationId,  // ✅ Include organizationId
    };
  }

  Task copyWith({
    String? id,
    String? title,
    List<String>? assignedTo,
    List<String>? assignedToNames,
    List<String>? assignedToUsernames,
    String? createdBy,
    String? createdByName,
    String? status,
    DateTime? dueDate,
    String? priority,
    String? description,
    List<String>? adminFiles,
    List<String>? adminFileNames,
    String? adminNote,
    List<String>? dependsOn,
    List<String>? dependsOnNames,
    String? parentTaskId,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<HistoryEntry>? history,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToNames: assignedToNames ?? this.assignedToNames,
      assignedToUsernames: assignedToUsernames ?? this.assignedToUsernames,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      adminFiles: adminFiles ?? this.adminFiles,
      adminFileNames: adminFileNames ?? this.adminFileNames,
      adminNote: adminNote ?? this.adminNote,
      dependsOn: dependsOn ?? this.dependsOn,
      dependsOnNames: dependsOnNames ?? this.dependsOnNames,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }
}
