import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';

import 'prototype_flows_test.dart' show harness;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Poppins',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
  });
  for (final mode in ['normal', 'large', 'offline']) {
    testWidgets('los detalles desplazan la cabecera roja: $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState()
        ..screen = 'sos-sent'
        ..lg = mode == 'large'
        ..offline = mode == 'offline';
      await tester.pumpWidget(harness(state));
      final header = find.byKey(const ValueKey('sos-sent-header'));
      final details = find.byKey(const ValueKey('sos-sent-details'));
      final headerBefore = tester.getTopLeft(header).dy;
      final detailsBefore = tester.getTopLeft(details).dy;
      expect(tester.getBottomLeft(header).dy, closeTo(detailsBefore, 0.1));
      await tester.dragFrom(
        Offset(180, detailsBefore + 40),
        const Offset(0, -140),
      );
      await tester.pump();
      final headerDelta = tester.getTopLeft(header).dy - headerBefore;
      final detailsDelta = tester.getTopLeft(details).dy - detailsBefore;
      expect(headerDelta, lessThan(-80));
      expect(headerDelta, closeTo(detailsDelta, 0.1));
      final close = find.text('Estoy a salvo · cerrar alerta');
      await tester.ensureVisible(close);
      await tester.pump();
      expect(close.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
