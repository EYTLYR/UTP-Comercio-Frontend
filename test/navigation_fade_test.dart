import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/widgets/common_widgets.dart';
import 'package:utp_comercio_frontend/widgets/navigation_chrome.dart';

import 'prototype_flows_test.dart' show harness;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Poppins',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
  });
  for (final mode in ['normal', 'dark', 'large']) {
    testWidgets('contenido bajo barras fijas y último texto accesible: $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState()
        ..dark = mode == 'dark'
        ..lg = mode == 'large';
      await tester.pumpWidget(harness(state));
      await tester.pump();
      await tester.pump();
      final fade = find.byKey(const ValueKey('navigation-content-fade'));
      expect(tester.widget<ShaderMask>(fade).blendMode, BlendMode.dstIn);
      final scroll = find
          .descendant(of: fade, matching: find.byType(Scrollable))
          .first;
      expect(tester.getTopLeft(scroll).dy, 0);
      expect(tester.getBottomRight(scroll).dy, 780);
      final top = find.byType(NearbyTopBar);
      final bottom = find.byType(NearbyBottomNav);
      final topBounds = tester.getRect(top);
      final bottomBounds = tester.getRect(bottom);
      expect(
        tester.getTopLeft(find.text('Hola, María')).dy,
        greaterThan(topBounds.bottom),
      );
      await tester.drag(scroll, const Offset(0, -160));
      await tester.pump();
      expect(tester.getRect(top), topBounds);
      expect(tester.getRect(bottom), bottomBounds);
      final scrollState = tester.state<ScrollableState>(scroll);
      for (var i = 0; i < 4; i++) {
        scrollState.position.jumpTo(scrollState.position.maxScrollExtent);
        await tester.pump();
      }
      final last = find.text('Aprende tocando la app (1 minuto)');
      expect(last.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(last).dy, lessThan(bottomBounds.top));
      expect(find.byType(NavigationChrome), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
