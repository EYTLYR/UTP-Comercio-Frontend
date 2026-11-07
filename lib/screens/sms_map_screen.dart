import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/offline_tiles.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/navigation_chrome.dart';

/// Mapa del punto recibido por SMS (modo brigadista).
///
/// Funciona sin internet: las teselas salen de la caché local que se descargó
/// antes (5 km alrededor de la casa). Si el punto cae fuera de lo descargado,
/// igual se ve el marcador con las coordenadas y la distancia a la casa.
class SmsMapScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const SmsMapScreen({super.key, required this.state, required this.theme});

  @override
  State<SmsMapScreen> createState() => _SmsMapScreenState();
}

class _SmsMapScreenState extends State<SmsMapScreen> {
  final _map = MapController();
  final _tiles = OfflineTiles.instance;
  late final TileProvider? _provider = _tiles.provider();

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.state.smsPoint;
    final theme = widget.theme;
    if (point == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay coordenadas para mostrar. Pega un SMS con GPS en el modo brigadista.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.muted),
          ),
        ),
      );
    }
    final sos = LatLng(point.lat, point.lng);
    final homeLat = widget.state.regLat ?? widget.state.homeZoneLat;
    final homeLng = widget.state.regLng ?? widget.state.homeZoneLng;
    final home = homeLat != null && homeLng != null
        ? LatLng(homeLat, homeLng)
        : null;
    final insets = NavigationInsets.controlsOf(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _tiles.online,
      builder: (context, online, _) {
        // Sin conexión real o con el modo "sin conexión" de la app activado.
        final offline = widget.state.offline || !online;
        final covered = _tiles.covers(point.lat, point.lng, radiusKm: 0);
        final distKm = home == null
            ? null
            : TileMath.distanceKm(
                home.latitude,
                home.longitude,
                sos.latitude,
                sos.longitude,
              );
        return Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: sos,
                  initialZoom: 16,
                  minZoom: 3,
                  maxZoom: 19,
                  backgroundColor: theme.surface2,
                ),
                children: [
                  TileLayer(
                    tileProvider: _provider,
                    urlTemplate: kOsmTileUrl,
                    userAgentPackageName: 'com.example.utp_comercio_frontend',
                    // Sin internet solo existen las teselas guardadas (hasta zoom 16);
                    // al acercar más, flutter_map amplía esas mismas teselas.
                    maxNativeZoom: offline && _provider != null
                        ? OfflineTiles.maxZoom
                        : 19,
                  ),
                  if (home != null && distKm != null && distKm > 0.02)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [home, sos],
                          color: NearbyColors.sos.withValues(alpha: .7),
                          strokeWidth: 3,
                          pattern: StrokePattern.dashed(segments: const [8, 6]),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (home != null)
                        Marker(
                          point: home,
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: 'Tu casa',
                            child: Icon(
                              Icons.home_rounded,
                              color: theme.primaryDark,
                              size: 32,
                            ),
                          ),
                        ),
                      Marker(
                        point: sos,
                        width: 52,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: const Tooltip(
                          message: 'Ubicación del SMS',
                          child: Icon(
                            Icons.location_on,
                            color: NearbyColors.sos,
                            size: 52,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: insets.top + 8,
              left: 8,
              right: 8,
              child: _Banner(
                theme: theme,
                offline: offline,
                covered: covered,
                hasCache: _provider != null,
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: insets.bottom + 8,
              child: Material(
                color: theme.surface,
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sms, color: NearbyColors.sos),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              point.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (point.sub.isNotEmpty) point.sub,
                          '${point.lat.toStringAsFixed(5)}, ${point.lng.toStringAsFixed(5)}',
                          if (distKm != null) _distanceText(distKm),
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: theme.muted),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _map.move(sos, 17),
                            icon: const Icon(Icons.center_focus_strong),
                            label: const Text('Centrar'),
                          ),
                          if (home != null)
                            TextButton.icon(
                              onPressed: () => _map.fitCamera(
                                CameraFit.coordinates(
                                  coordinates: [home, sos],
                                  padding: const EdgeInsets.fromLTRB(
                                    48,
                                    140,
                                    48,
                                    200,
                                  ),
                                  maxZoom: 17,
                                ),
                              ),
                              icon: const Icon(Icons.home_rounded),
                              label: const Text('Ver con mi casa'),
                            ),
                          const Spacer(),
                          if (!offline)
                            IconButton(
                              tooltip: 'Abrir en otra app de mapas',
                              onPressed: () => launchUrl(
                                Uri.parse(
                                  'https://www.openstreetmap.org/?mlat=${point.lat}&mlon=${point.lng}#map=17/${point.lat}/${point.lng}',
                                ),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(Icons.open_in_new),
                            ),
                        ],
                      ),
                      const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _distanceText(double km) => km < 1
      ? 'a ${(km * 1000).round()} m de tu casa'
      : 'a ${km.toStringAsFixed(1)} km de tu casa';
}

class _Banner extends StatelessWidget {
  final NearbyThemeData theme;
  final bool offline, covered, hasCache;
  const _Banner({
    required this.theme,
    required this.offline,
    required this.covered,
    required this.hasCache,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String text) = !offline
        ? (Icons.wifi, NearbyColors.primary, 'En línea · mapa actualizado')
        : covered
        ? (
            Icons.offline_pin,
            NearbyColors.accent,
            'Sin internet · mapa guardado de tu zona',
          )
        : (
            Icons.cloud_off,
            NearbyColors.sos,
            hasCache
                ? 'Sin internet y este punto está fuera del mapa guardado: guíate por el marcador y las coordenadas.'
                : 'Sin internet y sin mapa guardado: descarga tu zona en Perfil › Sin conexión.',
          );
    return Material(
      color: theme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
