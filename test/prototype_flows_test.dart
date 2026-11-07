import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/main.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/services/startup_permissions.dart';
import 'package:utp_comercio_frontend/theme/nearby_theme.dart';
import 'package:utp_comercio_frontend/widgets/common_widgets.dart';

Widget harness(AppState state) => AnimatedBuilder(
  animation: state,
  builder: (context, _) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: state.dark ? NearbyColors.darkPrimary : NearbyColors.primary,
        brightness: state.dark ? Brightness.dark : Brightness.light,
      ),
    ),
    home: NearbyMasterShell(
      state: state,
      theme: NearbyThemeData.build(
        dark: state.dark,
        lg: state.lg,
        hc: state.hc,
        emergency: state.emergency,
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('SOS exige dos segundos y permite cancelar la cuenta regresiva', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(harness(state));
    final button = find.byType(SosHoldButton);
    final short = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 500));
    await short.up();
    await tester.pump();
    expect(state.screen, 'home');
    final hold = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 2100));
    await hold.up();
    await tester.pump();
    expect(state.screen, 'sos-countdown');
    expect(find.text('Enviando alerta en'), findsOneWidget);
    await tester.tap(find.text('Cancelar, fue un error'));
    await tester.pump();
    expect(state.screen, 'home');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SOS se envía automáticamente después de cinco segundos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState()..screen = 'sos-countdown';
    await tester.pumpWidget(harness(state));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(state.screen, 'sos-sent');
    expect(find.text('Alerta enviada'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('tutorial permite pulsar la navegación que solicita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState()..startTour('main');
    state.tourIndex = 3;
    await tester.pumpWidget(harness(state));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Servicios').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.screen, 'servicios');
    expect(state.tourIndex, 4);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  if (const bool.fromEnvironment('PREVIEW')) {
    testWidgets('exporta vistas para revisión visual', (tester) async {
      const previewWidth = int.fromEnvironment(
        'PREVIEW_WIDTH',
        defaultValue: 1280,
      );
      tester.view.physicalSize = Size(previewWidth.toDouble(), 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      final key = GlobalKey();
      for (final screen in [
        'home',
        'home-large',
        'home-contrast',
        'sos-countdown',
        'servicios',
        'sos-sent',
        'red',
        'tutorial',
        'voice',
        'permissions',
      ]) {
        state.lg = screen == 'home-large';
        state.hc = screen == 'home-contrast';
        if (screen == 'home-large' || screen == 'home-contrast') {
          state.go('home');
        } else if (screen == 'tutorial') {
          state.startTour('main');
          state.tourIndex = 1;
        } else if (screen == 'voice') {
          state.endTour();
          state.openSheet('voice');
        } else {
          state.go(screen);
        }
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: screen == 'permissions'
                ? NearbyApp(permissions: StartupPermissions()..visible = true)
                : harness(state),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (screen == 'sos-countdown') {
          await tester.pump(const Duration(seconds: 2));
        }
        await tester.pump();
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/previews').create(recursive: true);
          await File('build/previews/$screen.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  for (final width in [360.0, 390.0, 1280.0]) {
    for (final mode in [0, 1, 2]) {
      testWidgets('pantallas a $width px, emergencia $mode', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = AppState()
          ..emergency = mode != 0
          ..dark = mode == 2
          ..lg = mode == 2
          ..hc = mode == 2
          ..offline = mode == 2;
        addTearDown(state.dispose);
        state.openChat('Carlos Mendoza');
        state.startCall('105');
        for (final screen in [
          'home',
          'splash',
          'login',
          'otp',
          'registro',
          'contactos',
          'permisos',
          'listo',
          'servicios',
          'svc',
          'muro',
          'publicar',
          'mapa',
          'ruta',
          'chat',
          'llamada',
          'ficha',
          'sos',
          'sos-countdown',
          'sos-sent',
          'alerta-recibida',
          'tablero',
          'recursos',
          'apoyo',
          'red',
          'puente',
          'perfil',
        ]) {
          state.go(screen);
          await tester.pumpWidget(harness(state));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: screen);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
