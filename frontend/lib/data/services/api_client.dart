// ---------------------------------------------------------------------------
// api_client.dart — Centralized Dio HTTP client.
// All network calls in the app MUST go through this client.
// Architecture rule: auth token is added here so screens never touch headers.
// ---------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),  // 5 min for file uploads
        sendTimeout: const Duration(minutes: 5),     // 5 min for file uploads
      ),
    );
    
    // ✅ ADD RETRY INTERCEPTOR for mobile resilience
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: print,
      ),
    );
  }

  /// Call this after login to inject the JWT token for all future requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove auth token on logout.
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Extract a clean, user-friendly error message from any exception.
  /// Prevents raw Dio internals (URLs, headers, stack traces) from reaching the UI.
  static String friendlyError(Object e) {
    try {
      final dynamic err = e;
      
      // Check for HTTP status codes first (401, 403, 404, 5xx)
      final statusCode = err?.response?.statusCode;
      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }
      if (statusCode == 403) {
        // Prefer server message for 403 (lock errors, permission denied, etc.)
        final serverMsg = err?.response?.data?['message'];
        if (serverMsg != null && serverMsg.toString().isNotEmpty) {
          return serverMsg.toString();
        }
        return 'Access denied. You don\'t have permission to perform this action.';
      }
      if (statusCode == 404) {
        return 'Resource not found.';
      }
      if (statusCode != null && statusCode >= 500) {
        final serverMsg = err?.response?.data?['message'];
        if (serverMsg != null && serverMsg.toString().isNotEmpty) {
          return serverMsg.toString();
        }
        return 'Server error. Please try again later.';
      }
      
      // Dio error with a server response body (2xx-4xx)
      final serverMsg = err?.response?.data?['message'];
      if (serverMsg != null && serverMsg.toString().isNotEmpty) {
        return serverMsg.toString();
      }
      
      // Dio connection/timeout errors
      final dioType = err?.type?.toString() ?? '';
      if (dioType.contains('connectTimeout') || dioType.contains('connectionTimeout')) {
        return 'Connection timed out. Check your network and try again.';
      }
      if (dioType.contains('receiveTimeout')) {
        return 'Server took too long to respond. Try again.';
      }
      if (dioType.contains('sendTimeout')) {
        return 'Upload timed out. Check your network and try again.';
      }
      if (dioType.contains('connectionError') || dioType.contains('unknown')) {
        return 'Cannot reach the server. Check your network connection.';
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }

  /// ✅ MOBILE: Check if network is available before making requests
  Future<bool> isNetworkAvailable() async {
    try {
      final response = await _dio.head(
        '/app/version', // Light endpoint just to check connectivity
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── Authentication & Users ───────────────────────────────────────────────

  /// Login to the system and get JWT.
  Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  /// Register/Create a new user (Admin or Self).
  Future<Response> createUser(Map<String, dynamic> userData) =>
      _dio.post('/auth/users', data: userData);

  /// Get current user profile.
  Future<Response> getMe() => _dio.get('/auth/me');

  /// Get all users (Admin only).
  Future<Response> getUsers() => _dio.get('/auth/users');

  /// Delete a user (Admin only).
  Future<Response> deleteUser(String userId) => _dio.delete('/auth/users/$userId');

  /// Update a user's password (Admin only).
  Future<Response> updateUserPassword(String userId, String password) =>
      _dio.put('/auth/users/$userId/password', data: {'password': password});

  /// Update self profile (name or password).
  Future<Response> updateSelfProfile(Map<String, dynamic> data) =>
      _dio.put('/auth/me/profile', data: data);

  // ─── Super Admin - Organizations ──────────────────────────────────────────

  /// Get all organizations (Super Admin only).
  Future<Response> getAllOrganizations({int page = 1, int limit = 20}) =>
      _dio.get('/super-admin/organizations', queryParameters: {'page': page, 'limit': limit});
  
  /// Alias for consistency
  Future<Response> getOrganizations({int page = 1, int limit = 20}) =>
      getAllOrganizations(page: page, limit: limit);

  /// Get single organization details (Super Admin only).
  Future<Response> getOrganization(String orgId) =>
      _dio.get('/super-admin/organizations/$orgId');

  /// Create new organization (Super Admin only).
  Future<Response> createOrganization(Map<String, dynamic> orgData) =>
      _dio.post('/super-admin/organizations', data: orgData);

  /// Update organization (Super Admin only).
  Future<Response> updateOrganization(String orgId, Map<String, dynamic> updates) =>
      _dio.patch('/super-admin/organizations/$orgId', data: updates);

  /// Toggle organization active status (Super Admin only).
  Future<Response> toggleOrganizationStatus(String orgId) =>
      _dio.post('/super-admin/organizations/$orgId/toggle');
  
  /// Alias for toggle
  Future<Response> toggleOrganization(String orgId) =>
      toggleOrganizationStatus(orgId);

  /// Delete organization (Super Admin only).
  Future<Response> deleteOrganization(String orgId) =>
      _dio.delete('/super-admin/organizations/$orgId');

  /// Get system-wide statistics (Super Admin only).
  Future<Response> getSystemWideStats() =>
      _dio.get('/super-admin/stats');
  
  /// Alias for platform stats
  Future<Response> getPlatformStats() =>
      getSystemWideStats();

  // ─── Tasks ────────────────────────────────────────────────────────────────

  /// Fetch all tasks relevant to the user.
  Future<Response> getTasks() => _dio.get('/tasks');

  /// Fetch tasks assigned to current user (Member view).
  Future<Response> getMyTasks() => _dio.get('/tasks/my');

  /// Get a single task by ID.
  Future<Response> getTask(String id) => _dio.get('/tasks/$id');

  /// Create a new task (Admin only). Supports multipart for adminFiles.
  Future<Response> createTask(FormData formData) {
    // For FormData with files, we need to ensure array fields are encoded properly
    // Dio's listFormat only works for URL-encoded data, not multipart
    // We need to manually ensure arrays are sent as multiple fields
    return _dio.post(
      '/tasks', 
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  /// Update an existing task.
  Future<Response> updateTask(String id, FormData formData) =>
      _dio.put(
        '/tasks/$id', 
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

  /// Delete a task (Admin only).
  Future<Response> deleteTask(String id) => _dio.delete('/tasks/$id');

  /// Add comment to a task.
  Future<Response> addTaskComment(String id, String comment) =>
      _dio.post('/tasks/$id/comments', data: {'text': comment});

  /// Reassign a task.
  Future<Response> assignTask(String id, List<String> userIds) =>
      _dio.put('/tasks/$id/assign', data: {'assignedTo': userIds});

  /// Deploy a new APK version.
  Future<Response> deployNewVersion({
    required String version,
    String? notes,
    PlatformFile? apkFile,
  }) async {
    final formData = FormData.fromMap({
      'version': version,
      if (notes != null) 'releaseNotes': notes,
    });

    if (apkFile != null && apkFile.bytes != null) {
      formData.files.add(MapEntry(
        'apk',
        MultipartFile.fromBytes(apkFile.bytes!, filename: apkFile.name),
      ));
    }

    return _dio.put('/app/version', data: formData);
  }

  /// Get current app version.
  Future<Response> getAppVersion() => _dio.get('/app/version');

  // ─── Messages & Chat ──────────────────────────────────────────────────────

  /// Get chat history for a task.
  Future<Response> getMessages(String taskId) => _dio.get('/messages/$taskId');

  /// Mark messages as read for a task.
  Future<Response> markMessagesRead(String taskId) => _dio.post('/messages/$taskId/read');

  /// Get unread message counts for all tasks.
  Future<Response> getUnreadCounts() => _dio.get('/messages/unread-counts');

  // ─── Submissions ──────────────────────────────────────────────────────────

  /// Upload proof images (multipart/form-data) to the backend.
  Future<Response> createSubmission(FormData formData) =>
      _dio.post(
        '/submissions', 
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

  /// Fetch all pending submissions for admin review.
  Future<Response> getPendingSubmissions() => _dio.get('/submissions/pending');

  /// Fetch all submissions (including historical) for admin review.
  Future<Response> getAllSubmissions() => _dio.get('/submissions/admin/all');

  /// Fetch member's own submissions (Member view of their submission history).
  Future<Response> getMySubmissions({int page = 1, int limit = 20}) =>
      _dio.get('/submissions/member/my', queryParameters: {'page': page, 'limit': limit});

  /// Approve or reject a submission with optional feedback.
  /// Approve or reject a submission with optional feedback.
  Future<Response> updateSubmissionStatus(String id, String status, {String? feedback}) {
    final data = {
      'status': status,
    };
    // Only include adminFeedback if it's not null and not empty
    if (feedback != null && feedback.trim().isNotEmpty) {
      data['adminFeedback'] = feedback.trim();
    }
    return _dio.patch('/submissions/$id/status', data: data);
  }

  /// Get a single submission with signed image URLs.
  Future<Response> getSubmission(String id) => _dio.get('/submissions/$id');

  /// Get all submissions for a specific task (Admin viewing task details with proofs).
  Future<Response> getSubmissionsByTaskId(String taskId) =>
      _dio.get('/submissions/task/$taskId');

  /// Add comment to a submission.
  Future<Response> addSubmissionComment(String id, String comment) =>
      _dio.post('/submissions/$id/comments', data: {'text': comment});

  /// Get comments for a submission.
  Future<Response> getSubmissionComments(String id) =>
      _dio.get('/submissions/$id/comments');

  // ─── Analytics ────────────────────────────────────────────────────────────


  /// Get overall system stats (Admin only).
  Future<Response> getSystemStats() => _dio.get('/analytics/stats');

  /// Get worker leaderboard by completed tasks.
  Future<Response> getLeaderboard() => _dio.get('/analytics/leaderboard');

  /// Get active team activity.
  Future<Response> getTeamActivity() => _dio.get('/analytics/activity');

  // ─── Push Notifications ───────────────────────────────────────────────────

  /// Register or update FCM token for push notifications.
  Future<Response> updateFcmToken(String token) =>
      _dio.put('/auth/fcm-token', data: {'token': token});
}



// ✅ RETRY INTERCEPTOR - Automatically retries failed requests (mobile resilience)
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final Function logPrint;
  final int maxRetries = 3;
  final Map<String, int> _requestRetries = {}; // Per-request retry tracking

  RetryInterceptor({required this.dio, required this.logPrint});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Generate unique key for this request to track retries independently
    final requestKey = '${err.requestOptions.method}-${err.requestOptions.path}';
    final retryCount = _requestRetries[requestKey] ?? 0;

    // Retry only on connection errors, timeouts, and 5xx errors
    final shouldRetry = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.unknown ||
        (err.response?.statusCode ?? 0) >= 500;

    if (shouldRetry && retryCount < maxRetries) {
      final newRetryCount = retryCount + 1;
      _requestRetries[requestKey] = newRetryCount;
      final delaySeconds = (1 << (newRetryCount - 1)); // Exponential backoff: 1s, 2s, 4s
      logPrint('🔄 Retry $newRetryCount/$maxRetries after ${delaySeconds}s - ${err.message}');

      await Future.delayed(Duration(seconds: delaySeconds));

      try {
        final response = await dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
          ),
        );
        _requestRetries.remove(requestKey); // Clean up on success
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _requestRetries.remove(requestKey); // Clean up on final failure
    return handler.next(err);
  }
}
