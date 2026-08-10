import 'package:hive/hive.dart';

part 'submission.g.dart';

@HiveType(typeId: 2)
class Submission extends HiveObject {
  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final List<String> beforeFiles;

  @HiveField(3)
  final List<String> afterFiles;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  String status; // pending, approved, rejected

  @HiveField(7)
  final List<String> beforeFileNames;

  @HiveField(8)
  final List<String> afterFileNames;

  Submission({
    required this.taskId,
    required this.userId,
    required this.beforeFiles,
    required this.afterFiles,
    this.description,
    required this.status,
    required this.createdAt,
    this.beforeFileNames = const [],
    this.afterFileNames = const [],
  });
}
