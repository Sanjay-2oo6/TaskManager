import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/organization.dart';
import '../data/services/api_client.dart';
import 'auth_provider.dart';

// Organization state
class OrganizationState {
  final Organization? currentOrganization;
  final List<Organization> organizations;
  final bool isLoading;
  final String? error;

  OrganizationState({
    this.currentOrganization,
    this.organizations = const [],
    this.isLoading = false,
    this.error,
  });

  OrganizationState copyWith({
    Organization? currentOrganization,
    List<Organization>? organizations,
    bool? isLoading,
    String? error,
  }) {
    return OrganizationState(
      currentOrganization: currentOrganization ?? this.currentOrganization,
      organizations: organizations ?? this.organizations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Get current organization name
  String get currentOrgName {
    return currentOrganization?.name ?? 'No Organization';
  }

  /// Get current organization ID
  String? get currentOrgId {
    return currentOrganization?.id;
  }
}

class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final ApiClient _apiClient;

  OrganizationNotifier(this._apiClient) : super(OrganizationState());

  /// Load all organizations (for super admin only)
  Future<void> loadOrganizations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.getAllOrganizations();
      final data = response.data['data'] as List? ?? [];
      final orgs = data.map((o) => Organization.fromJson(o as Map<String, dynamic>)).toList();
      state = state.copyWith(organizations: orgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.friendlyError(e),
      );
    }
  }

  /// Load specific organization details
  Future<void> loadOrganization(String organizationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.getOrganization(organizationId);
      final orgData = response.data['data'] as Map<String, dynamic>? ?? {};
      final org = Organization.fromJson(orgData);
      state = state.copyWith(currentOrganization: org, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.friendlyError(e),
      );
    }
  }

  /// Switch to a different organization (super admin only)
  void switchOrganization(Organization org) {
    state = state.copyWith(currentOrganization: org);
    print('✅ Switched to organization: ${org.name}');
  }

  /// Clear organization (for logout)
  void clearOrganization() {
    state = state.copyWith(currentOrganization: null);
  }
}

// Providers
final organizationApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final organizationProvider = StateNotifierProvider<OrganizationNotifier, OrganizationState>((ref) {
  final apiClient = ref.watch(organizationApiClientProvider);
  return OrganizationNotifier(apiClient);
});

// Current organization display name provider
final currentOrgDisplayNameProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final orgState = ref.watch(organizationProvider);

  if (authState.isSuperAdmin) {
    return orgState.currentOrgName;
  }

  return authState.user?['organizationId'] != null ? 'Organization' : 'No Organization';
});

// Check if user can manage organizations (super admin only)
final canManageOrganizationsProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isSuperAdmin;
});
