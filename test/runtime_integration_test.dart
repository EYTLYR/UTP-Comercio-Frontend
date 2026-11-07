import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utp_comercio_frontend/api/api_client.dart';
import 'package:utp_comercio_frontend/services/location_service.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';

class NoGps extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.deniedForever;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('temporary refresh network failure preserves the session', () async {
    var expired = false;
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          throw http.ClientException('offline');
        }
        return http.Response('{}', 401);
      }),
    );
    client.setTokens('test-access', 'test-refresh');
    client.onSessionExpired = () => expired = true;
    await expectLater(
      client.get('me'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'network error', true),
      ),
    );
    expect(expired, isFalse);
    expect(client.refreshToken, 'test-refresh');
  });
  test(
    'SMS server unavailable restores controls without accepting a code',
    () async {
      final state = AppState(
        api: ApiClient(
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        ),
      )..phoneDraft = '987654321';
      expect(await state.requestOtp(), isFalse);
      expect(state.busy, isFalse);
      expect(state.connected, isFalse);
      expect(state.toastMessage, isNotNull);
      state.dispose();
    },
  );
  test(
    'late callbacks after disposal do not notify or create a toast timer',
    () {
      final state = AppState();
      state.dispose();
      expect(() {
        state.refresh();
        state.toast('late');
      }, returnsNormally);
      expect(state.toastMessage, isNull);
    },
  );
  test('IP fallback keeps city and identifies approximate position', () async {
    final original = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = NoGps();
    addTearDown(() => GeolocatorPlatform.instance = original);
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'success': true,
          'latitude': -12.04,
          'longitude': -77.03,
          'city': 'Lima',
          'region': 'Lima',
        }),
        200,
      ),
    );
    final service = LocationService(client: client);
    final position = await service.current();
    expect(position.real, isTrue);
    expect(position.city, 'Lima');
    expect(service.approximate, isTrue);
  });
  test(
    'unavailable location is never marked as an actual device fix',
    () async {
      final original = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = NoGps();
      addTearDown(() => GeolocatorPlatform.instance = original);
      final service = LocationService(
        client: MockClient((_) async => http.Response('{}', 503)),
      );
      expect((await service.current()).real, isFalse);
    },
  );
}
