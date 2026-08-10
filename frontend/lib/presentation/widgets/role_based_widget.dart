import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';

/// Widget that shows content based on user role
class RoleBasedWidget extends ConsumerWidget {
  final Widget? superAdminWidget;
  final Widget? adminWidget;
  final Widget? memberWidget;
  final Widget? fallbackWidget;

  const RoleBasedWidget({
    Key? key,
    this.superAdminWidget,
    this.adminWidget,
    this.memberWidget,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isSuperAdmin) {
      return superAdminWidget ?? fallbackWidget ?? SizedBox.shrink();
    } else if (authState.isAdmin) {
      return adminWidget ?? fallbackWidget ?? SizedBox.shrink();
    } else if (authState.isMember) {
      return memberWidget ?? fallbackWidget ?? SizedBox.shrink();
    }

    return fallbackWidget ?? SizedBox.shrink();
  }
}

/// Builder widget for role-based UI
class RoleBasedBuilder extends ConsumerWidget {
  final Widget Function(BuildContext, String role, WidgetRef) builder;

  const RoleBasedBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.userRole ?? 'member';

    return builder(context, role, ref);
  }
}

/// Widget that shows/hides based on role condition
class ConditionalRoleWidget extends ConsumerWidget {
  final bool Function(String role) shouldShow;
  final Widget child;
  final Widget? replacement;

  const ConditionalRoleWidget({
    Key? key,
    required this.shouldShow,
    required this.child,
    this.replacement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.userRole ?? 'member';

    if (shouldShow(role)) {
      return child;
    }

    return replacement ?? SizedBox.shrink();
  }
}

/// Extension for easy role checking
extension RoleCheckExtension on String? {
  bool get isSuperAdmin => this == 'super_admin';
  bool get isAdmin => this == 'admin';
  bool get isMember => this == 'member';
}
