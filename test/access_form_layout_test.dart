import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';

import 'prototype_flows_test.dart' show harness;

void main() {
  for (final (screen, heading) in [
    ('registro', '¿Dónde vives?'),
    ('contactos', 'Tu círculo de confianza'),
    ('permisos', 'Ubicación y avisos de emergencia'),
  ]) {
    testWidgets('$screen fits a narrow screen with large text', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState()
        ..screen = screen
        ..contactsMode = 'setup'
        ..connected = true
        ..lg = true;
      await tester.pumpWidget(harness(state));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.scrollUntilVisible(
        find.text(heading),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(heading), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  for (final screen in ['login', 'otp']) {
    for (final keyboard in [0.0, 300.0]) {
      testWidgets('$screen fits large text and keyboard $keyboard', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 600);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final state = AppState()
          ..screen = screen
          ..lg = true;
        await tester.pumpWidget(harness(state));
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.byKey(const ValueKey('access-form-scroll')),
          findsOneWidget,
        );
        final footer = screen == 'login'
            ? find.text(
                'Al continuar aceptas los términos y la política de privacidad de Nearby.',
              )
            : find.text(
                'Puedes autorizar la lectura de este único SMS para completar el código, o escribirlo manualmente.',
              );
        await tester.ensureVisible(footer);
        await tester.pump();
        expect(footer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
  }
}
