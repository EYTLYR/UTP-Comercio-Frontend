import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utp_comercio_frontend/main.dart';
import 'package:utp_comercio_frontend/screens/startup_screen.dart';

void main() {
  testWidgets('dibuja el splash desde el primer cuadro de la app', (
    tester,
  ) async {
    await tester.pumpWidget(const NearbyApp(connectToApi: true));

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(find.text('Ingresar con mi celular'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(StartupScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });

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
