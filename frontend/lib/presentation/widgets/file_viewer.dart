import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class FileViewer extends StatelessWidget {
  final List<String> fileUrls;
  final List<String> fileNames;

  const FileViewer({
    required this.fileUrls,
    required this.fileNames,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fileUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FILES', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(fileUrls.length, (index) {
            final url = fileUrls[index];
            final fileName = fileNames.isNotEmpty && index < fileNames.length
                ? fileNames[index]
                : 'File ${index + 1}';
            final isImage = _isImageUrl(url);

            return GestureDetector(
              onTap: () => isImage
                  ? _showImageViewer(context, url, fileName)
                  : _downloadOrOpenFile(url, fileName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.secondaryBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isImage ? Icons.image_rounded : Icons.file_download_rounded,
                      color: AppTheme.secondaryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp');
  }

  void _showImageViewer(BuildContext context, String url, String fileName) {
    // ✅ FIX 16: Use backend proxy for S3 files to bypass CORS issues on localhost
    // Extract S3 key from URL if it's an S3 URL, otherwise use as-is
    String imageUrl = url;
    if (url.contains('amazonaws.com') && url.contains('/')) {
      // URL format: https://bucket.s3.region.amazonaws.com/key
      // Extract just the key part
      final parts = url.split('.com/');
      if (parts.length == 2) {
        final key = parts[1].split('?')[0]; // Remove query params
        // Use backend proxy with proper server URL (works in dev and production)
        imageUrl = '${AppConstants.serverUrl}/api/v1/tasks/file-proxy?key=$key';
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ✅ FIX 15: Add error handling for image loading
              FutureBuilder<String>(
                future: _resolveImageUrl(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      color: Colors.black87,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          const Text('Failed to load image', style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error?.toString() ?? 'Unknown error',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black87,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            const Text('Failed to load image', style: TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolve the image URL, handling backend proxy responses
  Future<String> _resolveImageUrl(String url) async {
    try {
      // If it's a proxy URL, fetch the actual signed URL from the backend
      if (url.contains('/file-proxy')) {
        final response = await _getProxyUrl(url);
        return response;
      }
      return url;
    } catch (e) {
      throw Exception('Failed to resolve image URL: $e');
    }
  }

  /// Fetch the actual file URL from the backend proxy
  Future<String> _getProxyUrl(String proxyUrl) async {
    try {
      final uri = Uri.parse(proxyUrl);
      
      // ✅ SECURITY: Include auth token for protected endpoint
      // Get token from secure storage
      const tokenKey = 'auth_token';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['url'];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required - please log in again');
      }
      throw Exception('Failed to get proxy URL: ${response.statusCode}');
    } catch (e) {
      throw Exception('Proxy request failed: $e');
    }
  }

  Future<void> _downloadOrOpenFile(String url, String fileName) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }
}
