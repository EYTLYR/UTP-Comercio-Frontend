# Nearby · Flutter

Interfaz y navegación basadas en `../prototipo.html`. La app se adapta a móvil, web y escritorio sin marco de teléfono ni panel fijo de simulación.

## Conexión con el backend (Nearby API)

La app usa la API de [UTP-Comercio-Backend](https://github.com/EYTLYR/UTP-Comercio-Backend) (Spring Boot). Levanta el backend primero (`./mvnw spring-boot:run "-Dspring-boot.run.profiles=local"` con Neon, o `./mvnw spring-boot:test-run` sin internet) y luego la app:

```sh
flutter pub get
flutter run -d chrome                                         # web: http://localhost:8080
flutter run -d emulator-5554                                  # Android: http://10.0.2.2:8080
flutter run --dart-define=API_URL=http://192.168.1.20:8080    # celular físico: IP de la PC
flutter build apk --dart-define=API_URL=https://api.midominio.pe
```

- **Ingreso:** código SMS real (`/auth/otp`). En el perfil `dev` del backend el código es `123456`. La sesión se guarda (token de refresco) y se renueva sola.
- **Registro:** nombre, ubicación del GPS (zona más cercana), contactos de confianza (se agregan con nombre y celular) y consentimiento de IA.
- **Datos:** servicios y Visto Bueno, reseñas, muro de favores, chat (se actualiza cada 4 s), mapa, recursos, grupos de apoyo, tablero de reportes, ficha médica y lo que la IA aprendió.
- **SOS:** envía la ubicación real, muestra cuántos vecinos, contactos y brigadistas recibieron la alerta y quién va en camino. Cada 20 s la app revisa si un vecino cercano pidió ayuda y abre «Alerta de un vecino».
- **Modos:** la Municipalidad (o un delegado) cambia el modo de toda la zona desde el interruptor de emergencia; los vecinos lo ven en su app. Un vecino puede activarlo solo en su app o volver al modo normal.
- **Brigada:** «Tablero», «Red de rescate» y «Modo brigadista» solo se muestran a BRIGADIST, DELEGATE y ADMIN. El plan de rescate con IA y el aviso de misiones usan el backend.
- **Sin conexión:** con «Sin conexión» del simulador, las publicaciones, reportes, mensajes, check-ins y SOS van a una cola y se envían en orden al volver la señal (`/sync/outbox`).

Código: `lib/api/` (cliente HTTP, configuración, traducción de datos) y `lib/state/app_state_backend.dart` (todas las llamadas). Sin sesión, por ejemplo en las pruebas de widgets, la app usa los datos de ejemplo de `lib/models/models.dart`.

Android permite HTTP sin cifrar únicamente en debug para probar contra un backend local. Las compilaciones release requieren HTTPS. iOS permite solo la red local (`NSAllowsLocalNetworking`).

## Ambientes

La app lee automáticamente el archivo `.env` de la raíz antes de iniciar. Al clonar el proyecto, copia `.env.example` a `.env` (este último está ignorado por Git):

```dotenv
APP_ENV=development
# Emulador Android; en celular físico usa la IP LAN del equipo del backend.
API_BASE_URL=http://10.0.2.2:8080
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

## Navegación y contenido

Las barras principales permanecen fijas y el contenido se desplaza por detrás. Los degradados superior e inferior usan una transición suave de opacidad, sin superponer una capa blanca adicional, al entrar el contenido bajo los controles. No hay un panel blanco flotante. El espacio de desplazamiento se calcula con la altura real de las barras para conservar legibles el primer y el último elemento, también con texto grande y en modo oscuro.

## Accesibilidad y permisos

«Texto grande» aplica un aumento del 40 % a todos los textos, incluidos formularios, etiquetas, navegación, texto enriquecido y nombres del mapa. Se combina con la escala de texto del sistema. El alto contraste cambia fondos, textos y bordes en tema claro y oscuro. Ambas opciones están en el perfil y funcionan en producción. Los interruptores apagados mantienen pista y contorno visibles en ambos temas. El interruptor de emergencia del perfil activa el modo directamente; desactivarlo conserva la confirmación.

En el primer inicio aparece una explicación de los accesos de cámara, ubicación, contactos, llamadas, dispositivos cercanos, Bluetooth y galería. «Permitir y continuar» solicita los permisos reales admitidos por la plataforma; «Ahora no» permite continuar sin concederlos. La elección de mostrar la explicación se recuerda localmente con SharedPreferences. Se puede volver a abrir desde «Permisos del dispositivo» en el perfil.

Android selecciona los permisos de galería, Bluetooth y Wi-Fi cercano según la versión del sistema. iOS declara sus motivos de uso en Info.plist y utiliza Swift Package Manager. En web se solicitan cámara y ubicación; contactos, archivos y Bluetooth no tienen un permiso general al iniciar y dependen de los selectores y APIs compatibles del navegador. En iOS y web no existe un permiso general para abrir el marcador de llamadas. La app informa de estas diferencias sin simular permisos concedidos. La validación física de las solicitudes debe hacerse en los dispositivos de destino.

La cuenta regresiva reduce su arco durante cinco segundos y mantiene los botones al pie, con el resto del contenido desplazable. La tarjeta de zona abre el mapa y el avatar conserva el acceso al perfil.

## Dictado con micrófono

«Dilo con tu voz» → «Activar micrófono» solicita permiso y usa reconocimiento de voz real. Muestra resultados parciales, permite detener, corregir y confirmar con «Usar este texto». No inventa frases ni publica automáticamente. Cerrar la hoja cancela la escucha.

Android, iOS y macOS incluyen las declaraciones de permisos de micrófono. En Android se utiliza el micrófono sin solicitar acceso adicional a Bluetooth. En web se necesita un navegador compatible, HTTPS o localhost, y permiso para el micrófono. El reconocimiento y su disponibilidad sin conexión dependen del dispositivo/proveedor. Si no está disponible o se deniega el permiso, se puede escribir.

Se utiliza [speech_to_text](https://pub.dev/packages/speech_to_text). En Windows, Flutter puede requerir activar el Modo de desarrollador del sistema para crear los enlaces de sus plugins; su soporte de reconocimiento de voz está marcado como beta por el paquete. La captura física debe validarse en cada dispositivo de destino.

## Tutorial

La app ya no ofrece el tutorial (se quitaron los botones de inicio, perfil, cuenta lista y emergencia). El código queda para el simulador de desarrollo y las pruebas. El tutorial resalta los controles reales, desplaza automáticamente el contenido y solo deja interactuar con el objetivo del paso. Las instrucciones y botones se acomodan al espacio disponible. La guía de emergencia también funciona sobre las hojas modales.

Las publicaciones de práctica no se guardan. Al salir se restauran las recomendaciones, el borrador, los filtros y el estado anterior de conexión/emergencia. Salir cancela cualquier avance pendiente.

## Compilación Android

`permission_handler` está fijado en `12.0.1`, cuya implementación Android compila con API 35. Es compatible con el SDK 36 utilizado por este proyecto. La versión `13.0.2` del paquete resuelve un plugin que exige `android-37`; actualizarla requiere revisar primero los SDK instalados.

```sh
flutter pub get
flutter run
```

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

Las llamadas telefónicas y la transmisión por sonido siguen simuladas. Sin backend (pruebas de widgets), la app usa los datos de ejemplo y no persiste cambios. Nunito se incluye con su licencia en `assets/fonts/`.

## SMS, llamadas y mapa del dispositivo

El acceso usa `/api/v1/auth/otp/request` y `/api/v1/auth/otp/verify` del cliente compartido. El código no se acepta localmente: lo valida el backend. En Android con Google Play Services se solicita consentimiento para leer un único SMS (SMS User Consent); si se rechaza o no está disponible, permite escribir o pegar el código. iOS usa la sugerencia de código del teclado. No se solicita acceso general a las notificaciones ni al buzón. El código de desarrollo solo se muestra si el backend devuelve `devCode` y la app está en desarrollo. Para recibir SMS reales, el backend debe usar su proveedor SMS real; el proveedor `console` solo escribe el mensaje en los logs.

Los números de emergencia abren el marcador para confirmar la llamada. Otros números registrados usan el permiso `CALL_PHONE` en Android; si se rechaza, se abre el marcador. En otras plataformas se usa `tel:`. Los contactos sin teléfono registrado no simulan una llamada. Los controles de audio y la duración corresponden a la aplicación Teléfono.

El mapa usa OpenStreetMap y los pines con coordenadas del backend. «Mi ubicación» solicita acceso al GPS. Se puede navegar sin concederlo; la cartografía necesita conexión. Los ejemplos siguen disponibles únicamente en desarrollo y no se colocan sobre la posición real del usuario. Los avisos aparecen al pie con una barra de duración y se descartan con un deslizamiento o el botón cerrar.

Si aparece el error de SDK `android-37`, ejecuta `flutter pub get` con este `pubspec.lock`: `permission_handler` permanece fijado en `12.0.1`, compatible con el SDK del proyecto. Los avisos de versiones más nuevas disponibles no son errores y no requieren actualizar las versiones principales.
