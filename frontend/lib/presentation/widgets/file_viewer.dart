import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(url),
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
