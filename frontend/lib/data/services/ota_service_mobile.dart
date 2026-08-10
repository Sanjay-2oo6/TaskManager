import 'package:ota_update/ota_update.dart';

class OtaService {
  static void execute(String url, {required Function(String, double) onProgress}) {
    try {
      // Use a unique filename based on the URL or timestamp to avoid corrupted cache issues
      final String filename = "update_${DateTime.now().millisecondsSinceEpoch}.apk";
      
      OtaUpdate()
        .execute(url, destinationFilename: filename)
        .listen((OtaEvent event) {
          String statusText = "Processing...";
          double progress = 0;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              progress = double.tryParse(event.value ?? "0") ?? 0;
              statusText = "Downloading... ${progress.toInt()}%";
              break;
            case OtaStatus.INSTALLING:
              statusText = "Launching installer...";
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              statusText = "Error: Permission denied.";
              break;
            case OtaStatus.INTERNAL_ERROR:
              statusText = "Update failed. Please try again.";
              break;
            default:
              statusText = "Updating...";
          }
          
          onProgress(statusText, progress);
        });
    } catch (e) {
      onProgress("Update error: $e", 0);
    }
  }
}
