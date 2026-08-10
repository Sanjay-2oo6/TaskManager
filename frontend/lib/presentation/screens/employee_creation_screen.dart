import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';

class EmployeeCreationScreen extends ConsumerStatefulWidget {
  const EmployeeCreationScreen({super.key});

  @override
  ConsumerState<EmployeeCreationScreen> createState() => _EmployeeCreationScreenState();
}

class _EmployeeCreationScreenState extends ConsumerState<EmployeeCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'member';
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiClient().createUser({
        'name': _nameController.text.trim(),
        'email': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': _selectedRole,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operator profile synchronized successfully'), backgroundColor: AppTheme.sageMint),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Sync Error: ${e.toString()}'), backgroundColor: AppTheme.copperBlaze),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('PROVISION OPERATOR', style: TextStyle(color: AppTheme.champagneGold, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.champagneGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.pineGlass,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppTheme.champagneGold.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_rounded, color: AppTheme.champagneGold, size: 24),
                        SizedBox(width: 12),
                        Text('ORGANIZATION SETUP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.champagneGold, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Establish a new secure identity for the workspace.', style: TextStyle(color: AppTheme.mutedForest, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 48),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Identity Name',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Operation Handle (Username)',
                      icon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Access Key (Password)',
                      icon: Icons.lock_open_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      dropdownColor: AppTheme.pineGlass,
                      style: const TextStyle(color: AppTheme.champagneGold, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('Operational Role', Icons.security_rounded),
                      items: const [
                        DropdownMenuItem(value: 'member', child: Text('Standard Operator')),
                        DropdownMenuItem(value: 'admin', child: Text('Command (Admin)')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 48),

                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.champagneGold))
                      : SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _createUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.champagneGold,
                              foregroundColor: AppTheme.darkBg,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: const Text('INITIALIZATION ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.mutedForest, fontSize: 12, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: AppTheme.champagneGold, size: 20),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.champagneGold)),
      filled: true,
      fillColor: AppTheme.darkBg.withValues(alpha: 0.4),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppTheme.champagneGold, fontSize: 14),
      decoration: _inputDecoration(label, icon),
      validator: (val) => val == null || val.isEmpty ? 'Intelligence required' : null,
    );
  }
}
