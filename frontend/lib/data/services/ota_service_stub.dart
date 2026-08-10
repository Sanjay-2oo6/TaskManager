import 'package:flutter/foundation.dart';

class OtaService {
  static void execute(String url, {required Function(String, double) onProgress}) {
    debugPrint('OTA Update is not available on this platform.');
  }
}
