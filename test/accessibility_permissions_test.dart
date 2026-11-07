import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/main.dart';
import 'package:utp_comercio_frontend/state/app_state.dart';
import 'package:utp_comercio_frontend/services/startup_permissions.dart';
import 'package:utp_comercio_frontend/widgets/permission_intro.dart';

import 'prototype_flows_test.dart' show harness;

class Memory extends PermissionMemory {
  bool seen = false;
  @override
  Future<bool> hasSeenIntro() async => seen;
  @override
  Future<void> markSeen() async {
    seen = true;
  }
}

class Backend extends AccessBackend {
  int requests = 0;
  @override
  Future<Map<AppAccess, AccessState>> requestAll() async {
    requests++;
    return {for (final access in AppAccess.values) access: AccessState.denied};
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
  });
  void viewport(WidgetTester tester, {double height = 900}) {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('texto grande amplía títulos, etiquetas y navegación', (
    tester,
  ) async {
    viewport(tester);
    final state = AppState();
    await tester.pumpWidget(harness(state));
    for (final label in ['Hola, María', 'Inicio', 'Publicar']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.textScaler.scale(10), 10);
    }
    state.toggleLg();
    await tester.pump();
    for (final label in ['Hola, María', 'Inicio', 'Publicar']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.textScaler.scale(10), 14);
    }
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('alto contraste cambia fondos, bordes y texto en ambos temas', (
    tester,
  ) async {
    viewport(tester);
    final state = AppState();
    await tester.pumpWidget(harness(state));
    final context = tester.element(find.text('Hola, María'));
    final before = Theme.of(context).colorScheme;
    state.toggleHc();
    await tester.pump();
    final after = Theme.of(context).colorScheme;
    expect(after.outline, isNot(before.outline));
    expect(after.surface, Colors.white);
    expect(after.onSurface, Colors.black);
    expect(MediaQuery.highContrastOf(context), isTrue);
    state.toggleDark();
    await tester.pump();
    final dark = Theme.of(context).colorScheme;
    expect(dark.onSurface, Colors.white);
    expect(dark.surface.computeLuminance(), lessThan(0.01));
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('cuenta regresiva pierde arco y mantiene las acciones abajo', (
    tester,
  ) async {
    viewport(tester, height: 640);
    final state = AppState()
      ..lg = true
      ..screen = 'sos-countdown';
    await tester.pumpWidget(harness(state));
    final key = find.byKey(const ValueKey('sos-countdown-actions'));
    final bottom = tester.getBottomRight(key).dy;
    expect(bottom, closeTo(640, 1));
    final ring = find.byKey(const ValueKey('sos-countdown-ring'));
    expect(tester.widget<CircularProgressIndicator>(ring).value, 1);
    final category = find.text('Salud');
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pump();
    expect(state.sosType, 'salud');
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<CircularProgressIndicator>(ring).value!,
      closeTo(0.6, 0.02),
    );
    expect(tester.getBottomRight(key).dy, bottom);
    await tester.tap(find.text('Cancelar, fue un error'));
    await tester.pump(const Duration(seconds: 6));
    expect(state.screen, 'home');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('zona abre mapa y el avatar mantiene el perfil', (tester) async {
    viewport(tester);
    final state = AppState();
    await tester.pumpWidget(harness(state));
    await tester.tap(find.byKey(const ValueKey('zone-map')));
    await tester.pump();
    expect(state.screen, 'mapa');
    await tester.tap(find.byKey(state.tourTarget('profile')));
    await tester.pump();
    expect(state.screen, 'perfil');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('botón flotante responde también en su borde superior', (
    tester,
  ) async {
    viewport(tester);
    final state = AppState();
    await tester.pumpWidget(harness(state));
    final circle = find.byKey(const ValueKey('publish-floating-button'));
    await tester.tapAt(tester.getTopLeft(circle) + const Offset(30, 8));
    await tester.pump();
    expect(state.screen, 'publicar');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'primer inicio explica los siete permisos y permite rechazarlos',
    (tester) async {
      viewport(tester);
      final memory = Memory();
      final backend = Backend();
      final permissions = StartupPermissions(memory: memory, backend: backend);
      await permissions.initialize();
      await tester.pumpWidget(NearbyApp(permissions: permissions));
      expect(find.byType(PermissionIntro), findsOneWidget);
      for (final label in [
        'Cámara',
        'Ubicación',
        'Contactos',
        'Llamadas',
        'Dispositivos cercanos',
        'Bluetooth',
        'Galería',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      expect(backend.requests, 0);
      await tester.tap(find.text('Permitir y continuar'));
      await tester.pump();
      expect(backend.requests, 1);
      expect(
        permissions.states.values.every((value) => value == AccessState.denied),
        isTrue,
      );
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.byType(PermissionIntro), findsNothing);
      expect(memory.seen, isTrue);
      await tester.pumpWidget(const SizedBox());
      final nextStart = StartupPermissions(memory: memory, backend: backend);
      await nextStart.initialize();
      expect(nextStart.visible, isFalse);
      nextStart.dispose();
    },
  );

  testWidgets('aplazar permisos no vuelve a interrumpir el siguiente inicio', (
    tester,
  ) async {
    viewport(tester);
    final memory = Memory();
    final backend = Backend();
    final permissions = StartupPermissions(memory: memory, backend: backend);
    await permissions.initialize();
    await tester.pumpWidget(NearbyApp(permissions: permissions));
    await tester.tap(find.text('Ahora no'));
    await tester.pump();
    expect(backend.requests, 0);
    expect(memory.seen, isTrue);
    expect(find.byType(PermissionIntro), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tablero con todas las opciones de accesibilidad', (
    tester,
  ) async {
    viewport(tester);
    final state = AppState()
      ..emergency = true
      ..dark = true
      ..hc = true
      ..lg = true
      ..offline = true
      ..screen = 'tablero';
    await tester.pumpWidget(harness(state));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
