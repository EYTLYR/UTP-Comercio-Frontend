import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';

class LiveMap extends StatefulWidget {
  final List<MapPin> pins;
  final ValueChanged<MapPin> onOpenPin;
  final double topInset;
  final double bottomInset;
  final ValueChanged<String> onMessage;
  const LiveMap({
    super.key,
    required this.topInset,
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
  bool _tileError = false;
  LatLng get _initialCenter {
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Activa la ubicación del teléfono para encontrar tu posición.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permite el acceso a tu ubicación en los ajustes del dispositivo.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _position = point);
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
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 14,
          minZoom: 3,
          maxZoom: 19,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.utp_comercio_frontend',
            maxNativeZoom: 19,
            errorTileCallback: (_, _, _) {
              if (!_tileError && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _tileError = true);
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
                  child: const Tooltip(
                    message: 'Tu ubicación',
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
      Positioned(
        right: 16,
        top: widget.topInset + 12,
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
      Positioned(
        left: 12,
        right: 12,
        bottom: widget.bottomInset + 12,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selected != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected!.title,
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
                  Text(_selected!.sub),
                  if (_selected!.svc != null || _selected!.go != null)
                    TextButton(
                      onPressed: () => widget.onOpenPin(_selected!),
                      child: const Text('Ver detalle'),
                    ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _tileError
                      ? 'No se pudo cargar la cartografía. Revisa tu conexión.'
                      : _position == null
                      ? 'Explora el mapa o pulsa Mi ubicación.'
                      : 'Ubicación del dispositivo · Acerca y desplaza el mapa',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
