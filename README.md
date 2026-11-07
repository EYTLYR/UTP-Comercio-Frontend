# Nearby · Flutter

Interfaz y navegación basadas en `../prototipo.html`. La app se adapta a móvil, web y escritorio sin marco de teléfono ni panel fijo de simulación.

## Ambientes

La app lee automáticamente el archivo `.env` de la raíz antes de iniciar. Al clonar el proyecto, copia `.env.example` a `.env` (este último está ignorado por Git):

```dotenv
APP_ENV=development
```

```sh
flutter pub get
flutter run
```

Cambia el valor a `APP_ENV=production` para ocultar el simulador también durante una ejecución de depuración. Detén y vuelve a ejecutar la app después de editar el archivo; hot reload no lo vuelve a cargar.

En desarrollo aparece un botón flotante «Simulador», que se puede arrastrar y abre los controles en un cajón lateral. Cualquier valor distinto de `development` oculta los controles. Las compilaciones release siempre excluyen las herramientas de desarrollo, incluso si `.env` conserva `development`:

```sh
flutter build web --release
```

Los parámetros opcionales `--dart-define=APP_ENV=...` y `--dart-define-from-file=config/production.json` siguen funcionando y tienen prioridad sobre `.env`.

El `.env` se incluye como un asset público en la app: úsalo solo para configuración pública, nunca para contraseñas o claves secretas. Ignorarlo en Git no evita que forme parte de la compilación.

## Accesibilidad y permisos

«Texto grande» aplica un aumento del 40 % a todos los textos, incluidos formularios, etiquetas, navegación, texto enriquecido y nombres del mapa. Se combina con la escala de texto del sistema. El alto contraste cambia fondos, textos y bordes en tema claro y oscuro. Ambas opciones están en el perfil y funcionan en producción.

En el primer inicio aparece una explicación de los accesos de cámara, ubicación, contactos, llamadas, dispositivos cercanos, Bluetooth y galería. «Permitir y continuar» solicita los permisos reales admitidos por la plataforma; «Ahora no» permite continuar sin concederlos. La elección de mostrar la explicación se recuerda localmente con SharedPreferences. Se puede volver a abrir desde «Permisos del dispositivo» en el perfil.

Android selecciona los permisos de galería, Bluetooth y Wi-Fi cercano según la versión del sistema. iOS declara sus motivos de uso en Info.plist y utiliza Swift Package Manager. En web se solicitan cámara y ubicación; contactos, archivos y Bluetooth no tienen un permiso general al iniciar y dependen de los selectores y APIs compatibles del navegador. En iOS y web no existe un permiso general para abrir el marcador de llamadas. La app informa de estas diferencias sin simular permisos concedidos. La validación física de las solicitudes debe hacerse en los dispositivos de destino.

La cuenta regresiva reduce su arco durante cinco segundos y mantiene los botones al pie, con el resto del contenido desplazable. La tarjeta de zona abre el mapa y el avatar conserva el acceso al perfil.

## Dictado con micrófono

«Dilo con tu voz» → «Activar micrófono» solicita permiso y usa reconocimiento de voz real. Muestra resultados parciales, permite detener, corregir y confirmar con «Usar este texto». No inventa frases ni publica automáticamente. Cerrar la hoja cancela la escucha.

Android, iOS y macOS incluyen las declaraciones de permisos de micrófono. En Android se utiliza el micrófono sin solicitar acceso adicional a Bluetooth. En web se necesita un navegador compatible, HTTPS o localhost, y permiso para el micrófono. El reconocimiento y su disponibilidad sin conexión dependen del dispositivo/proveedor. Si no está disponible o se deniega el permiso, se puede escribir.

Se utiliza [speech_to_text](https://pub.dev/packages/speech_to_text). En Windows, Flutter puede requerir activar el Modo de desarrollador del sistema para crear los enlaces de sus plugins; su soporte de reconocimiento de voz está marcado como beta por el paquete. La captura física debe validarse en cada dispositivo de destino.

## Tutorial

El tutorial resalta los controles reales, desplaza automáticamente el contenido y solo deja interactuar con el objetivo del paso. Las instrucciones y botones se acomodan al espacio disponible. La guía de emergencia también funciona sobre las hojas modales.

Las publicaciones de práctica no se guardan. Al salir se restauran las recomendaciones, el borrador, los filtros y el estado anterior de conexión/emergencia. Salir cancela cualquier avance pendiente.

## Verificación

```sh
flutter analyze
flutter test --dart-define-from-file=config/development.json
flutter test test/improvements_test.dart --dart-define-from-file=config/production.json
flutter build web --release --dart-define-from-file=config/production.json
```

Las pruebas recorren las 27 pantallas a 360, 390 y 1280 píxeles con modos normal, emergencia, oscuro, letra grande, alto contraste y sin conexión. También recorren ambos tutoriales completos, validan el anillo SOS desde las 12 durante dos segundos y comprueban los controles por ambiente. El dictado se prueba con un servicio inyectable para verificar permisos denegados, transcripción, confirmación y cancelación sin grabar audio durante las pruebas.

Exportar vistas de Flutter a `build/previews/`:

```sh
flutter test --dart-define=PREVIEW=true --dart-define=PREVIEW_WIDTH=390 --dart-define=APP_ENV=production test/prototype_flows_test.dart --plain-name "exporta vistas"
```

Las llamadas, SMS, ubicación, clasificación de IA y transmisión por sonido conservan la simulación local del prototipo. Los datos no persisten al reiniciar. Nunito se incluye con su licencia en `assets/fonts/`.
