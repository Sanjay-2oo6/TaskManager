import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../state/organization_provider.dart';

/// Displays current organization information in app bar or header
class OrganizationIndicator extends ConsumerWidget {
  final TextStyle? textStyle;
  final double? fontSize;
  final Color? color;

  const OrganizationIndicator({
    Key? key,
    this.textStyle,
    this.fontSize,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final orgState = ref.watch(organizationProvider);

    if (!authState.isAuthenticated) {
      return SizedBox.shrink();
    }

    // Super admin shows current organization
    if (authState.isSuperAdmin) {
      final orgName = orgState.currentOrganization?.name ?? 'Select Organization';
      return Text(
        '🏢 $orgName',
        style: textStyle ?? TextStyle(
          fontSize: fontSize ?? 14,
          color: color ?? Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Regular admin/member shows organization (if exists)
    if (authState.hasOrganization) {
      return Text(
        '🏢 Organization',
        style: textStyle ?? TextStyle(
          fontSize: fontSize ?? 14,
          color: color ?? Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // No organization
    return Text(
      'Not in an Organization',
      style: textStyle ?? TextStyle(
        fontSize: fontSize ?? 14,
        color: color ?? Colors.orange,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Full organization info card
class OrganizationCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const OrganizationCard({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final orgState = ref.watch(organizationProvider);

    if (!authState.hasOrganization) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '⚠️ You are not part of any organization',
            style: TextStyle(color: Colors.orange),
          ),
        ),
      );
    }

    final org = orgState.currentOrganization;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.business),
        title: Text(org?.name ?? 'Organization'),
        subtitle: Text(org?.slug ?? 'org-slug'),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Organization switcher for super admin
class OrganizationSwitcher extends ConsumerWidget {
  final VoidCallback? onOrganizationSelected;

  const OrganizationSwitcher({
    Key? key,
    this.onOrganizationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final orgState = ref.watch(organizationProvider);

    // Only show for super admin
    if (!authState.isSuperAdmin) {
      return SizedBox.shrink();
    }

    final orgs = orgState.organizations;
    final currentOrgId = orgState.currentOrgId;

    if (orgs.isEmpty) {
      return Text('No organizations available');
    }

    return DropdownButton<String>(
      value: currentOrgId ?? orgs.first.id,
      onChanged: (value) {
        if (value != null) {
          final org = orgs.firstWhere((o) => o.id == value);
          ref.read(organizationProvider.notifier).switchOrganization(org);
          onOrganizationSelected?.call();
        }
      },
      items: orgs.map((org) {
        return DropdownMenuItem<String>(
          value: org.id,
          child: Text('${org.name} (${org.memberCount} members)'),
        );
      }).toList(),
    );
  }
}

/// Mini badge showing organization affiliation
class OrganizationBadge extends ConsumerWidget {
  final double? size;

  const OrganizationBadge({
    Key? key,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isSuperAdmin) {
      return Chip(
        label: Text('Super Admin'),
        backgroundColor: Colors.purple[100],
        labelStyle: TextStyle(color: Colors.purple[900]),
        avatar: Icon(Icons.security, size: 16, color: Colors.purple[900]),
      );
    }

    if (!authState.hasOrganization) {
      return SizedBox.shrink();
    }

    String roleLabel = authState.isMember ? 'Member' : 'Admin';
    Color roleColor = authState.isMember ? Colors.blue : Colors.green;

    return Chip(
      label: Text(roleLabel),
      backgroundColor: roleColor.withOpacity(0.2),
      labelStyle: TextStyle(color: roleColor),
      avatar: Icon(
        authState.isMember ? Icons.person : Icons.admin_panel_settings,
        size: 16,
        color: roleColor,
      ),
    );
  }
}

// Extension on AuthState for easier checks
extension AuthStateExtension on AuthState {
  bool get isAuthenticated => status == AuthStatus.authenticated;
}
