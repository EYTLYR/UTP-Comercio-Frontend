import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/config/app_environment.dart';
import 'package:utp_comercio_frontend/services/speech_input.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/widgets/common_widgets.dart';
import 'package:utp_comercio_frontend/widgets/simulation_panel.dart';

import 'prototype_flows_test.dart' show harness;

class FakeSpeechInput extends SpeechInput {
  int starts = 0;
  int cancels = 0;
  bool denied = false;
  @override
  Future<void> start() async {
    starts++;
    error = denied ? 'Permite el acceso al micrófono.' : null;
    listening = !denied;
    notifyListeners();
  }

  void recognize(String words) {
    transcript = words;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    listening = false;
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    cancels++;
    listening = false;
  }
}

Future<void> layout(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
  });
  void viewport(
    WidgetTester tester, {
    double width = 390,
    double height = 780,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets('controles de desarrollo según APP_ENV a $width', (
      tester,
    ) async {
      viewport(tester, width: width);
      final state = AppState();
      await tester.pumpWidget(harness(state));
      expect(find.text('9:41'), findsNothing);
      expect(find.byType(SimulationPanel), findsNothing);
      final control = find.byTooltip('Simulador');
      if (AppEnvironment.showDevelopmentTools) {
        expect(control, findsOneWidget);
        final before = tester.getCenter(control);
        await tester.drag(control, const Offset(-70, -80));
        await tester.pump();
        expect(tester.getCenter(control), isNot(before));
        await tester.tap(control);
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(SimulationPanel), findsOneWidget);
      } else {
        expect(control, findsNothing);
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold).first).endDrawer,
          isNull,
        );
      }
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets('anillo SOS parte de las doce y completa dos segundos', (
    tester,
  ) async {
    viewport(tester);
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SosHoldButton(onComplete: () => completions++)),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosHoldButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final gradients = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SosHoldButton),
            matching: find.byType(Container),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.gradient)
        .whereType<SweepGradient>();
    final gradient = gradients.single;
    expect(gradient.startAngle, 0);
    expect(gradient.endAngle, math.pi * 2);
    expect((gradient.transform as GradientRotation).radians, -math.pi / 2);
    expect(gradient.stops!.first, closeTo(0.5, 0.02));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 999));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 16));
    expect(completions, 1);
    await gesture.up();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dictado usa reconocimiento y solo aplica el texto confirmado', (
    tester,
  ) async {
    viewport(tester);
    final voice = FakeSpeechInput();
    final state = AppState(voice: voice)..openSheet('voice');
    await tester.pumpWidget(harness(state));
    await tester.pump(const Duration(milliseconds: 300));
    expect(voice.starts, 0);
    expect(find.text('Usar frase de demostración'), findsNothing);
    await tester.tap(find.text('Activar micrófono'));
    await tester.pump();
    expect(voice.starts, 1);
    expect(voice.listening, isTrue);
    voice.recognize('Necesito una escalera para mañana');
    await tester.pump();
    expect(state.pub.text, isEmpty);
    await tester.tap(find.text('Usar este texto'));
    await layout(tester);
    expect(state.screen, 'publicar');
    expect(state.pub.text, 'Necesito una escalera para mañana');
    expect(voice.listening, isFalse);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'permiso denegado permite escribir sin inventar una transcripción',
    (tester) async {
      viewport(tester);
      final voice = FakeSpeechInput()..denied = true;
      final state = AppState(voice: voice)..openSheet('voice');
      await tester.pumpWidget(harness(state));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Activar micrófono'));
      await tester.pump();
      expect(find.text('Permite el acceso al micrófono.'), findsOneWidget);
      expect(state.pub.text, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('voice-transcript')),
        'Necesito agua',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Usar este texto'));
      await tester.tap(find.text('Usar este texto'));
      await layout(tester);
      expect(state.pub.text, 'Necesito agua');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  for (final width in [360.0, 1280.0]) {
    testWidgets('tutorial completo sin publicar datos, ancho $width', (
      tester,
    ) async {
      viewport(tester, width: width);
      final state = AppState()..startTour('main');
      final postsBefore = state.posts.length;
      await tester.pumpWidget(harness(state));
      Future<void> tapTarget(String name) async {
        await layout(tester);
        final target = find.byKey(state.tourTarget(name));
        expect(target, findsOneWidget, reason: name);
        await tester.tap(target);
        await tester.pump(const Duration(milliseconds: 350));
        await layout(tester);
        expect(tester.takeException(), isNull, reason: name);
      }

      Future<void> next() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
        await layout(tester);
      }

      await tester.tap(find.text('Empezar'));
      await layout(tester);
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(state.tourTarget('sos'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2016));
      await hold.up();
      await tester.pump(const Duration(milliseconds: 350));
      expect(state.tourIndex, 2);
      await next();
      await tapTarget('nav-servicios');
      expect(state.tourIndex, 4);
      await tapTarget('service-category');
      expect(state.tourIndex, 5);
      await tapTarget('service-julio');
      expect(state.tourIndex, 6);
      await next();
      await tapTarget('vb');
      expect(state.tourIndex, 8);
      await tapTarget('back');
      expect(state.tourIndex, 9);
      await tapTarget('nav-publicar');
      expect(state.tourIndex, 10);
      await tapTarget('publish-type');
      expect(state.tourIndex, 11);
      await tapTarget('publish-category');
      expect(state.tourIndex, 12);
      await tapTarget('publish-submit');
      expect(state.tourIndex, 13);
      expect(state.posts.length, postsBefore);
      await tapTarget('publish-home');
      expect(state.tourIndex, 14);
      await next();
      await next();
      await tester.tap(find.text('Terminar'));
      await tester.pump();
      expect(state.tourName, isNull);
      expect(state.vbGiven, isEmpty);
      expect(state.posts.length, postsBefore);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets('tutorial emergencia funciona sobre la hoja modal', (
    tester,
  ) async {
    viewport(tester);
    final state = AppState()..startTour('em');
    await tester.pumpWidget(harness(state));
    await layout(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await layout(tester);
    }
    await tester.tap(find.byKey(state.tourTarget('em-banner')));
    await tester.pump(const Duration(milliseconds: 350));
    await layout(tester);
    expect(state.tourIndex, 4);
    expect(state.sheet?['type'], 'em');
    await tester.tap(find.text('Entendido'));
    await tester.pump();
    expect(state.tourName, isNull);
    expect(state.sheet, isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('salir cancela un avance del tutorial pendiente', (tester) async {
    viewport(tester);
    final state = AppState()..startTour('main');
    state.tourIndex = 3;
    state.checkTourEvent('screen:servicios');
    state.endTour();
    await tester.pump(const Duration(seconds: 1));
    expect(state.tourName, isNull);
    expect(state.tourIndex, 0);
    state.dispose();
  });
  testWidgets('cerrar la hoja detiene el micrófono sin usar el texto', (
    tester,
  ) async {
    viewport(tester);
    final voice = FakeSpeechInput();
    final state = AppState(voice: voice)..openSheet('voice');
    await tester.pumpWidget(harness(state));
    await tester.tap(find.text('Activar micrófono'));
    await tester.pump();
    voice.recognize('Texto sin confirmar');
    await tester.pump();
    await tester.tapAt(const Offset(10, 20));
    await tester.pump();
    expect(state.sheet, isNull);
    expect(voice.cancels, greaterThan(0));
    expect(voice.listening, isFalse);
    expect(state.pub.text, isEmpty);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  test('tutorial restaura el borrador y el ambiente anterior', () {
    final state = AppState(voice: FakeSpeechInput())
      ..emergency = true
      ..offline = true
      ..servCat = 'electricidad';
    state.pub.reset(
      step: 2,
      type: 'offer',
      cat: 'habilidades',
      text: 'Mi borrador',
    );
    state.startTour('main');
    expect(state.emergency, isFalse);
    state.toggleVb('julio');
    state.pub.text = 'Práctica';
    state.endTour();
    expect(state.pub.text, 'Mi borrador');
    expect(state.pub.type, 'offer');
    expect(state.servCat, 'electricidad');
    expect(state.emergency, isTrue);
    expect(state.offline, isTrue);
    expect(state.vbGiven, isEmpty);
    state.dispose();
  });

  test('los reportes no comparten datos mutables entre sesiones', () {
    final first = AppState(voice: FakeSpeechInput());
    final second = AppState(voice: FakeSpeechInput());
    first.reports.first.status = 'a';
    expect(second.reports.first.status, 'p');
    first.dispose();
    second.dispose();
  });

  testWidgets('la hoja de voz funciona con teclado abierto', (tester) async {
    viewport(tester, height: 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);
    final state = AppState(voice: FakeSpeechInput())..openSheet('voice');
    await tester.pumpWidget(harness(state));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('voice-transcript')),
      'Necesito medicinas',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Usar este texto'));
    await tester.tap(find.text('Usar este texto'));
    await layout(tester);
    expect(state.pub.text, 'Necesito medicinas');
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
