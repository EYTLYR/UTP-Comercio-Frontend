import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/main.dart';
import 'package:utp_comercio_frontend/theme/nearby_theme.dart';
import 'package:utp_comercio_frontend/services/sound_service.dart';
import 'package:utp_comercio_frontend/services/location_service.dart';

class _PresentationLocation extends LocationService {
  @override
  Future<({double lat, double lng, bool real, String? city, String? region})>
      current() async => (lat: -11.979, lng: -77.003, real: false, city: null, region: null);
}

void main() {
  testWidgets('capturas reales para el video de presentación', (tester) async {
    final fonts = FontLoader('Poppins');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await fonts.load();
    for (final alias in ['Roboto', 'Ahem']) {
      await (FontLoader(alias)
        ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
    }
    final messenger = tester.binding.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers.global', 'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'), (call) async {
        if (call.method == 'create') {
          final id = (call.arguments as Map)['playerId'];
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'), (_) async => null);
        }
        if (call.method == 'seek') {
          final id = (call.arguments as Map)['playerId'];
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope(
              {'event': 'audio.onSeekComplete'}), (_) {});
        }
        if (call.method == 'getCurrentPosition' || call.method == 'getDuration') return 0;
        return null;
      },
    );
    SoundService.instance.isSilentMode = true;
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final format in ['mobile', 'web']) {
      tester.view.physicalSize = format == 'mobile'
          ? const Size(390, 844)
          : const Size(1440, 960);
      for (final page in [
        'home', 'servicios', 'muro', 'sos-countdown', 'sos-sent',
        'emergency', 'tablero', 'recursos', 'perfil',
        'mapa', 'publicar-tipo', 'publicar-categoria', 'publicar-texto',
        'red', 'home-offline',
      ]) {
        final state = AppState(location: _PresentationLocation())
          ..networkMaps = false
          ..connected = true
          ..zoneName = 'Zona 3 · Las Flores';
        if (['emergency', 'tablero', 'recursos', 'red'].contains(page)) {
          state.emergency = true;
          state.role = 'BRIGADIST';
        }
        state.screen = page == 'emergency' ? 'home' : page;
        if (page.startsWith('publicar-')) {
          state.screen = 'publicar';
          state.userAddress = 'Jr. Los Pinos 340';
          state.pub.reset(
            step: page == 'publicar-tipo' ? 1 : page == 'publicar-categoria' ? 2 : 3,
            type: page == 'publicar-tipo' ? null : 'need',
            cat: page != 'publicar-tipo' ? 'herramientas' : null,
            text: page != 'publicar-tipo'
                ? 'Necesito un taladro por 2 horas para colocar una repisa.' : '',
          );
        }
        if (page == 'home-offline') {
          state.screen = 'home';
          state.offline = true;
          state.pending = 2;
        }
        final theme = NearbyThemeData.build(
          dark: false, lg: false, hc: false, emergency: state.emergency);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.materialTheme,
            home: NearbyMasterShell(state: state, theme: theme),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 400));
        if (page == 'sos-countdown') {
          await tester.pump(const Duration(seconds: 1));
        }
        if (page == 'perfil') {
          await Scrollable.ensureVisible(tester.element(find.text('Texto grande')),
            alignment: 0.4);
          await tester.pump();
        }
        await tester.pump();
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: format == 'mobile' ? 2 : 1.25);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final folder = Directory('build/presentation/captures');
          await folder.create(recursive: true);
          await File('${folder.path}/$format-$page.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox());
        state.dispose();
        await tester.pump();
      }
    }
    await tester.pump(const Duration(seconds: 31));
  });
}
