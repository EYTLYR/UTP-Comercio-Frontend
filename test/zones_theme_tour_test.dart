import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utp_comercio_frontend/api/api_client.dart';
import 'package:utp_comercio_frontend/models/models.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/theme/nearby_theme.dart';

import 'prototype_flows_test.dart' show harness;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Poppins',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
  });
  const other = BrowseZone(
    id: 'other',
    name: 'Otra zona',
    district: 'Distrito',
    latitude: -12,
    longitude: -77,
    radius: 2000,
  );
  test(
    'exploring a zone uses GET only and never changes the saved zone',
    () async {
      final requests = <http.Request>[];
      final state =
          AppState(
              api: ApiClient(
                client: MockClient((request) async {
                  requests.add(request);
                  return http.Response(jsonEncode([]), 200);
                }),
              ),
            )
            ..connected = true
            ..zoneId = 'home'
            ..zoneName = 'Mi barrio';
      await state.browseZone(other);
      expect(state.visibleZoneName, 'Otra zona');
      expect(state.zoneId, 'home');
      expect(state.zoneName, 'Mi barrio');
      expect(requests.every((request) => request.method == 'GET'), isTrue);
      expect(
        requests.any(
          (request) => request.url.queryParameters['zoneId'] == 'other',
        ),
        isTrue,
      );
      await state.browseZone(null);
      expect(state.visibleZoneName, 'Mi barrio');
      expect(requests.last.url.queryParameters.containsKey('zoneId'), isFalse);
      state.dispose();
    },
  );
  test('tutorial keeps practice services separate from backend services', () {
    final state = AppState()..connected = true;
    final original = state.services;
    state.services = [];
    state.startTour('main');
    expect(state.services.any((service) => service.id == 'julio'), isTrue);
    state.endTour();
    expect(state.services, isEmpty);
    expect(original, isNotEmpty);
    state.dispose();
  });
  testWidgets('top bar displays the saved zone instead of a fixed label', (
    tester,
  ) async {
    final state = AppState()..zoneName = 'Zona guardada del usuario';
    await tester.pumpWidget(harness(state));
    expect(find.text('Zona guardada del usuario'), findsOneWidget);
    expect(find.text('Zona 3 · Las Flores'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
    'zone picker searches and returns to the saved zone with keyboard open',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final state =
          AppState(
              api: ApiClient(
                client: MockClient((request) async {
                  return http.Response(
                    jsonEncode(
                      request.url.path.endsWith('/zones')
                          ? [
                              {
                                'id': 'home',
                                'name': 'Mi barrio',
                                'district': 'Distrito',
                                'centerLat': -12,
                                'centerLng': -77,
                                'radiusM': 1500,
                              },
                              {
                                'id': 'other',
                                'name': 'Otra zona',
                                'district': 'Distrito',
                                'centerLat': -13,
                                'centerLng': -72,
                                'radiusM': 2000,
                              },
                            ]
                          : [],
                    ),
                    200,
                  );
                }),
              ),
            )
            ..connected = true
            ..zoneId = 'home'
            ..zoneName = 'Mi barrio'
            ..lg = true;
      await tester.pumpWidget(harness(state));
      await tester.tap(find.byKey(const ValueKey('zone-map')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar otra zona'),
        'Otra',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Otra zona'));
      await tester.tap(find.text('Otra zona'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.viewedZone?.id, 'other');
      expect(state.zoneName, 'Mi barrio');
      tester.view.resetViewInsets();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('zone-map')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('restore-home-zone')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.viewedZone, isNull);
      expect(state.visibleZoneName, 'Mi barrio');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
  for (final screen in ['publicar', 'perfil']) {
    for (final dark in [false, true]) {
      testWidgets(
        'emergency header is navy and $screen respects dark preference $dark',
        (tester) async {
          final state = AppState()
            ..emergency = true
            ..screen = screen
            ..dark = dark;
          await tester.pumpWidget(harness(state));
          final expected = dark ? NearbyColors.darkBg : NearbyColors.bg;
          expect(
            tester
                .widget<Scaffold>(find.byType(Scaffold).first)
                .backgroundColor,
            expected,
          );
          final header = tester.widget<Container>(
            find.byKey(const ValueKey('top-chrome')),
          );
          expect((header.decoration as BoxDecoration).color, NearbyColors.navy);
          expect(state.dark, dark);
          state.emergency = false;
          state.refresh();
          await tester.pump();
          // Fuera de emergencia el diseño nuevo usa página blanca (en oscuro, el fondo oscuro).
          expect(
            tester
                .widget<Scaffold>(find.byType(Scaffold).first)
                .backgroundColor,
            dark ? NearbyColors.darkBg : Colors.white,
          );
          expect(state.dark, dark);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          state.dispose();
        },
      );
    }
  }
  testWidgets('tutorial started at page bottom reveals SOS automatically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState();
    await tester.pumpWidget(harness(state));
    final scroll = find
        .descendant(
          of: find.byKey(const ValueKey('navigation-content-fade')),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(scroll).position;
    for (var i = 0; i < 5; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
    }
    await tester.tap(find.text('Aprende tocando la app (1 minuto)'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Empezar'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final sos = find.byKey(state.tourTarget('sos'));
    expect(sos.hitTestable(), findsOneWidget);
    expect(tester.getCenter(sos).dy, inInclusiveRange(100, 680));
    final hold = await tester.startGesture(tester.getCenter(sos));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 2100));
    await hold.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(state.tourIndex, 2);
    expect(find.byKey(state.tourTarget('calls')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
