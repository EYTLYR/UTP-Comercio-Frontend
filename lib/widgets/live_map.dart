import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/location_service.dart';
import '../services/offline_tiles.dart';
import 'navigation_chrome.dart';

class LiveMap extends StatefulWidget {
  final TileProvider? tileProvider;
  final double? centerLat, centerLng;

  /// Casa del vecino (la dirección de su perfil): se marca con una casita.
  final double? homeLat, homeLng;
  final LocationService location;
  final List<MapPin> pins;
  final ValueChanged<MapPin> onOpenPin;
  final double topInset;
  final double bottomInset;
  final ValueChanged<String> onMessage;
  const LiveMap({
    super.key,
    required this.topInset,
    this.tileProvider,
    this.centerLat,
    this.centerLng,
    this.homeLat,
    this.homeLng,
    required this.location,
    required this.pins,
    required this.onOpenPin,
    required this.bottomInset,
    required this.onMessage,
  });
  @override
  State<LiveMap> createState() => _LiveMapState();
}

/// Capas del mapa: calles (OpenStreetMap), relieve (OpenTopoMap) y satélite (Esri).
enum MapLayerStyle {
  streets('Calles', Icons.map_outlined),
  terrain('Relieve', Icons.terrain),
  satellite('Satélite', Icons.satellite_alt);

