import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_client.dart';

/// Model for submission review
class SubmissionReview {
  final String id;
  final String taskId;
  final String taskTitle;
  final String employeeName;
  final List<String> beforeFilesUrls;
  final List<String> beforeFileNames;
  final List<String> afterFilesUrls;
  final List<String> afterFileNames;
  final String? description;
  final String status;
  final String? previousSubmissionId;

  SubmissionReview({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.employeeName,
    required this.beforeFilesUrls,
    required this.beforeFileNames,
    required this.afterFilesUrls,
    required this.afterFileNames,
    this.description,
    required this.status,
    this.previousSubmissionId,
  });

  factory SubmissionReview.fromJson(Map<String, dynamic> json) {
    return SubmissionReview(
      id: json['_id'] ?? '',
      taskId: (json['task'] is Map ? json['task']['_id']?.toString() : null) ?? json['taskId']?.toString() ?? '',
      taskTitle: (json['task'] is Map ? json['task']['title']?.toString() : null) ?? json['taskTitle']?.toString() ?? 'Unknown Task',
      employeeName: (json['employee'] is Map ? json['employee']['name']?.toString() : null) ?? json['employeeName']?.toString() ?? 'Unknown Employee',
      beforeFilesUrls: List<String>.from(json['beforeFilesUrls'] ?? []),
      beforeFileNames: List<String>.from(json['beforeFileNames'] ?? []),
      afterFilesUrls: List<String>.from(json['afterFilesUrls'] ?? []),
      afterFileNames: List<String>.from(json['afterFileNames'] ?? []),
      description: json['description'],
      status: json['status'] ?? 'pending',
      previousSubmissionId: json['previousSubmissionId']?.toString(),
    );
  }
}

/// Provider for pending submissions (used by admin review screen)
final pendingSubmissionsProvider =
    FutureProvider<List<SubmissionReview>>((ref) async {
  final response = await ApiClient().getPendingSubmissions();
      
  if (response.statusCode == 200) {
    final List data = response.data['data'];
    return data.map((json) => SubmissionReview.fromJson(json)).toList();
  }
  return [];
});
