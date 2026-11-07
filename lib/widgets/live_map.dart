import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/location_service.dart';
import 'navigation_chrome.dart';

class LiveMap extends StatefulWidget {
  final TileProvider? tileProvider;
  final double? centerLat, centerLng;
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
    required this.location,
    required this.pins,
    required this.onOpenPin,
    required this.bottomInset,
    required this.onMessage,
  });
  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  final _map = MapController();
  LatLng? _position;
  MapPin? _selected;
  bool _busy = false;
  bool _approximate = false;
  bool _tileError = false;
  LatLng get _initialCenter {
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
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            onTap: (_, _) {
              if (_selected != null) setState(() => _selected = null);
            },
            initialCenter: _initialCenter,
            initialZoom: 14,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              tileProvider: widget.tileProvider,
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.utp_comercio_frontend',
              maxNativeZoom: 19,
              errorTileCallback: (_, _, _) {
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
              },
            ),
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
                        color: Color(0xFF007D69),
                        size: 36,
                      ),
                    ),
                  ),
                ],
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
            onTap: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
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
