import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/app_theme.dart';

/// Screen for creating a new organization (Super Admin only)
class OrganizationCreationScreen extends ConsumerStatefulWidget {
  const OrganizationCreationScreen({super.key});

  @override
  ConsumerState<OrganizationCreationScreen> createState() =>
      _OrganizationCreationScreenState();
}

class _OrganizationCreationScreenState
    extends ConsumerState<OrganizationCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _memberLimitController = TextEditingController(text: '10');

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _memberLimitController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await ApiClient().createOrganization({
        'name': _nameController.text.trim(),
        'slug': _slugController.text.trim(),
        'adminName': _adminNameController.text.trim(),
        'adminEmail': _adminEmailController.text.trim(),
        'adminPassword': _adminPasswordController.text,
        'memberLimit': int.tryParse(_memberLimitController.text) ?? 10,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _successMessage = 'Organization created successfully!';
          _nameController.clear();
          _slugController.clear();
          _adminNameController.clear();
          _adminEmailController.clear();
          _adminPasswordController.clear();
          _memberLimitController.text = '10';
        });

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organization created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      String errorMsg = 'Failed to create organization';
      if (error is Exception) {
        errorMsg = ApiClient.friendlyError(error);
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'Create Organization',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.business_rounded,
                    color: AppTheme.accentPurple,
                    size: 32,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Create New Organization',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Set up a new organization with admin credentials',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Success message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization name
                  const Text(
                    'Organization Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Acme Corporation',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Organization name is required';
                      }
                      if (value.length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Slug
                  const Text(
                    'Organization Slug',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _slugController,
                    decoration: InputDecoration(
                      hintText: 'e.g., acme-corp (URL-friendly)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Slug is required';
                      }
                      if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(value)) {
                        return 'Slug must be lowercase letters, numbers, and hyphens only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Admin name
                  const Text(
                    'Admin Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _adminNameController,
                    decoration: InputDecoration(
                      hintText: 'Full name of organization admin',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Admin name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Admin email
                  const Text(
                    'Admin Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _adminEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'admin@organization.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Admin email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Admin password
                  const Text(
                    'Admin Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _adminPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Min 8 chars, with uppercase, lowercase, number, special char',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Member limit
                  const Text(
                    'Member Limit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _memberLimitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Number of allowed members (e.g., 10, 50, 100)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Member limit is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createOrganization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Organization',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
