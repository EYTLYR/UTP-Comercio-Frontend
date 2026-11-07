import 'package:flutter_test/flutter_test.dart';

import 'package:utp_comercio_frontend/main.dart';

void main() {
  testWidgets('muestra la portada de Nearby', (WidgetTester tester) async {
    await tester.pumpWidget(const NearbyApp());

    expect(find.text('Hola, María'), findsOneWidget);
    expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('¿Estás en peligro?'), findsOneWidget);
  });

  testWidgets('permite abrir el directorio desde la navegación', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NearbyApp());

    await tester.tap(find.text('Servicios'));
    await tester.pump();

    expect(find.text('Servicios del barrio'), findsOneWidget);
  });
}
