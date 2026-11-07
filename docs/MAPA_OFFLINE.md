# Mapa sin conexión con el punto del SMS

**El problema:** sin internet, la brigada recibe un SMS comprimido con las coordenadas GPS del SOS. Al abrir el mapa, `flutter_map` pide las teselas a `tile.openstreetmap.org`, ninguna llega y el mapa sale en blanco.

**La solución:**

1. Descargar antes las teselas de OpenStreetMap de un radio de 5 km alrededor de la casa del vecino.
2. Guardarlas en el teléfono.
3. Cuando no hay conexión, dibujar el mapa con esas teselas y poner un marcador en las coordenadas del SMS.

## Cómo funciona

```
 SMS  ──►  Modo brigadista  ──►  decompressSOS()  ──►  "Ver en el mapa"  ──►  SmsMapScreen
                (pegar el SMS)    (tipo, lugar, lat/lng)                        │
                                                                                  ▼
                                               TileLayer(tileProvider: CachedTileProvider)
                                                                                  │
                                         ┌──────── ¿la tesela z/x/y está guardada? ────────┐
                                         │ sí                                               │ no
                                    Hive (disco)                          ¿hay conexión? ── sí ─► OSM ─► se guarda
                                                                                  │ no
                                                                       tesela transparente
```

| Pieza | Archivo | Qué hace |
|---|---|---|
| Caché y descarga | [lib/services/offline_tiles.dart](../lib/services/offline_tiles.dart) | `OfflineTiles`: abre la caché (Hive), escucha la conexión (`connectivity_plus`), descarga la región y guarda el estado |
| Proveedor de teselas | mismo archivo | `CachedTileProvider`: un `TileProvider` de `flutter_map` que lee primero de la caché |
| Matemática de teselas | mismo archivo | `TileMath`: lat/lng ↔ x/y (Web Mercator) y la lista de teselas que tocan el círculo de 5 km |
| Pantalla del SMS | [lib/screens/sms_map_screen.dart](../lib/screens/sms_map_screen.dart) | Mapa centrado en el SMS, marcador rojo, la casa, la distancia y un aviso de en línea o sin conexión |
| Código SMS con GPS | [lib/models/models.dart](../lib/models/models.dart) | `compressSOS(lat:, lng:)`, `decompressSOS`, `smsCoordinates`, `extractSosCode` |
| Descarga automática y manual | `AppState.ensureOfflineMap` | Sola con wifi después de cargar los datos; desde **Perfil › Sin conexión** también con datos |

### Por qué una caché propia y no `flutter_map_tile_caching`

FMTC es muy completo, pero:

- trae ObjectBox, una base nativa que agrega binarios por plataforma;
- tiene licencia GPL-3.0;
- su última versión es de marzo de 2025.

Para un solo radio fijo alrededor de la casa basta con unas 200 líneas. Hive (`hive_ce`) es Dart puro, así que no agrega código nativo. Además usamos una **LazyBox**: las teselas quedan en disco y solo se cargan a memoria las que se dibujan.

## 1. Descargar el radio de 5 km

`TileMath.tilesAround(lat, lng, radiusKm: 5, minZoom: 12, maxZoom: 16)` recorre el cuadrado que rodea el círculo en cada zoom y descarta las teselas que no tocan el círculo. Para usarlo, convierte grados a teselas con la fórmula estándar de OSM:

```dart
x = floor((lng + 180) / 360 * 2^z)
y = floor((1 - ln(tan(latRad) + 1/cos(latRad)) / π) / 2 * 2^z)
```

En San Juan de Lurigancho (lat −11.979, lng −77.003) salen **368 teselas**, unos **5 MB**:

| Zoom | Teselas |
|---|---|
| 12 | 4 |
| 13 | 9 |
| 14 | 23 |
| 15 | 74 |
| 16 | 258 |

`OfflineTiles.downloadRegion()`:

- descarga con **2 pedidos a la vez** y una pausa corta entre cada uno;
- envía un `User-Agent` que identifica a la app;
- reintenta una vez si falla;
- **retoma** donde se quedó, sin volver a pedir lo que ya está guardado.

Al terminar guarda en la caja `osm_tiles_meta` el centro, el radio, la cantidad de teselas, el tamaño y la fecha. El perfil muestra esos datos y permite **Actualizar** o **Borrar** el mapa.

```dart
// Al iniciar (main.dart)
await OfflineTiles.instance.init();

// Descargar 5 km alrededor de la casa
await OfflineTiles.instance.downloadRegion(homeLat, homeLng, radiusKm: 5);
```

