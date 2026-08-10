import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'worker';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBg, Color(0xFF071412)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.pineGlass,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppTheme.champagneGold.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'OPERATOR REGISTRATION',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.champagneGold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Establish your secure credentials',
                          style: TextStyle(fontSize: 11, color: AppTheme.mutedForest, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 40),
                        _buildField(_nameController, 'Full Identity Name', Icons.badge_outlined),
                        const SizedBox(height: 16),
                        _buildField(_emailController, 'Secure Email Address', Icons.alternate_email_rounded),
                        const SizedBox(height: 16),
                        _buildField(_passwordController, 'Access Token (Password)', Icons.lock_open_rounded, obscure: true),
                        const SizedBox(height: 16),
                        
                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: _role,
                          dropdownColor: AppTheme.pineGlass,
                          style: const TextStyle(color: AppTheme.champagneGold, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Operational Role',
                            labelStyle: TextStyle(color: AppTheme.mutedForest),
                            prefixIcon: Icon(Icons.security_rounded, color: AppTheme.champagneGold),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'worker', child: Text('Operator (Worker)')),
                            DropdownMenuItem(value: 'employee', child: Text('Employee')),
                            // Note: admin/assigner accounts must be created by an existing admin
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                        
                        const SizedBox(height: 40),
                        if (authState.status == AuthStatus.loading)
                          const CircularProgressIndicator(color: AppTheme.champagneGold)
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.champagneGold,
                                foregroundColor: AppTheme.darkBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('INITIALIZE PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                        
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Secure Login', style: TextStyle(color: AppTheme.mutedForest, fontSize: 13)),
                        ),

                        if (authState.message != null && authState.status == AuthStatus.failure) ...[
                          const SizedBox(height: 16),
                          Text(authState.message!, style: const TextStyle(color: AppTheme.copperBlaze, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.champagneGold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.mutedForest),
        prefixIcon: Icon(icon, color: AppTheme.champagneGold, size: 20),
        filled: true,
        fillColor: AppTheme.darkBg.withValues(alpha: 0.4),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }
}
