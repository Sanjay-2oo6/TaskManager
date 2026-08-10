// ---------------------------------------------------------------------------
// app_constants.dart — Global constants for the Task Manager app.
// All contributors MUST use these constants instead of hardcoding values.
// ---------------------------------------------------------------------------

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._(); // Prevent instantiation

  // --- API ---
  static String get serverUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:5000';
  static String get apiBaseUrl => '$serverUrl/api/v1';
  static String get baseUrl => serverUrl; // Used for Sockets
  static const String tasksEndpoint = '/tasks';
  static const String tokenKey = 'auth_token';
  static const String loginTimestampKey = 'login_timestamp';

  // --- Hive Box Names ---
  static const String syncQueueBox = 'sync_queue';
  static const String submissionsBox = 'submissions';

  // --- Submission Status Labels ---
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // --- Storage ---
  static const String proofsSubDir = 'proofs';

  // --- Task Constants from Module B ---
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String statusInProgress = 'in-progress';
  static const String statusSubmitted = 'submitted';
  static const String statusCompleted = 'completed';
  static const String displayDateTimeFormat = 'MMM d, yyyy h:mm a';
  static const String displayDateFormat = 'MMM d, yyyy';
}
