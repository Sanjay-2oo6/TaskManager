import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_client.dart';
import '../core/constants/app_constants.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final Map<String, dynamic>? user;
  final String? message;
  final String? organizationId;
  final String? userRole;

  const AuthState({
    required this.status,
    this.token,
    this.user,
    this.message,
    this.organizationId,
    this.userRole,
  });

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    Map<String, dynamic>? user,
    String? message,
    String? organizationId,
    String? userRole,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
      message: message ?? this.message,
      organizationId: organizationId ?? this.organizationId,
      userRole: userRole ?? this.userRole,
    );
  }

  // Helper methods for role checking
  bool get isSuperAdmin => userRole == 'super_admin';
  bool get isAdmin => userRole == 'admin';
  bool get isMember => userRole == 'member';
  bool get hasOrganization => organizationId != null && organizationId!.isNotEmpty;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);

    try {
      final response = await ApiClient().login(email, password);
      final data = response.data['data'];
      final token = data['token'] as String?;
      final userMap = data['user'] as Map<String, dynamic>?;
      
      // Extract organizationId and role from user data
      final organizationId = userMap?['organizationId']?.toString();
      final userRole = userMap?['role']?.toString() ?? 'member';
      
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setInt(AppConstants.loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
        
        // Store organizationId and role in SharedPreferences
        if (organizationId != null) {
          await prefs.setString('organizationId', organizationId);
        }
        await prefs.setString('userRole', userRole);
        
        ApiClient().setAuthToken(token);
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: userMap,
        organizationId: organizationId,
        userRole: userRole,
      );
    } catch (error) {
      // Extract clean message — avoid leaking Dio internals (URL, headers, etc.)
      String message = 'Login failed. Please try again.';
      try {
        final dynamic err = error;
        if (err?.response?.data?['message'] != null) {
          message = err.response.data['message'].toString();
        }
      } catch (_) {}
      state = state.copyWith(
        status: AuthStatus.failure,
        message: message,
      );
    }
  }

  Future<void> register(
      String name, String email, String password, String role) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);

    try {
      final response = await ApiClient().createUser({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      final data = response.data['data'];
      final token = data['token'] as String?;

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setInt(AppConstants.loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
        ApiClient().setAuthToken(token);
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: data['user'] as Map<String, dynamic>?,
      );
    } catch (error) {
      // Extract clean message — avoid leaking Dio internals
      String message = 'Registration failed. Please try again.';
      try {
        final dynamic err = error;
        if (err?.response?.data?['message'] != null) {
          message = err.response.data['message'].toString();
        }
      } catch (_) {}
      state = state.copyWith(
        status: AuthStatus.failure,
        message: message,
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.loginTimestampKey);
    await prefs.remove('organizationId');
    await prefs.remove('userRole');
    ApiClient().clearAuthToken();

    state = const AuthState(status: AuthStatus.unauthenticated);
    print('✅ Logout complete: Auth state cleared');
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final timestamp = prefs.getInt(AppConstants.loginTimestampKey);
    final organizationId = prefs.getString('organizationId');
    final userRole = prefs.getString('userRole') ?? 'member';

    print('Checking persistent session: Token found = ${token != null}, Timestamp found = ${timestamp != null}');

    if (token == null || timestamp == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final sevenDaysInMs = 7 * 24 * 60 * 60 * 1000;
    final isExpired = DateTime.now().millisecondsSinceEpoch - timestamp > sevenDaysInMs;

    if (isExpired) {
      print('Persistent session EXPIRED (7+ days).');
      await logout();
      return;
    }

    try {
      ApiClient().setAuthToken(token);
      final response = await ApiClient().getMe();
      final data = response.data['data'];
      final userMap = data['user'] as Map<String, dynamic>?;
      final newOrgId = userMap?['organizationId']?.toString();
      final newRole = userMap?['role']?.toString() ?? 'member';
      
      // ✅ SECURITY FIX: Detect organization change and update cache
      if (organizationId != newOrgId && newOrgId != null) {
        print('⚠️ ORGANIZATION CHANGED: Old=$organizationId, New=$newOrgId');
        await prefs.setString('organizationId', newOrgId);
      }
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: userMap,
        organizationId: newOrgId,
        userRole: newRole,
      );
    } catch (e) {
      print('Persistent session verification FAILED: $e');
      final errStr = e.toString();
      
      // 401 = token invalid/revoked → force logout
      if (errStr.contains('401')) {
        print('Token is INVALID (401). Logging out.');
        await logout();
      } else if (errStr.contains('403')) {
        // 403 = forbidden, also force logout
        print('Token is FORBIDDEN (403). Logging out.');
        await logout();
      } else {
        // Genuine network error → keep session optimistically
        print('Network/server error detected. Maintaining optimistic session.');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          organizationId: organizationId,
          userRole: userRole,
        );
      }
    }
  }

  void updateUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }
}

