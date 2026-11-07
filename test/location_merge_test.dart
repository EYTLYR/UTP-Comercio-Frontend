import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:utp_comercio_frontend/services/location_service.dart';

class BrowserLocation extends GeolocatorPlatform {
  bool requestedCurrent = false;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => throw UnsupportedError('No last-known position in browsers');
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    requestedCurrent = true;
    return Position(
      latitude: -12.04,
      longitude: -77.03,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  test(
    'web still obtains actual GPS when last-known position is unsupported',
    () async {
      final original = GeolocatorPlatform.instance;
      final browser = BrowserLocation();
      GeolocatorPlatform.instance = browser;
      addTearDown(() => GeolocatorPlatform.instance = original);
      final result = await LocationService().current();
      expect(browser.requestedCurrent, isTrue);
      expect(result.real, isTrue);
      expect(result.lat, -12.04);
      expect(result.lng, -77.03);
    },
  );
}
