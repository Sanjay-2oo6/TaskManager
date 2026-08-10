class User {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String? organizationId;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.organizationId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      organizationId: json['organizationId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'organizationId': organizationId,
    };
  }

  // Check if user is super admin
  bool get isSuperAdmin => role == 'super_admin';

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Check if user is member
  bool get isMember => role == 'member';

  // Check if user has organization context
  bool get hasOrganization => organizationId != null && organizationId!.isNotEmpty;

  // Get display name for organization
  String getOrgDisplayName(String? orgName) {
    if (isSuperAdmin) return 'Super Admin';
    if (!hasOrganization) return 'No Organization';
    return orgName ?? 'Organization';
  }

  // Copy with method for updates
  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? role,
    String? organizationId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
