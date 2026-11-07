import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Ubicación del teléfono o dispositivo. Detecta primero el GPS físico del móvil.
/// Si está en navegador sin GPS satelital o no hay permiso, obtiene la ubicación real por IP.
class LocationService {
  static const double fallbackLat = -11.9790;
  static const double fallbackLng = -77.0030;

  ({double lat, double lng, bool real, String? city, String? region})? last;

  Future<({double lat, double lng, bool real, String? city, String? region})> current() async {
    // 1. Intentar con GPS del dispositivo (Geolocator)
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          last = (
            lat: lastKnown.latitude,
            lng: lastKnown.longitude,
            real: true,
            city: null,
            region: null,
          );
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
        return last = (
          lat: pos.latitude,
          lng: pos.longitude,
          real: true,
          city: null,
          region: null,
        );
      }
    } catch (_) {}

    // 2. Si el GPS satelital no está disponible o tarda, obtener ubicación real de la red/IP
    final ipPos = await _getIpLocation();
    if (ipPos != null) {
      return last = ipPos;
    }

    // 3. Fallback en caso de no tener internet ni GPS
    return _fallback();
  }

  Future<({double lat, double lng, bool real, String? city, String? region})?> _getIpLocation() async {
    try {
      final res = await http.get(Uri.parse('https://ipwho.is/')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          final city = data['city'] as String?;
          final region = data['region'] as String?;
          return (lat: lat, lng: lng, real: true, city: city, region: region);
        }
      }
    } catch (_) {}

    try {
      final res = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          final city = data['city'] as String?;
          final region = data['region'] as String?;
          return (lat: lat, lng: lng, real: true, city: city, region: region);
        }
      }
    } catch (_) {}

    return null;
  }

  ({double lat, double lng, bool real, String? city, String? region}) _fallback() =>
      last ?? (
        lat: fallbackLat,
        lng: fallbackLng,
        real: false,
        city: null,
        region: null,
      );
}
