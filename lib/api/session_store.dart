import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el token de refresco (y el celular) para no pedir el código SMS en cada apertura.
///
/// Usa almacenamiento cifrado del sistema:
/// - Android: AES-GCM con la clave protegida por el Android Keystore (RSA OAEP), el modo por
///   defecto de flutter_secure_storage 11. La opción antigua `encryptedSharedPreferences` ya no existe
///   porque Google dejó de mantener Jetpack Security.
/// - iOS: Keychain, accesible después del primer desbloqueo del teléfono (sirve con la pantalla
///   bloqueada, por ejemplo para renovar la sesión durante un SOS).
/// - Web: WebCrypto + localStorage.
///
/// Si en el teléfono quedó una sesión vieja en SharedPreferences (texto plano), se mueve al
/// almacenamiento cifrado la primera vez y se borra de SharedPreferences.
class SessionStore {
  static const _kRefresh = 'nearby.refreshToken';
  static const _kPhone = 'nearby.phone';

  final FlutterSecureStorage _secure;
  Future<void>? _migration;

  SessionStore({FlutterSecureStorage? storage})
    : _secure =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Una sola vez por ejecución: pasa los valores viejos en texto plano al almacenamiento cifrado.
  Future<void> _migrate() => _migration ??= () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in const [_kRefresh, _kPhone]) {
        final old = prefs.getString(key);
        if (old == null) continue;
        if (await _secure.read(key: key) == null) {
          await _secure.write(key: key, value: old);
        }
        await prefs.remove(key);
      }
    } catch (_) {
      // Sin SharedPreferences o sin almacenamiento seguro (pruebas): no hay nada que migrar.
    }
  }();

  Future<String?> readRefreshToken() => _read(_kRefresh);

  Future<String?> readPhone() => _read(_kPhone);

  Future<void> save({required String refreshToken, String? phone}) async {
    await _migrate();
    try {
      await _secure.write(key: _kRefresh, value: refreshToken);
      if (phone != null) await _secure.write(key: _kPhone, value: phone);
    } catch (_) {
      // Sin almacenamiento seguro (modo privado del navegador): la sesión dura lo que la pestaña.
    }
  }

  /// Al cerrar sesión se borra el token. El celular se conserva para no volver a escribirlo.
  Future<void> clear() async {
    await _migrate();
    try {
      await _secure.delete(key: _kRefresh);
    } catch (_) {}
  }

  Future<String?> _read(String key) async {
    await _migrate();
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }
}
