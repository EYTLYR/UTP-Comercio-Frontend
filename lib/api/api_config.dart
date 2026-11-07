import 'package:flutter/foundation.dart';

/// URL del backend (Nearby API, Spring Boot).
///
/// Se cambia al compilar: `flutter run --dart-define=API_URL=https://mi-api.example`.
/// Sin API_URL: en web y escritorio usa http://localhost:8080; en el emulador de
/// Android, http://10.0.2.2:8080 (el localhost de la PC). En un celular físico hay
/// que pasar la IP de la PC en la red, por ejemplo http://192.168.1.20:8080.
class ApiConfig {
  static const String _fromEnv = String.fromEnvironment('API_URL');

  static String get baseUrl {
    final url = _fromEnv.isNotEmpty ? _fromEnv : _defaultUrl();
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String _defaultUrl() {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// URL absoluta de un archivo servido por la API (por ejemplo /files/abc.jpg).
  static String fileUrl(String path) =>
      path.startsWith('http') ? path : '$baseUrl$path';

  static const Duration timeout = Duration(seconds: 15);
}
