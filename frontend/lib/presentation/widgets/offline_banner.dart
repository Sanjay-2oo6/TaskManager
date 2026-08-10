import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/sync_status_provider.dart';
import '../../core/theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(syncStatusProvider);

    if (isOnline) return const SizedBox.shrink();

    return Container(
      color: Colors.red[600],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are offline. Changes will sync when back online.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
