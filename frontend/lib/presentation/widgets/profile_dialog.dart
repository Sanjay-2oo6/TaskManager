import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../data/services/api_client.dart';

class ProfileDialog extends ConsumerStatefulWidget {
  const ProfileDialog({super.key});

  @override
  ConsumerState<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<ProfileDialog> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppTheme.copperBlaze),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final response = await ApiClient().updateSelfProfile({
        'name': _nameController.text.trim(),
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text.trim(),
      });
      
      ref.read(authNotifierProvider.notifier).updateUser(response.data['data']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppTheme.sageMint),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.copperBlaze),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    if (user == null) return const SizedBox.shrink();

    final username = user['username'] ?? 'anonymous';
    final isMaster = username.toString().toLowerCase() == 'sanjay';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.pineGlass,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.champagneGold.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: -10)
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.darkBg,
                    child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.champagneGold)),
                  ),
                  if (isMaster)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.champagneGold, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.darkBg),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(_nameController.text.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.champagneGold, letterSpacing: 1)),
              Text('@$username', style: const TextStyle(color: AppTheme.mutedForest, fontWeight: FontWeight.bold, fontSize: 13)),
              if (isMaster)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.champagneGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.champagneGold.withValues(alpha: 0.2))),
                  child: const Text('MASTER ADMIN', style: TextStyle(color: AppTheme.champagneGold, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                ),
              const SizedBox(height: 32),
              const Divider(color: AppTheme.mutedForest, thickness: 0.5),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ACCOUNT SETTINGS', style: TextStyle(color: AppTheme.mutedForest, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.champagneGold, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  hintStyle: TextStyle(color: AppTheme.champagneGold.withValues(alpha: 0.3)),
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.champagneGold, size: 20),
                  filled: true,
                  fillColor: AppTheme.darkBg.withValues(alpha: 0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.champagneGold),
                decoration: InputDecoration(
                  hintText: 'Change Password (Optional)',
                  hintStyle: TextStyle(color: AppTheme.champagneGold.withValues(alpha: 0.3), fontSize: 10),
                  prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.champagneGold, size: 20),
                  filled: true,
                  fillColor: AppTheme.darkBg.withValues(alpha: 0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.champagneGold,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isUpdating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  Navigator.pop(context);
                },
                child: const Text('LOGOUT', style: TextStyle(color: AppTheme.copperBlaze, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
