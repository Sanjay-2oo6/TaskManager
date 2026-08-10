import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import 'ota_service_stub.dart'
    if (dart.library.io) 'ota_service_mobile.dart';

class UpdateService {
  /**
   * Checks the server for a newer version of the application.
   * Returns a map with 'updateAvailable', 'version', and 'url' if found.
   */
  static Future<Map<String, dynamic>> checkUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentFullVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
      debugPrint('🔍 Local Version: $currentFullVersion');

      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/app/version'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final String serverVersion = data['version']; // e.g., "1.1.0+4"
        debugPrint('📡 Server Version: $serverVersion');
        
        bool updateAvailable = _isVersionGreater(serverVersion, currentFullVersion);

        return {
          'updateAvailable': updateAvailable,
          'version': serverVersion,
          'androidUrl': data['androidUrl'],
          'desktopUrl': data['desktopUrl'],
          'releaseNotes': data['releaseNotes'] ?? "New features and fixes."
        };
      }
    } catch (e) {
      debugPrint('❌ Update Check Failed: $e');
    }
    return {'updateAvailable': false};
  }

  /**
   * Triggers the platform-specific update flow.
   */
  static Future<void> performUpdate(String url, {Function(String, double)? onProgress}) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Android specific OTA installation
        OtaService.execute(url, onProgress: (status, pct) {
          if (onProgress != null) onProgress(status, pct);
        });
      } catch (e) {
        debugPrint('❌ OTA Update Error: $e');
        // Fallback to browser download if OTA fails
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      // Desktop/Web fallback: Open download link in browser
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  static bool _isVersionGreater(String serverVersion, String currentVersion) {
    try {
      // Split version and build number: "1.1.0+4" -> ["1.1.0", "4"]
      List<String> serverParts = serverVersion.split('+');
      List<String> currentParts = currentVersion.split('+');

      // 1. Compare semantic version (1.1.0)
      List<int> v1 = serverParts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> v2 = currentParts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < v1.length; i++) {
        if (i >= v2.length) return true;
        if (v1[i] > v2[i]) return true;
        if (v1[i] < v2[i]) return false;
      }

      // 2. If semantic versions are equal, compare build numbers (the part after +)
      if (serverParts.length > 1 && currentParts.length > 1) {
        int b1 = int.tryParse(serverParts[1]) ?? 0;
        int b2 = int.tryParse(currentParts[1]) ?? 0;
        return b1 > b2;
      } else if (serverParts.length > 1) {
        // Server has a build number but client doesn't (server is likely newer)
        return true;
      }
    } catch (e) {
      debugPrint('❌ Version Sync Error: $e');
    }
    return false;
  }
}
