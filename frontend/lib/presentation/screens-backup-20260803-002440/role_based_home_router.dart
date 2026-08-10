import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_provider.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'member_dashboard_screen.dart';
import 'super_admin_dashboard_screen.dart';

/// Role-based router that automatically navigates to the correct dashboard
/// based on user role without any manual selection
class RoleBasedHomeRouter extends ConsumerWidget {
  const RoleBasedHomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    // Get the user role from auth state
    final userRole = authState.userRole?.toLowerCase() ?? 'member';
    
    // Log for debugging
    print('🎯 Route based on role: $userRole');
    
    // Route to correct dashboard based on role
    switch (userRole) {
      case 'super_admin':
        return const SuperAdminDashboardScreen();
      case 'admin':
        return const AdminDashboardScreen();
      case 'member':
      default:
        return const MemberDashboardScreen();
    }
  }
}
