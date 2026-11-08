import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../services/offline_tiles.dart';
import '../../../state/app_state.dart';
import '../../../theme/nearby_theme.dart';
import 'profile_ui.dart';

/// Hoja para elegir la casa en un mapa: el pin queda fijo al centro y se mueve el mapa hasta
/// la puerta exacta. Al soltar, la dirección se completa sola. «Usar mi GPS» centra el mapa
/// en la ubicación actual para afinarla.
void showEditAddressSheet(BuildContext context, AppState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _EditAddressSheet(state: state),
  );
}

class _EditAddressSheet extends StatefulWidget {
  final AppState state;
  const _EditAddressSheet({required this.state});

  @override
  State<_EditAddressSheet> createState() => _EditAddressSheetState();
}

class _EditAddressSheetState extends State<_EditAddressSheet> {
  static const _lima = LatLng(-11.9790, -77.0030);

  final _map = MapController();
  late final TextEditingController _address = TextEditingController(
    text: widget.state.userAddress,
  );
  late LatLng _point =
      (widget.state.regLat != null && widget.state.regLng != null)
      ? LatLng(widget.state.regLat!, widget.state.regLng!)
      : _lima;
  late final TileProvider? _cached = OfflineTiles.instance.provider();

  Timer? _lookup;
  bool _locating = false;
  bool _resolving = false;
  bool _saving = false;
  bool _moved = false;

  @override
  void dispose() {
    _lookup?.cancel();
    _address.dispose();
    _map.dispose();
    super.dispose();
  }

  /// El mapa se movió con el dedo: el centro es el nuevo punto de la casa.
  void _onMove(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _point = camera.center;
    _moved = true;
    _lookup?.cancel();
    // Busca la dirección cuando el mapa se queda quieto.
    _lookup = Timer(const Duration(milliseconds: 700), _reverseGeocode);
    setState(() {});
  }

  Future<void> _reverseGeocode() async {
    if (!mounted) return;
    setState(() => _resolving = true);
    final p = _point;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=${p.latitude}&lon=${p.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'Nearby/1.0 (vecinos SJL)'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted && p == _point) {
        final text = _format(jsonDecode(res.body) as Map<String, dynamic>);
        if (text != null) _address.text = text;
      }
    } catch (_) {
      // Sin internet: la persona escribe la dirección; el punto del mapa igual se guarda.
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  static String? _format(Map<String, dynamic> data) {
    final a = data['address'] as Map<String, dynamic>?;
    if (a == null) return null;
    final road = a['road'] as String?;
    final number = a['house_number'] as String?;
    final area =
        (a['suburb'] ?? a['neighbourhood'] ?? a['city_district'] ?? a['city'])
            as String?;
    if (road == null) return area;
    final street = number == null ? road : '$road $number';
    return area == null ? street : '$street, $area';
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final pos = await widget.state.location.current();
      _point = LatLng(pos.lat, pos.lng);
      _moved = true;
      _map.move(_point, 18);
      await _reverseGeocode();
    } catch (_) {
      widget.state.toast(
        'No pudimos usar tu GPS. Mueve el mapa hasta tu casa.',
        icon: 'error',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final text = _address.text.trim();
    if (text.isEmpty) {
      widget.state.toast(
        'Escribe tu dirección o una referencia',
        icon: 'warning',
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.state.updateUserLocation(
      address: text,
      lat: _point.latitude,
      lng: _point.longitude,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      widget.state.toast('Guardamos tu casa', icon: 'check_circle');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = uiThemeOf(widget.state);
    final ui = NearbyCommunityStyle(theme);
    return Padding(
      padding: uiSheetPadding(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSheetHeader(
              ui: ui,
              title: '¿Dónde está tu casa?',
              subtitle: 'Mueve el mapa hasta que el pin quede sobre tu puerta.',
              onClose: () => Navigator.pop(context),
            ),
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: ui.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: _point,
                          initialZoom: 17,
                          minZoom: 5,
                          maxZoom: 19,
                          onPositionChanged: _onMove,
                        ),
                        children: [
                          if (widget.state.networkMaps)
                            TileLayer(
                              tileProvider: _cached,
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.utp_comercio_frontend',
                              maxNativeZoom:
                                  _cached != null &&
                                      !OfflineTiles.instance.online.value
                                  ? OfflineTiles.maxZoom
                                  : 19,
                            ),
                        ],
                      ),
                      // Pin fijo al centro: se mueve el mapa, no el pin.
                      IgnorePointer(
                        child: Center(
                          // La punta del pin (abajo de la columna de 76 px) cae en el centro del mapa.
                          child: Transform.translate(
                            offset: const Offset(0, -36),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NearbyColors.brandNavy,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _moved ? 'Tu casa' : 'Mueve el mapa',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.location_on,
                                  size: 48,
                                  color: NearbyColors.brandTurquoise,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Material(
                          color: theme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: ui.line),
                          ),
                          child: IconButton(
                            tooltip: 'Usar mi GPS',
                            onPressed: _locating ? null : _useGps,
                            icon: _locating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.my_location, color: ui.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            UiLabeled(
              ui: ui,
              label: 'Dirección o referencia',
              child: TextField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: ui.ink, fontSize: 14),
                decoration: uiField(
                  ui,
                  hint: 'Ej. Jr. Los Jazmines 312, puerta verde',
                  icon: Icons.home_outlined,
                  suffix: _resolving
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ui.action(),
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: ui.onAccent,
                      ),
                    )
                  : const Text('Sí, aquí vivo'),
            ),
          ],
        ),
      ),
    );
  }
}