> **Política de uso de OSM:** prohíbe descargar áreas grandes a **zoom 17 o más** sin permiso, y pide pocas conexiones a la vez y un User-Agent que identifique a la app. Por eso guardamos hasta el zoom 16. Si el usuario acerca más estando sin conexión, `maxNativeZoom: 16` hace que `flutter_map` amplíe esas mismas teselas. Para producción con muchos usuarios conviene un proveedor que permita uso offline, como MapTiler, Stadia o un servidor propio. Basta con cambiar `kOsmTileUrl`.

## 2. Mostrar el mapa desde la caché sin conexión

```dart
TileLayer(
  tileProvider: OfflineTiles.instance.provider(), // CachedTileProvider
  urlTemplate: kOsmTileUrl,
  userAgentPackageName: 'com.example.utp_comercio_frontend',
  maxNativeZoom: offline ? OfflineTiles.maxZoom : 19,
)
```

`CachedTileProvider.getImage()` devuelve un `ImageProvider` propio que decide así:

1. Si la tesela está en Hive, la muestra. Lo hace aunque haya internet, porque es más rápido.
2. Si no está y hay conexión, la baja de OSM y la guarda (caché mientras se navega).
3. Si no está y no hay conexión, devuelve una tesela transparente. Así no sale un error y se ve el fondo.

**Cómo detecta que no hay conexión:**

- `connectivity_plus` avisa cuando no hay wifi, datos ni ethernet (`OfflineTiles.online`).
- La pantalla también respeta el modo "Sin conexión" de la app (`state.offline`).
- Estar conectado a una red no garantiza tener internet. Por eso, si la descarga de una tesela falla, se usa la caché igual.

El mapa principal (`LiveMap`) usa el mismo proveedor, así que tampoco queda en blanco.

## 3. El SMS con coordenadas y el marcador

El código comprimido ahora puede terminar con el GPS, con 5 decimales (unos 1 m de precisión). Ocupa 46 caracteres y entra en un solo SMS:

```
NB#SOS!H1@LP340$P:ALTA#G:-11.97901,-77.00302
```

`decompressSOS()` también acepta el **SMS completo** que manda el backend a los contactos:

```
NEARBY SOS: María necesita ayuda. Ubicación: https://maps.google.com/?q=-11.97900,-77.00300 · Código NB#SOS!H1@LF245$P:ALTA
```

En ese SMS busca el código (`extractSosCode`) y las coordenadas (`smsCoordinates`).

Para ver el punto en el mapa:

1. En **Modo brigadista**, pega el SMS y toca **Descomprimir**.
2. Toca **Ver en el mapa (funciona sin internet)**. Se abre `SmsMapScreen` con:
   - el **marcador rojo** en las coordenadas del SMS;
   - la **casa** y una línea punteada hasta el punto;
   - la distancia, las coordenadas y los botones **Centrar** y **Ver con mi casa**;
   - un aviso: *En línea*, *Sin internet · mapa guardado de tu zona* o, si el punto cae fuera de lo descargado, *guíate por el marcador y las coordenadas*.

Al enviar el reporte al tablero, el backend recibe solo el código y las coordenadas del GPS van aparte. El backend decodifica únicamente la parte `NB#SOS!…`.

## Cómo probarlo

1. Abre la app con internet y wifi, e inicia sesión con una dirección guardada. Se descarga sola. También puedes ir a **Perfil › Sin conexión › Descargar mapa de tu zona**.
2. Espera a que diga *Mapa de tu zona guardado · ~5 MB*.
3. Pon el teléfono en **modo avión**.
4. Ve a **Modo brigadista**, pega `NB#SOS!H1@LP340$P:ALTA#G:-11.97901,-77.00302` (o un punto cerca de tu casa) y toca **Descomprimir** y luego **Ver en el mapa**.
5. Debe verse el mapa de la zona con el marcador y el aviso *Sin internet · mapa guardado de tu zona*.

Pruebas automáticas (no necesitan red): `flutter test test/offline_map_test.dart`. Cubren el número de teselas, el código con GPS y el SMS completo del backend.

## Límites

- **Web:** no hay caché offline (`OfflineTiles.ready == false`) y el mapa usa la red como antes. El caso sin conexión es el del celular.
- **Puntos fuera de los 5 km:** se ven el marcador y las coordenadas sobre un fondo liso.
- **Mapa desactualizado:** las teselas guardadas no se renuevan solas. Usa **Actualizar** en el perfil.
- **Lectura del SMS:** el SMS se pega a mano en el modo brigadista. Leerlo automáticamente desde la bandeja de Android necesita permisos de SMS que Google Play restringe.
