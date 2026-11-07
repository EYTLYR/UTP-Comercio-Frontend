# Nearby · Flutter

Implementación Flutter basada en `../prototipo.html`, conservando las pantallas y los datos de demostración del avance existente.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome
```

En escritorio se muestran el panel de simulación y el teléfono. En móvil, el botón «Simulador» abre los controles de demostración.

## Verificar

```sh
flutter analyze
flutter test
flutter build web
```

Las pruebas recorren las 27 pantallas en anchos de 360, 390 y 1280 píxeles, en modo normal, emergencia y emergencia con tema oscuro, texto grande, alto contraste y sin conexión. También verifican pulsación SOS, cancelación, envío automático y navegación durante el tutorial.

Para exportar vistas Flutter a `build/previews/`:

```sh
flutter test --dart-define=PREVIEW=true test/prototype_flows_test.dart --plain-name "exporta vistas"
```

## Alcance

La app conserva el funcionamiento de demostración: llamadas, SMS, ubicación, reconocimiento de voz, IA y recepción por sonido se representan con datos y estados locales; no están conectados a servicios reales. Los cambios de datos no persisten al reiniciar la app. Nunito se incluye localmente con su licencia en `assets/fonts/`.

Se corrigieron errores de compilación, la ruta SOS, distribución en pantallas pequeñas, marco de escritorio, cabeceras, colores de la red de rescate y superposición del tutorial. Las comprobaciones de distribución y las vistas renderizadas de Flutter no equivalen a una comparación visual píxel por píxel con el HTML.
