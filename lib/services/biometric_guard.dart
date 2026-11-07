import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Pide huella, rostro o el PIN/patrón del teléfono antes de una acción sensible
/// (ver o editar la ficha médica, cerrar un SOS activo).
///
/// Devuelve true si el vecino se identificó. También devuelve true cuando el teléfono no tiene
/// ningún bloqueo configurado, en web y en pruebas (sin el plugin): ahí no hay con qué verificar
/// y bloquear dejaría al vecino sin acceso a su propia ficha.
class BiometricGuard {
  final LocalAuthentication _auth;

  BiometricGuard({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  Future<bool> authorize(String reason) async {
    if (kIsWeb) return true;
    try {
      if (!await _auth.isDeviceSupported()) return true;
      return await _auth.authenticate(
        localizedReason: reason,
        // Huella o rostro, y si no, el PIN/patrón del teléfono.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on MissingPluginException {
      return true;
    } on LocalAuthException catch (e) {
      // Sin bloqueo de pantalla configurado: no hay credencial que pedir.
      return e.code == LocalAuthExceptionCode.noCredentialsSet;
    } catch (_) {
      return false;
    }
  }
}