  const MapLayerStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _LiveMapState extends State<LiveMap> {
  final _map = MapController();
  MapLayerStyle _layer = MapLayerStyle.streets;
  LatLng? _position;
  MapPin? _selected;
  bool _busy = false;
  bool _approximate = false;
  bool _tileError = false;
  // Caché del mapa offline; null en web y en pruebas (usa la red como antes).
  late final TileProvider? _cached = OfflineTiles.instance.provider();
  LatLng? get _home => widget.homeLat != null && widget.homeLng != null
      ? LatLng(widget.homeLat!, widget.homeLng!)
      : null;

  LatLng get _initialCenter {
    if (_home != null) return _home!;
    if (widget.centerLat != null && widget.centerLng != null) {
      return LatLng(widget.centerLat!, widget.centerLng!);
    }
    final pin = widget.pins
        .where((p) => p.latitude != null && p.longitude != null)
        .firstOrNull;
    return pin == null
        ? const LatLng(-12.0464, -77.0428)
        : LatLng(pin.latitude!, pin.longitude!);
  }

  Future<void> _locate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final position = await widget.location.current();
      if (!position.real) {
        throw Exception(
          'No se pudo obtener la ubicación. Activa el GPS o revisa tu conexión.',
        );
      }
      if (!mounted) return;
      final point = LatLng(position.lat, position.lng);
      setState(() {
        _position = point;
        _approximate = widget.location.approximate;
      });
      if (_approximate) {
        widget.onMessage(
          'Posición aproximada por red. Activa el GPS para mayor precisión.',
        );
      }
      _map.move(point, 16);
    } catch (error) {
      if (mounted) {
        widget.onMessage(
          error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : 'No se pudo obtener la ubicación. Puedes explorar el mapa manualmente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _zoomBy(double delta) {
    final camera = _map.camera;
    _map.move(camera.center, (camera.zoom + delta).clamp(3.0, 19.0));
  }

  Future<void> _chooseLayer() async {
    final picked = await showModalBottomSheet<MapLayerStyle>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tipo de mapa',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            for (final layer in MapLayerStyle.values)
              ListTile(
                leading: Icon(layer.icon),
                title: Text(layer.label),
                subtitle: Text(switch (layer) {
                  MapLayerStyle.streets =>
                    'Calles y nombres (funciona sin internet)',
                  MapLayerStyle.terrain => 'Cerros, quebradas y pendientes',
                  MapLayerStyle.satellite => 'Foto aérea de tu barrio',
                }),
                trailing: layer == _layer
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () => Navigator.pop(ctx, layer),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && picked != _layer && mounted) {
      setState(() {
        _layer = picked;
        _tileError = false;
      });
    }
  }

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (!_tileError && mounted) {
      _tileError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onMessage(
            'No se pudo cargar la cartografía. Revisa tu conexión.',
          );
        }
      });
    }
  }

  TileLayer _tiles() {
    final offline =
        _cached != null &&
        widget.tileProvider == null &&
        !OfflineTiles.instance.online.value;
    return switch (_layer) {
      MapLayerStyle.streets => TileLayer(
        key: const ValueKey('tiles-streets'),
        tileProvider: widget.tileProvider ?? _cached,
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.utp_comercio_frontend',
        // Sin internet solo hay teselas guardadas hasta el zoom 16: se amplían.
        maxNativeZoom: offline ? OfflineTiles.maxZoom : 19,
        errorTileCallback: _onTileError,
      ),
      MapLayerStyle.terrain => TileLayer(
        key: const ValueKey('tiles-terrain'),
        tileProvider: widget.tileProvider,
        urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c'],
        userAgentPackageName: 'com.example.utp_comercio_frontend',
        maxNativeZoom: 17,
        errorTileCallback: _onTileError,
      ),
      MapLayerStyle.satellite => TileLayer(
        key: const ValueKey('tiles-satellite'),
        tileProvider: widget.tileProvider,
        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.example.utp_comercio_frontend',
        maxNativeZoom: 18,
        errorTileCallback: _onTileError,
      ),
    };
  }

  ({String text, String url}) get _attribution => switch (_layer) {
    MapLayerStyle.streets => (
      text: '© OpenStreetMap contributors',
      url: 'https://www.openstreetmap.org/copyright',
    ),
    MapLayerStyle.terrain => (
      text: '© OpenStreetMap · OpenTopoMap (CC-BY-SA)',
      url: 'https://opentopomap.org/about',
    ),
    MapLayerStyle.satellite => (
      text: 'Imágenes © Esri, Maxar, Earthstar Geographics',
      url: 'https://www.esri.com/en-us/legal/terms/full-master-agreement',
    ),
  };

  Widget _control({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    required String heroTag,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      child: Icon(icon),
    ),
  );

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      NavigationContentFade.wrap(
        context,
        RepaintBoundary(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              onTap: (_, _) {
                if (_selected != null) setState(() => _selected = null);
              },
              initialCenter: _initialCenter,
              initialZoom: _home != null ? 16 : 14,
              minZoom: 3,
              maxZoom: 19,
              // Pellizcar, doble toque y rueda del mouse acercan; sin girar el mapa.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              _tiles(),
              MarkerLayer(
                markers: widget.pins
                    .where((p) => p.latitude != null && p.longitude != null)
                    .map(
                      (p) => Marker(
                        point: LatLng(p.latitude!, p.longitude!),
                        width: 44,
                        height: 44,
                        child: IconButton.filled(
                          tooltip: p.title,
                          onPressed: () => setState(() => _selected = p),
                          icon: Icon(p.icon, size: 22),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_home != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _home!,
                      width: 48,
                      height: 48,
                      child: const Tooltip(
                        message: 'Tu casa',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF0B2D6B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position!,
                      width: 44,
                      height: 44,
                      child: Tooltip(
                        message: _approximate
                            ? 'Ubicación aproximada por red'
                            : 'Tu ubicación',
                        child: Icon(
                          Icons.my_location,
                          color: Color(0xFF00796B),
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      Positioned(
        key: const ValueKey('map-zoom-control'),
        right: 4,
        bottom: widget.bottomInset + 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _control(
              heroTag: 'map-layer',
              tooltip: 'Tipo de mapa: ${_layer.label}',
              icon: Icons.layers,
              onPressed: _chooseLayer,
            ),
            if (_home != null)
              _control(
                heroTag: 'map-home',
                tooltip: 'Ir a mi casa',
                icon: Icons.home,
                onPressed: () => _map.move(_home!, 17),
              ),
            _control(
              heroTag: 'map-zoom-in',
              tooltip: 'Acercar',
              icon: Icons.add,
              onPressed: () => _zoomBy(1),
            ),
            _control(
              heroTag: 'map-zoom-out',
              tooltip: 'Alejar',
              icon: Icons.remove,
              onPressed: () => _zoomBy(-1),
            ),
          ],
        ),
      ),
      Positioned(
        key: const ValueKey('map-location-control'),
        right: 4,
        bottom: widget.bottomInset + 4,
        child: FloatingActionButton.small(
          heroTag: 'map-location',
          tooltip: 'Mi ubicación',
          onPressed: _busy ? null : _locate,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ),
      if (_selected != null)
        Positioned(
          left: 4,
          right: 64,
          bottom: widget.bottomInset + 38,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    ((MediaQuery.sizeOf(context).height -
                                widget.topInset -
                                widget.bottomInset) *
                            .55)
                        .clamp(90, 240),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selected!.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar detalle',
                          onPressed: () => setState(() => _selected = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      _selected!.sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selected!.svc != null || _selected!.go != null)
                      TextButton(
                        onPressed: () => widget.onOpenPin(_selected!),
                        child: const Text('Ver detalle'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      Positioned(
        key: const ValueKey('map-attribution'),
        left: 4,
        bottom: widget.bottomInset + 4,
        child: Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(_attribution.url)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                _attribution.text,
                style: const TextStyle(
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
