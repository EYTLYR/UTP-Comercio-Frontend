import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utp_comercio_frontend/config/app_environment.dart';
import 'package:utp_comercio_frontend/main.dart' as app;

class _EnvBundle extends CachingAssetBundle {
  final String content;
  _EnvBundle(this.content);
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(key, '.env');
    return content;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const override = String.fromEnvironment('APP_ENV');
  tearDown(() => AppEnvironment.load(bundle: _EnvBundle('')));

  test('development habilita herramientas y production las oculta', () async {
    await AppEnvironment.load(bundle: _EnvBundle('APP_ENV=development\n'));
    expect(AppEnvironment.name, override.isEmpty ? 'development' : override);
    expect(
      AppEnvironment.showDevelopmentTools,
      override.isEmpty || override == 'development',
    );
    await AppEnvironment.load(bundle: _EnvBundle('APP_ENV=production\n'));
    expect(AppEnvironment.name, override.isEmpty ? 'production' : override);
    expect(AppEnvironment.showDevelopmentTools, override == 'development');
  });

  test('un ambiente desconocido no habilita el simulador', () async {
    await AppEnvironment.load(bundle: _EnvBundle('APP_ENV=environment\n'));
    expect(AppEnvironment.showDevelopmentTools, override == 'development');
  });

  test(
    'acepta el archivo de Windows con comentarios y valor entre comillas',
    () async {
      await AppEnvironment.load(
        bundle: _EnvBundle(
          '\uFEFF# Configuración\r\nAPP_ENV="production" # ambiente\r\n',
        ),
      );
      expect(AppEnvironment.name, override.isEmpty ? 'production' : override);
    },
  );

  testWidgets('el arranque carga el asset .env automáticamente', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final content = await rootBundle.loadString('.env');
      expect(content, contains('APP_ENV='));
      await app.main();
    });
    await tester.pump();
    expect(find.byType(app.NearbyApp), findsOneWidget);
    expect(
      find.byTooltip('Simulador'),
      AppEnvironment.showDevelopmentTools ? findsOneWidget : findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
