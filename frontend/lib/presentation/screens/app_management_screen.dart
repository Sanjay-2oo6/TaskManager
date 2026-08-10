import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';
import '../../state/task_providers.dart';
import '../../data/services/update_service.dart';
import '../../data/services/api_client.dart';

class AppManagementScreen extends ConsumerStatefulWidget {
  const AppManagementScreen({super.key});

  @override
  ConsumerState<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends ConsumerState<AppManagementScreen> {
  final _versionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0;
  PlatformFile? _selectedApk;
  dynamic _currentConfig;
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentVersion();
  }

  Future<void> _fetchCurrentVersion() async {
    try {
      final config = await UpdateService.checkUpdate();
      setState(() {
        _currentConfig = config;
        _versionController.text = config['version'] ?? '';
        _notesController.text = config['releaseNotes'] ?? '';
        _isLoadingConfig = false;
      });
    } catch (e) {
      debugPrint('Error fetching version: $e');
      setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _pickApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );

    if (result != null) {
      setState(() => _selectedApk = result.files.first);
    }
  }

  Future<void> _publishUpdate() async {
    if (_versionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify a version number'))
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1; // Start progress
    });

    try {
      // In a real implementation with a progress-enabled HTTP client:
      // We would use Dio or similar to track upload progress.
      // For now, we simulate progress and call our backend.
      
      final apiClient = ApiClient();
      await apiClient.deployNewVersion(
        version: _versionController.text,
        notes: _notesController.text,
        apkFile: _selectedApk,
      );


      setState(() => _uploadProgress = 1.0);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚀 Version Published Successfully!'),
          backgroundColor: AppTheme.successGreen,
        )
      );
      
      _fetchCurrentVersion();
      setState(() {
        _isUploading = false;
        _selectedApk = null;
      });
      
      // Auto-close page after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deployment failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('App Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: _isLoadingConfig 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 32),
                  const Text('Deploy New Version', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  _buildDeploymentForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.secondaryBlue, Color(0xFF6C8DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.secondaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Current Fleet Version', style: TextStyle(color: Colors.white70, fontSize: 13)),
                   Text('v${_currentConfig?['version'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Text('Last Notes: ${_currentConfig?['releaseNotes'] ?? 'None'}', 
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Version Number', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _versionController,
            decoration: _inputDecoration('e.g. 1.0.2'),
          ),
          const SizedBox(height: 20),
          const Text('Release Notes', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: _inputDecoration('What\'s new in this version?'),
          ),
          const SizedBox(height: 24),
          const Text('Android Package (APK)', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          _buildFilePicker(),
          const SizedBox(height: 32),
          if (_isUploading)
            Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress, borderRadius: BorderRadius.circular(10), minHeight: 8),
                const SizedBox(height: 8),
                Text('${(_uploadProgress * 100).toInt()}% Uploading...', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _publishUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text('Publish Update to Fleet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickApk,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3), width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(15),
          color: AppTheme.secondaryBlue.withOpacity(0.02),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppTheme.secondaryBlue, size: 40),
            const SizedBox(height: 12),
            Text(_selectedApk != null ? _selectedApk!.name : 'Click to select APK file', 
              style: TextStyle(color: _selectedApk != null ? AppTheme.textDark : AppTheme.textMuted, fontWeight: FontWeight.w500)),
            if (_selectedApk != null)
               Text('${(_selectedApk!.size / 1024 / 1024).toStringAsFixed(2)} MB', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.backgroundLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
