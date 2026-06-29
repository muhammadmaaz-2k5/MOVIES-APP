import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppConfig {
  static String get backendBaseUrl {
    if (kReleaseMode) {
      return 'https://moviebox.nazaarabox.com';
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Android emulator resolves host localhost as 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String get tmdbProxyUrl => '$backendBaseUrl/api/tmdb';
}
