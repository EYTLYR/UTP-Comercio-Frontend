import 'package:flutter_test/flutter_test.dart';

import 'package:utp_comercio_frontend/main.dart';

void main() {
  testWidgets('muestra la portada de Nearby', (WidgetTester tester) async {
    await tester.pumpWidget(const NearbyApp());

    expect(find.text('Hola, María Quispe'), findsOneWidget);
    expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('¿Estás en peligro?'), findsOneWidget);
  });

  testWidgets('permite activar el modo emergencia', (WidgetTester tester) async {
    await tester.pumpWidget(const NearbyApp());

    await tester.longPress(find.text('SOS').first);
    await tester.pump();
    await tester.longPress(find.text('SOS').first);
    await tester.pump();

    expect(find.text('Tu barrio se está organizando'), findsOneWidget);
    expect(find.text('Modo emergencia activo'), findsOneWidget);
  });
}
