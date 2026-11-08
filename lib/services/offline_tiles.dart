import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Plantilla de teselas de OpenStreetMap (la misma que usa el mapa en línea).
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Identificador que OSM exige en el User-Agent (política de uso de teselas).
const String kTileUserAgent = 'flutter_map (com.example.utp_comercio_frontend)';

/// Estado de la descarga del mapa de la zona (para la pantalla de perfil).
@immutable
class OfflineMapStatus {
  final bool downloading;
  final int done;
  final int total;
  final int failed;

  /// Región guardada (null = nunca se descargó).
  final double? lat, lng;
  final double radiusKm;
  final int tiles;
  final int bytes;
  final DateTime? savedAt;
  final String? error;

  const OfflineMapStatus({
    this.downloading = false,
    this.done = 0,
    this.total = 0,
    this.failed = 0,
    this.lat,
    this.lng,
    this.radiusKm = 0,
    this.tiles = 0,
    this.bytes = 0,
    this.savedAt,
    this.error,
  });

  bool get saved => savedAt != null && tiles > 0;
  double get progress => total == 0 ? 0 : done / total;
  String get sizeText => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).round()} KB';

  OfflineMapStatus copyWith({
    bool? downloading,
    int? done,
    int? total,
    int? failed,
    double? lat,
    double? lng,
    double? radiusKm,
    int? tiles,
    int? bytes,
    DateTime? savedAt,
    String? error,
    bool clearError = false,
  }) => OfflineMapStatus(
    downloading: downloading ?? this.downloading,
    done: done ?? this.done,
    total: total ?? this.total,
    failed: failed ?? this.failed,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusKm: radiusKm ?? this.radiusKm,
    tiles: tiles ?? this.tiles,
    bytes: bytes ?? this.bytes,
    savedAt: savedAt ?? this.savedAt,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Coordenada de una tesela (z/x/y) del esquema XYZ de OSM.
typedef TileXYZ = ({int z, int x, int y});

/// Matemática de teselas Web Mercator (EPSG:3857), la que usa OSM.
class TileMath {
  TileMath._();

  static int lngToX(double lng, int z) =>
      ((lng + 180) / 360 * (1 << z)).floor().clamp(0, (1 << z) - 1).toInt();

  static int latToY(double lat, int z) {
    final r = lat * math.pi / 180;
    final n = (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2;
    return (n * (1 << z)).floor().clamp(0, (1 << z) - 1).toInt();
  }

  static double xToLng(int x, int z) => x / (1 << z) * 360 - 180;

  static double yToLat(int y, int z) {
    final n = math.pi - 2 * math.pi * y / (1 << z);
    return 180 / math.pi * math.atan((math.exp(n) - math.exp(-n)) / 2);
  }

  /// Teselas que tocan el círculo de [radiusKm] alrededor de (lat, lng),
  /// de [minZoom] a [maxZoom]. Descarta las esquinas del cuadrado (~20 % menos).
  static List<TileXYZ> tilesAround(
    double lat,
    double lng, {
    required double radiusKm,
    required int minZoom,
    required int maxZoom,
  }) {
    const kmPerDegLat = 110.574;
    final kmPerDegLng = 111.320 * math.cos(lat * math.pi / 180);
    final dLat = radiusKm / kmPerDegLat;
    final dLng = radiusKm / kmPerDegLng;
    final out = <TileXYZ>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final x0 = lngToX(lng - dLng, z), x1 = lngToX(lng + dLng, z);
      final y0 = latToY(lat + dLat, z), y1 = latToY(lat - dLat, z);
      for (var x = x0; x <= x1; x++) {
        for (var y = y0; y <= y1; y++) {
          // Punto de la tesela más cercano al centro; si está fuera del radio, se omite.
          final west = xToLng(x, z), east = xToLng(x + 1, z);
          final north = yToLat(y, z), south = yToLat(y + 1, z);
          final nearLng = lng.clamp(west, east).toDouble();
          final nearLat = lat.clamp(south, north).toDouble();
          final dx = (nearLng - lng) * kmPerDegLng;
          final dy = (nearLat - lat) * kmPerDegLat;
          if (dx * dx + dy * dy <= radiusKm * radiusKm) {
            out.add((z: z, x: x, y: y));
          }
        }
      }
    }
    return out;
  }

  /// Distancia aproximada en km (equirectangular; suficiente a escala de barrio).
  static double distanceKm(double aLat, double aLng, double bLat, double bLng) {
    final x =
        (bLng - aLng) * math.cos((aLat + bLat) / 2 * math.pi / 180) * 111.320;
    final y = (bLat - aLat) * 110.574;
    return math.sqrt(x * x + y * y);
  }
}

/// Caché local del mapa: guarda las teselas PNG de OSM en Hive (una "lazy box" en
/// disco, no en memoria) y sabe si el teléfono tiene conexión.
///
/// - [downloadRegion] baja de antemano el radio alrededor de la casa.
/// - [CachedTileProvider] sirve primero desde la caché y solo va a la red si hay
///   conexión; así, sin internet, el mapa sale igual en lugar de quedar en blanco.
///
/// En web no se usa (el caso sin conexión es el del celular).
class OfflineTiles {
  OfflineTiles._();
  static final OfflineTiles instance = OfflineTiles._();

  /// Radio por defecto alrededor de la casa.
  static const double defaultRadiusKm = 5;

  /// OSM prohíbe descargar áreas grandes a zoom 17 o más sin permiso, así que se
  /// guarda hasta 16; el mapa offline amplía esas teselas si el usuario acerca más.
  static const int minZoom = 12;
  static const int maxZoom = 16;

  /// Como pide la política de OSM: pocas descargas a la vez.
  static const int _parallel = 2;

  static const String _tilesBox = 'osm_tiles';
  static const String _metaBox = 'osm_tiles_meta';

  LazyBox<Uint8List>? _tiles;
  Box<dynamic>? _meta;
  final http.Client _http = http.Client();
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _cancel = false;

  /// true cuando la caché está abierta (main llama a [init]).
  bool get ready => _tiles != null;

  /// Conexión según el sistema (wifi, datos, ethernet...). Ojo: "conectado a wifi"
  /// no garantiza internet; por eso el proveedor de teselas también cae a la caché
  /// si la descarga falla.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  /// true si la conexión actual es wifi o ethernet (descarga automática sin gastar datos).
  bool unmetered = false;

  final ValueNotifier<OfflineMapStatus> status = ValueNotifier(
    const OfflineMapStatus(),
  );

  /// Abre la caché y empieza a escuchar la conexión. No falla nunca: si algo sale
  /// mal, el mapa sigue funcionando en línea como antes.
  Future<void> init() async {
    if (kIsWeb || ready) return;
    try {
      final dir = await getApplicationSupportDirectory();
      Hive.init('${dir.path}/map_cache');
      _tiles = await Hive.openLazyBox<Uint8List>(_tilesBox);
      _meta = await Hive.openBox<dynamic>(_metaBox);
      _loadMeta();
    } catch (e) {
      debugPrint('Mapa offline no disponible: $e');
      _tiles = null;
      return;
    }
    try {
      final conn = Connectivity();
      _applyConnectivity(await conn.checkConnectivity());
      _connSub = conn.onConnectivityChanged.listen(_applyConnectivity);
    } catch (_) {
      // Sin el plugin de conectividad se asume en línea y se cae a la caché al fallar.
    }
  }

  void _applyConnectivity(List<ConnectivityResult> r) {
    online.value = r.any((c) => c != ConnectivityResult.none);
    unmetered =
        r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
  }

  void _loadMeta() {
    final m = _meta?.get('region');
    if (m is! Map) return;
    status.value = OfflineMapStatus(
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      radiusKm: (m['radiusKm'] as num?)?.toDouble() ?? defaultRadiusKm,
      tiles: (m['tiles'] as num?)?.toInt() ?? 0,
      bytes: (m['bytes'] as num?)?.toInt() ?? 0,
      savedAt: m['savedAt'] is String
          ? DateTime.tryParse(m['savedAt'] as String)
          : null,
    );
  }

  static String keyOf(int z, int x, int y) => '$z/$x/$y';

  static String urlOf(int z, int x, int y) => kOsmTileUrl
      .replaceFirst('{z}', '$z')
      .replaceFirst('{x}', '$x')
      .replaceFirst('{y}', '$y');

  /// Bytes PNG guardados para esa tesela, o null.
  Future<Uint8List?> read(int z, int x, int y) async {
    final box = _tiles;
    if (box == null) return null;
    final k = keyOf(z, x, y);
    if (!box.containsKey(k)) return null;
    try {
      return await box.get(k);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(int z, int x, int y, Uint8List bytes) async {
    final box = _tiles;
    if (box == null || bytes.isEmpty) return;
    try {
      await box.put(keyOf(z, x, y), bytes);
    } catch (_) {}
  }

  /// Descarga la tesela de OSM (o null si falla). No guarda.
  Future<Uint8List?> fetch(int z, int x, int y) async {
    try {
      final res = await _http
          .get(
            Uri.parse(urlOf(z, x, y)),
            headers: const {'User-Agent': kTileUserAgent},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  /// true si ya hay una región guardada que cubre (lat, lng) con ese radio.
  bool covers(double lat, double lng, {double radiusKm = defaultRadiusKm}) {
    final s = status.value;
    if (!s.saved || s.lat == null || s.lng == null) return false;
    return TileMath.distanceKm(s.lat!, s.lng!, lat, lng) + radiusKm <=
        s.radiusKm + 0.5;
  }

  /// Descarga de antemano las teselas de [radiusKm] alrededor de (lat, lng).
  /// Reanuda: las teselas que ya están en la caché no se vuelven a pedir.
  /// Devuelve false si no se pudo (sin caché, sin conexión o ya descargando).
  Future<bool> downloadRegion(
    double lat,
    double lng, {
    double radiusKm = defaultRadiusKm,
  }) async {
    if (!ready || status.value.downloading) return false;
    if (!online.value) {
      status.value = status.value.copyWith(
        error: 'Sin conexión: conéctate para descargar el mapa.',
      );
      return false;
    }
    final list = TileMath.tilesAround(
      lat,
      lng,
      radiusKm: radiusKm,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    _cancel = false;
    var done = 0, failed = 0;
    status.value = status.value.copyWith(
      downloading: true,
      done: 0,
      total: list.length,
      failed: 0,
      clearError: true,
    );

    var next = 0;
    Future<void> worker() async {
      while (!_cancel && next < list.length) {
        final t = list[next++];
        if (!_tiles!.containsKey(keyOf(t.z, t.x, t.y))) {
          var bytes = await fetch(t.z, t.x, t.y);
          bytes ??= await fetch(t.z, t.x, t.y); // un reintento
          if (bytes != null) {
            await write(t.z, t.x, t.y, bytes);
          } else {
            failed++;
          }
          // Pausa corta entre pedidos para no cargar los servidores de OSM.
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
        done++;
        if (done % 8 == 0 || done == list.length) {
          status.value = status.value.copyWith(done: done, failed: failed);
        }
      }
    }

    await Future.wait([for (var i = 0; i < _parallel; i++) worker()]);

    final cancelled = _cancel;
    var bytes = 0;
    var stored = 0;
    for (final t in list) {
      final b = await read(t.z, t.x, t.y);
      if (b != null) {
        bytes += b.length;
        stored++;
      }
    }
    final ok = !cancelled && stored > 0;
    if (ok) {
      final savedAt = DateTime.now();
      await _meta?.put('region', {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'tiles': stored,
        'bytes': bytes,
        'savedAt': savedAt.toIso8601String(),
      });
      status.value = OfflineMapStatus(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        tiles: stored,
        bytes: bytes,
        savedAt: savedAt,
        done: done,
        total: list.length,
        failed: failed,
        error: failed > 0
            ? '$failed teselas no se pudieron bajar; vuelve a intentar con señal.'
            : null,
      );
    } else {
      status.value = status.value.copyWith(
        downloading: false,
        done: done,
        failed: failed,
        error: cancelled
            ? 'Descarga cancelada.'
            : 'No se pudo descargar el mapa. Revisa tu conexión.',
      );
    }
    return ok;
  }

  void cancelDownload() => _cancel = true;

  /// Borra todas las teselas guardadas.
  Future<void> clear() async {
    _cancel = true;
    await _tiles?.clear();
    await _meta?.delete('region');
    status.value = const OfflineMapStatus();
  }

  /// Proveedor de teselas para [TileLayer]: caché primero, red si hay conexión.
  /// Si la caché no está lista (web o pruebas) devuelve null y el mapa usa el
  /// proveedor de red normal de flutter_map.
  TileProvider? provider() => ready ? CachedTileProvider(this) : null;

  Future<void> dispose() async {
    await _connSub?.cancel();
    _http.close();
  }
}

/// [TileProvider] de flutter_map que lee las teselas de [OfflineTiles].
///
/// 1. Si la tesela está en la caché, la muestra (aunque haya internet: es más rápido).
/// 2. Si no está y hay conexión, la descarga de OSM y la guarda (caché de navegación).
/// 3. Si no está y no hay conexión, devuelve una tesela transparente: se ve el
///    fondo del mapa en esa parte en lugar de un error.
class CachedTileProvider extends TileProvider {
  final OfflineTiles cache;
  CachedTileProvider(this.cache) : super(headers: {});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _CachedTileImage(
        cache: cache,
        z: coordinates.z,
        x: coordinates.x,
        y: coordinates.y,
      );
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  final OfflineTiles cache;
  final int z, x, y;
  const _CachedTileImage({
    required this.cache,
    required this.z,
    required this.x,
    required this.y,
  });

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_CachedTileImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    var bytes = await cache.read(z, x, y);
    if (bytes == null && cache.online.value) {
      bytes = await cache.fetch(z, x, y);
      if (bytes != null) unawaited(cache.write(z, x, y, bytes));
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes ?? TileProvider.transparentImage,
    );
    return decode(
      buffer,
      getTargetSize: (int intrinsicWidth, int intrinsicHeight) =>
          const ui.TargetImageSize(width: 256, height: 256),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);
}
