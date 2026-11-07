import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el token de refresco para no pedir el código SMS en cada apertura.
class SessionStore {
  static const _kRefresh = 'nearby.refreshToken';
  static const _kPhone = 'nearby.phone';

  Future<String?> readRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRefresh);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kPhone);
    } catch (_) {
      return null;
    }
  }

  Future<void> save({required String refreshToken, String? phone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRefresh, refreshToken);
      if (phone != null) await prefs.setString(_kPhone, phone);
    } catch (_) {
      // Sin almacenamiento (modo privado del navegador): la sesión dura lo que la pestaña.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kRefresh);
    } catch (_) {}
  }
}
