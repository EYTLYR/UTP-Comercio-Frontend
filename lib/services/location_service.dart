import 'package:geolocator/geolocator.dart';

/// Ubicación del teléfono. Si no hay GPS o permiso, usa el centro de la zona
/// (Jr. Las Flores 245) para que el SOS nunca se quede sin enviar.
class LocationService {
  static const double fallbackLat = -11.9790;
  static const double fallbackLng = -77.0030;

  ({double lat, double lng, bool real})? last;

  Future<({double lat, double lng, bool real})> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _fallback();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return _fallback();
      }
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        last = (lat: lastKnown.latitude, lng: lastKnown.longitude, real: true);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return last = (lat: pos.latitude, lng: pos.longitude, real: true);
    } catch (_) {
      return _fallback();
    }
  }

  ({double lat, double lng, bool real}) _fallback() =>
      last ?? (lat: fallbackLat, lng: fallbackLng, real: false);
}
