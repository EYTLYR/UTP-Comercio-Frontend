import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/theme/nearby_theme.dart';

import 'prototype_flows_test.dart' show harness;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Poppins',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
  });
  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      test(
        'interruptores apagados visibles: oscuro $dark, contraste $contrast',
        () {
          final theme = NearbyThemeData.build(
            dark: dark,
            lg: false,
            hc: contrast,
            emergency: false,
          );
          final switches = theme.materialTheme.switchTheme;
          final track = switches.trackColor!.resolve({})!;
          final thumb = switches.thumbColor!.resolve({})!;
          final outline = switches.trackOutlineColor!.resolve({})!;
          expect(track.a, 1);
          expect(thumb, isNot(track));
          expect(outline, isNot(theme.surface));
          expect(
            switches.trackOutlineWidth!.resolve({})!,
            greaterThanOrEqualTo(1.5),
          );
          expect(
            switches.trackColor!.resolve({WidgetState.selected}),
            theme.primary,
          );
        },
      );
    }
  }

  testWidgets('perfil activa emergencia directamente sin abrir una hoja', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState()..screen = 'perfil';
    await tester.pumpWidget(harness(state));
    await tester.pump();
    final toggle = find.widgetWithText(SwitchListTile, 'Modo emergencia');
    await Scrollable.ensureVisible(tester.element(toggle), alignment: 0.4);
    await tester.pump();
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();
    expect(state.emergency, isTrue);
    expect(state.emSource, 'yo');
    expect(state.zoneEm, isFalse);
    expect(state.screen, 'perfil');
    expect(state.sheet, isNull);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await Scrollable.ensureVisible(tester.element(toggle), alignment: 0.4);
    await tester.pump();
    await tester.tap(toggle);
    await tester.pump();
    expect(state.sheet?['type'], 'em-off');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('activar desde perfil respeta una emergencia de zona existente', (
    tester,
  ) async {
    final state = AppState()..zoneEm = true;
    state.activateEmergencyFromProfile();
    expect(state.emergency, isTrue);
    expect(state.zoneEm, isTrue);
    expect(state.emSource, 'zona');
    expect(state.sheet, isNull);
    state.dispose();
  });
}
