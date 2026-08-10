import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite, // Pure white background
      body: Row(
        children: [
          // Left Side - Login Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Branding
                        const Text(
                          'INNO TECH HUB',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome back! Please login to your account.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 48),

                        // Form Fields
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: AppTheme.textDark),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: const TextStyle(color: AppTheme.textMuted),
                            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.surfaceWhite,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryCoral, width: 2),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Username required' : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: AppTheme.textDark),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: AppTheme.textMuted),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.surfaceWhite,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryCoral, width: 2),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Password required' : null,
                        ),
                        const SizedBox(height: 40),

                        // Login Button
                        if (authState.status == AuthStatus.loading)
                          const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral))
                        else
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryCoral,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                        // Error Message
                        if (authState.message != null && authState.status == AuthStatus.failure) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCoral.withValues(alpha: 0.1), 
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              authState.message!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right Side - Illustration / Branding Area (Desktop Only)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundLight,
                  border: Border(left: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, size: 100, color: AppTheme.secondaryBlue),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Boost Your Productivity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Manage your tasks and team effortlessly.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
