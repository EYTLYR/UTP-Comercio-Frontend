import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/screens/map_screens.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/theme/nearby_theme.dart';
import 'package:utp_comercio_frontend/widgets/navigation_chrome.dart';

class LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF9sAAAAASUVORK5CYII=',
        ),
      );
}

void main() {
  testWidgets(
    'map controls stay at edges and permanent central panel is absent',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationInsets(
              padding: const EdgeInsets.only(top: 100, bottom: 120),
              child: MapScreen(
                state: state,
                theme: NearbyThemeData.build(
                  dark: false,
                  lg: false,
                  hc: false,
                  emergency: false,
                ),
                tileProvider: LocalTiles(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final filters = tester.getRect(
        find.byKey(const ValueKey('map-filter-control')),
      );
      final location = tester.getRect(
        find.byKey(const ValueKey('map-location-control')),
      );
      expect(filters.right, closeTo(386, .1));
      expect(filters.top, closeTo(104, .1));
      expect(location.right, closeTo(386, .1));
      expect(location.bottom, closeTo(516, .1));
      expect(find.text('Explora el mapa o pulsa Mi ubicación.'), findsNothing);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.byTooltip('Ver ejemplos'), findsNothing);
      await tester.tap(find.text('Servicios'));
      await tester.pump();
      expect(state.mapFilter, 'svc');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
  testWidgets('emergency filters scroll horizontally to the last option', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState()..emergency = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            state: state,
            theme: NearbyThemeData.build(
              dark: false,
              lg: false,
              hc: false,
              emergency: true,
            ),
            tileProvider: LocalTiles(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final strip = find.byKey(const ValueKey('map-filter-strip'));
    expect(tester.widget<ListView>(strip).scrollDirection, Axis.horizontal);
    await tester.drag(strip, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apoyo'));
    await tester.pump();
    expect(state.mapFilter, 'group');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
