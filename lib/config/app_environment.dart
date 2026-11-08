import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Public app configuration. Release builds never include development controls.
abstract final class AppEnvironment {
  static const _definedName = String.fromEnvironment('APP_ENV');
  static String? _fileName;
  static String? _apiUrl;
  static String get apiBaseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    if (_apiUrl != null && _apiUrl!.isNotEmpty) return _apiUrl!;
    if (kReleaseMode) return '';
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'https://nearby-api.eytlyr.com'
        : 'https://nearby-api.eytlyr.com';
  }

  static String get name => _definedName.isNotEmpty
      ? _definedName
      : _fileName ?? (kReleaseMode ? 'production' : 'development');

  static bool get showDevelopmentTools =>
      !kReleaseMode && name == 'development';

  /// Called before runApp; a full restart reloads the bundled .env file.
  static Future<void> load({AssetBundle? bundle}) async {
    _fileName = null;
    _apiUrl = null;
    try {
      final content = await (bundle ?? rootBundle).loadString('.env');
      for (var line
          in content.replaceFirst(RegExp(r'^\uFEFF'), '').split('\n')) {
        line = line.trim();
        if (line.startsWith('export ')) line = line.substring(7).trimLeft();
        final match = RegExp(r'^(APP_ENV|API_BASE_URL)\s*=\s*(.*)$')
            .firstMatch(line);
        if (match == null) continue;
        var value = match.group(2)!.trim();
        if (value.startsWith('"') || value.startsWith("'")) {
          final end = value.indexOf(value[0], 1);
          value = end < 0 ? '' : value.substring(1, end);
        } else {
          value = value.split(RegExp(r'\s+#')).first.trim();
        }
        if (match.group(1) == 'APP_ENV') {
          _fileName = value;
        } else {
          _apiUrl = value;
        }
      }
    } on FlutterError {
      // A missing asset falls back to the build-mode defaults above.
    }
  }
}
