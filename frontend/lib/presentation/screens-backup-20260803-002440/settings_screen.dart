import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_client.dart';
import '../../state/auth_provider.dart';
import 'app_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _nameController.text = user['name']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final password = _passwordController.text.isNotEmpty ? _passwordController.text : null;
      
      final response = await ApiClient().updateSelfProfile({
        if (name.isNotEmpty) 'name': name,
        if (password != null) 'password': password,
      });
      final updatedData = response.data['data'];

      // Force update the auth provider with new data
      ref.read(authNotifierProvider.notifier).updateUser(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.successGreen),
        );
        _passwordController.clear(); // Clear password field for safety
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.primaryCoral),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update your display name and security credentials.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 32),
                  
                  // Full Name Field
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryCoral),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Password Field
                  const Text('New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      hintText: 'Enter new password (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryCoral),
                      ),
                    ),
                    validator: (v) => v!.isNotEmpty && v.length < 6 
                        ? 'Password must be at least 6 characters' 
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '* Leave password blank if you do not want to change it.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCoral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Admin Version Management Section
                  if (ref.watch(authNotifierProvider).user?['role'] == 'admin' || 
                      ref.watch(authNotifierProvider).user?['role'] == 'master') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: AppTheme.borderLight),
                    ),
                    const Text('Software Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AppManagementScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.secondaryBlue.withOpacity(0.05),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.system_update_alt_rounded, color: AppTheme.secondaryBlue, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Deploy App Updates',
                              style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right_rounded, color: AppTheme.secondaryBlue),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
