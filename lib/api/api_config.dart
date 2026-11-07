import '../config/app_environment.dart';

/// URL del backend (Nearby API, Spring Boot).
///
/// Se lee API_BASE_URL desde .env. Opcionalmente se cambia al compilar: `flutter run --dart-define=API_URL=https://mi-api.example`.
/// Sin API_URL: en web y escritorio usa http://localhost:8080; en el emulador de
/// Android, http://10.0.2.2:8080 (el localhost de la PC). En un celular físico hay
/// que pasar la IP de la PC en la red, por ejemplo http://192.168.1.20:8080.
class ApiConfig {
  static const String _fromEnv = String.fromEnvironment('API_URL');

  static String get baseUrl {
    final url = _fromEnv.isNotEmpty ? _fromEnv : AppEnvironment.apiBaseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// URL absoluta de un archivo servido por la API (por ejemplo /files/abc.jpg).
  static String fileUrl(String path) =>
      path.startsWith('http') ? path : '$baseUrl$path';

  static const Duration timeout = Duration(seconds: 15);
}
