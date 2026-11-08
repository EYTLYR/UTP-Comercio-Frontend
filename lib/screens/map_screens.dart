import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show TileProvider;
import 'package:latlong2/latlong.dart' show Distance, LatLng, LengthUnit;
import 'package:url_launcher/url_launcher.dart';

import '../widgets/interactions.dart';
import '../widgets/navigation_chrome.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/map_view.dart';
import '../widgets/live_map.dart';
import '../models/models.dart';

// --- Piezas comunes de las capas del mapa ---

/// Ancho máximo de las tarjetas flotantes sobre el mapa (el mapa sigue a pantalla completa).
const double _kOverlayMaxWidth = 520;

/// Chip de filtro del mapa: radio 8, fondo de tarjeta con borde; elegido = tinta.
class _MapFilterChip extends StatelessWidget {
  final NearbyThemeData theme;
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _MapFilterChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    final bg = selected ? (ui.light ? ui.ink : theme.btnBg) : theme.surface;
    final fg = selected ? (ui.light ? Colors.white : theme.btnInk) : ui.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: theme.cardShadow,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: selected ? bg : ui.line),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta flotante sobre el mapa: borde de línea, radio 12, sombra suave.
class _MapCard extends StatelessWidget {
  final NearbyThemeData theme;
  final Widget child;
  const _MapCard({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    return Align(
      alignment: Alignment.bottomLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kOverlayMaxWidth),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: ui.line),
            borderRadius: BorderRadius.circular(12),
            boxShadow: theme.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Botón principal ámbar; en emergencia o ayuda conserva el rojo SOS.
ButtonStyle _mapPrimary(NearbyCommunityStyle ui, {bool red = false}) =>
    ui.action().copyWith(
      backgroundColor: WidgetStatePropertyAll(
        red ? NearbyColors.sos : ui.accent,
      ),
      foregroundColor: WidgetStatePropertyAll(red ? Colors.white : ui.onAccent),
    );

// --- Interactive Map Screen ---
class DemoMapScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const DemoMapScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final em = state.emergency;
    final allPins = em ? state.emergencyPins : state.normalPins;
    final filteredPins = allPins.where((p) {
      if (state.mapFilter == 'all') return true;
      if (state.mapFilter == 'fav') {
        return p.kind == 'need' || p.kind == 'offer';
      }
      return p.kind == state.mapFilter;
    }).toList();

    final selPin = allPins.where((p) => p.id == state.mapSel).firstOrNull;

    final filters = em
        ? [
            ['all', 'Todo', Icons.layers],
            ['vuln', 'Vulnerables', Icons.elderly],
            ['safe', 'Puntos seguros', Icons.flag],
            ['res', 'Recursos', Icons.inventory_2],
            ['group', 'Apoyo', Icons.diversity_3],
          ]
        : [
            ['all', 'Todo', Icons.layers],
            ['svc', 'Servicios', Icons.handyman],
            ['fav', 'Favores', Icons.volunteer_activism],
          ];

    return Stack(
      children: [
        // Map Vector Canvas
        Positioned.fill(
          child: NearbyMapView(
            theme: theme,
            emergency: em,
            pins: filteredPins,
            selectedPinId: state.mapSel,
            onPinSelected: (pinId) {
              state.mapSel = pinId;
              state.refresh();
            },
          ),
        ),

        // Filtros arriba
        Positioned(
          top: NavigationInsets.of(context).top + 10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(16) + 26,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final id = filters[i][0] as String;
                final label = filters[i][1] as String;
                final icon = filters[i][2] as IconData;
                return _MapFilterChip(
                  theme: theme,
                  label: label,
                  icon: icon,
                  selected: state.mapFilter == id,
                  onTap: () {
                    state.mapFilter = id;
                    state.mapSel = null;
                    state.refresh();
                  },
                );
              },
            ),
          ),
        ),

        // Tarjeta inferior
        Positioned(
          left: 16,
          right: 16,
          bottom: NavigationInsets.of(context).bottom + 16,
          child: _MapCard(
            theme: theme,
            child: selPin != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getPinColor(selPin.kind),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              selPin.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selPin.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: ui.ink,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  selPin.sub,
                                  style: TextStyle(
                                    color: ui.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () {
                              state.mapSel = null;
                              state.refresh();
                            },
                            icon: Icon(Icons.close, color: ui.ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                state.routeTo = {
                                  'title': selPin.title,
                                  'icon': selPin.icon,
                                  'kind': selPin.kind,
                                };
                                state.go('ruta');
                              },
                              style: ui.action(filled: false),
                              icon: const Icon(Icons.directions_walk, size: 18),
                              label: const Text(
                                'Cómo llegar',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (selPin.svc != null) {
                                  state.selService = selPin.svc!;
                                  state.go('svc');
                                } else if (selPin.go != null) {
                                  state.go(selPin.go!);
                                } else {
                                  state.routeTo = {
                                    'title': selPin.title,
                                    'icon': selPin.icon,
                                    'kind': selPin.kind,
                                  };
                                  state.go('ruta');
                                }
                              },
                              style: _mapPrimary(ui, red: em),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text(
                                'Ver detalle',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: em
                            ? [
                                _legendDot(NearbyColors.sos, 'Vulnerables'),
                                _legendDot(NearbyColors.info, 'Seguros'),
                                _legendDot(NearbyColors.accent, 'Recursos'),
                                _legendDot(NearbyColors.violet, 'Apoyo'),
                                _legendDot(NearbyColors.info, 'Tú'),
                              ]
                            : [
                                _legendDot(NearbyColors.navy, 'Servicios'),
                                _legendDot(NearbyColors.accent, 'Necesitan'),
                                _legendDot(NearbyColors.primary, 'Ofrecen'),
                                _legendDot(NearbyColors.info, 'Tú'),
                              ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: ui.line),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.download_done, color: ui.ink, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Datos de ejemplo · Las distancias no son reales',
                              style: TextStyle(color: ui.muted, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ui.ivory,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ui.ink,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPinColor(String kind) {
    switch (kind) {
      case 'svc':
        return NearbyColors.navy;
      case 'need':
        return NearbyColors.accent;
      case 'offer':
        return NearbyColors.primary;
      case 'vuln':
        return NearbyColors.sos;
      case 'safe':
        return NearbyColors.info;
      case 'res':
        return NearbyColors.accent;
      case 'group':
        return NearbyColors.violet;
      default:
        return NearbyColors.primary;
    }
  }
}

// --- Route Screen ---
class RouteScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const RouteScreen({super.key, required this.state, required this.theme});

  /// 260 m · 1,2 km
  static String _fmtDist(double m) => m < 1000
      ? '${m.round()} m'
      : '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  @override
  Widget build(BuildContext context) {
    final r =
        state.routeTo ??
        (state.connected
            ? <String, dynamic>{
                'title': 'Elige un destino en el mapa',
                'icon': Icons.flag,
                'kind': 'safe',
              }
            : <String, dynamic>{
                'title': 'Punto de reunión · Parque Las Flores',
                'sub': 'Zona segura',
                'icon': Icons.flag,
                'kind': 'safe',
              });
    final lat = (r['lat'] as num?)?.toDouble();
    final lng = (r['lng'] as num?)?.toDouble();
    final dest = lat != null && lng != null ? LatLng(lat, lng) : null;
    // Sin sesión ni coordenadas: ruta de ejemplo de la demo.
    final demo = !state.connected && dest == null;
    final title = (r['title'] as String?) ?? 'Destino';
    final sub = (r['sub'] as String?) ?? '';
    final icon = (r['icon'] as IconData?) ?? Icons.flag;

    // Distancia en línea recta desde el último GPS real.
    final gps = state.location.last;
    final meters = dest != null && gps != null && gps.real
        ? const Distance().as(LengthUnit.Meter, LatLng(gps.lat, gps.lng), dest)
        : null;

    final isHelp = r['kind'] == 'help' || r['kind'] == 'vuln';
    final col = isHelp
        ? NearbyColors.sos
        : (r['kind'] == 'safe' ? NearbyColors.info : NearbyColors.primary);

    final Widget map;
    if (dest != null && state.networkMaps) {
      map = LiveMap(
        key: ValueKey('route-${dest.latitude},${dest.longitude}'),
        centerLat: dest.latitude,
        centerLng: dest.longitude,
        location: state.location,
        pins: [
          MapPin(
            latitude: dest.latitude,
            longitude: dest.longitude,
            id: 'route-dest',
            kind: (r['kind'] as String?) ?? 'safe',
            x: 0,
            y: 0,
            icon: icon,
            title: title,
            sub: sub,
          ),
        ],
        onOpenPin: (_) {},
        topInset: NavigationInsets.controlsOf(context).top,
        bottomInset: 236,
        onMessage: state.toast,
      );
    } else if (demo) {
      map = NearbyMapView(
        theme: theme,
        emergency: state.emergency,
        pins: const [],
        showRoute: true,
        routeColor: col,
        routeDestIcon: icon,
      );
    } else {
      // Sin coordenadas del destino: no dibujamos una ruta inventada.
      map = Container(
        color: theme.surface,
        alignment: const Alignment(0, -0.4),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ui.blueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_off_outlined, color: ui.ink, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              dest == null
                  ? 'Este destino no tiene ubicación exacta'
                  : 'El mapa no está disponible ahora',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: map),

        // Tarjeta de la ruta
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _MapCard(
            theme: theme,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isHelp ? theme.sosSoft : ui.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_walk,
                        color: isHelp ? NearbyColors.sos : ui.ink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: demo
                                      ? '4 min'
                                      : (meters != null
                                            ? _fmtDist(meters)
                                            : 'Destino'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: ui.ink,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (demo || meters != null)
                                  TextSpan(
                                    text: demo
                                        ? ' · 260 m a pie'
                                        : ' en línea recta',
                                    style: TextStyle(
                                      color: ui.muted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ui.ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!demo && sub.isNotEmpty)
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: ui.muted, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (demo) ...[
                  // Indicaciones paso a paso (solo demo)
                  Divider(height: 1, color: ui.line),
                  _stepRow(Icons.straight, 'Camina 40 m por Jr. Las Flores'),
                  Divider(height: 1, color: ui.line),
                  _stepRow(
                    Icons.turn_left,
                    'Gira a la izquierda en la Av. Principal (110 m)',
                  ),
                  Divider(height: 1, color: ui.line),
                  _stepRow(
                    Icons.turn_right,
                    'Gira a la derecha en Jr. Los Pinos; llegas en 70 m',
                  ),
                  Divider(height: 1, color: ui.line),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.download_done, color: ui.ink, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ruta disponible sin conexión',
                          style: TextStyle(color: ui.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Indicaciones paso a paso: las da Google Maps
                if (dest != null) ...[
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=walking',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    style: ui.action(filled: false),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: const Text('Abrir ruta en Google Maps'),
                  ),
                  const SizedBox(height: 8),
                ],

                ElevatedButton.icon(
                  onPressed: () {
                    state.back();
                    state.toast(
                      isHelp
                          ? 'Avisamos a la brigada que llegaste'
                          : 'Llegaste a tu destino',
                      icon: 'where_to_vote',
                    );
                  },
                  style: _mapPrimary(ui, red: isHelp),
                  icon: const Icon(Icons.where_to_vote, size: 20),
                  label: Text(
                    isHelp ? 'Llegué, avisar que estoy aquí' : 'Ya llegué',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ui.blueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ui.ink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: ui.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final TileProvider? tileProvider;
  final AppState state;
  final NearbyThemeData theme;
  const MapScreen({
    super.key,
    required this.state,
    required this.theme,
    this.tileProvider,
  });
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    if (!widget.state.networkMaps) {
      return DemoMapScreen(state: widget.state, theme: widget.theme);
    }
    final insets = NavigationInsets.controlsOf(context);
    final filters = widget.state.emergency
        ? const [
            ('all', 'Todo'),
            ('vuln', 'Vulnerables'),
            ('safe', 'Puntos seguros'),
            ('res', 'Recursos'),
            ('group', 'Apoyo'),
          ]
        : const [('all', 'Todo'), ('svc', 'Servicios'), ('fav', 'Favores')];
    final pins = widget.state.connected
        ? (widget.state.emergency
              ? widget.state.emergencyPins
              : widget.state.normalPins)
        : <MapPin>[];
    final filtered = pins
        .where(
          (pin) =>
              widget.state.mapFilter == 'all' ||
              (widget.state.mapFilter == 'fav'
                  ? pin.kind == 'need' || pin.kind == 'offer'
                  : pin.kind == widget.state.mapFilter),
        )
        .toList();
    return Stack(
      children: [
        Positioned.fill(
          child: LiveMap(
            tileProvider: widget.tileProvider,
            key: ValueKey('zone-view-${widget.state.zoneViewRevision}'),
            centerLat:
                widget.state.viewedZone?.latitude ?? widget.state.homeZoneLat,
            centerLng:
                widget.state.viewedZone?.longitude ?? widget.state.homeZoneLng,
            // La casa del perfil centra el mapa; mirando otra zona se centra en esa zona.
            homeLat: widget.state.viewedZone == null
                ? widget.state.regLat
                : null,
            homeLng: widget.state.viewedZone == null
                ? widget.state.regLng
                : null,
            location: widget.state.location,
            pins: filtered,
            onOpenPin: (pin) {
              if (pin.svc != null) {
                widget.state.selService = pin.svc!;
                widget.state.go('svc');
              } else if (pin.go != null) {
                widget.state.go(pin.go!);
              }
            },
            topInset: insets.top,
            bottomInset: insets.bottom,
            onMessage: widget.state.toast,
            onBoundsChanged: (minLat, maxLat, minLon, maxLon) {
              widget.state.loadPinsInBounds(
                minLat: minLat,
                maxLat: maxLat,
                minLon: minLon,
                maxLon: maxLon,
              );
            },
          ),
        ),
        Positioned(
          key: const ValueKey('map-filter-control'),
          top: insets.top + 4,
          left: 4,
          right: 4,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(16) + 32,
                  child: ListView.separated(
                    key: const ValueKey('map-filter-strip'),
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.zero,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final filter = filters[index];
                      final selected = widget.state.mapFilter == filter.$1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _MapFilterChip(
                          theme: widget.theme,
                          label: filter.$2,
                          selected: selected,
                          onTap: () {
                            widget.state.mapFilter = filter.$1;
                            widget.state.mapSel = null;
                            widget.state.refresh();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NearbyFilterButton(
                theme: widget.theme,
                active: widget.state.mapFilter == 'all' ? 0 : 1,
                onPressed: () => _openFilters(context, filters),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Panel lateral: qué mostrar en el mapa y qué significa cada color de pin.
  void _openFilters(BuildContext context, List<(String, String)> filters) {
    final state = widget.state;
    final theme = widget.theme;
    final ui = NearbyCommunityStyle(theme);
    final legend = state.emergency
        ? const [
            ('vuln', 'Vecino vulnerable', Icons.accessible),
            ('safe', 'Punto seguro', Icons.flag),
            ('res', 'Recurso disponible', Icons.inventory_2),
            ('group', 'Grupo de apoyo', Icons.diversity_3),
          ]
        : const [
            ('need', 'Pide ayuda', Icons.front_hand),
            ('offer', 'Ofrece ayuda', Icons.volunteer_activism),
            ('svc', 'Oficio del barrio', Icons.handyman),
          ];
    showNearbyFilterPanel(
      context: context,
      theme: theme,
      title: 'Filtrar el mapa',
      subtitle: 'Elige qué ver cerca de ti',
      onClear: () {
        state.mapFilter = 'all';
        state.mapSel = null;
        state.refresh();
      },
      builder: (context, setPanel) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NearbyFilterGroup(theme: theme, title: 'Mostrar'),
          for (final (id, label) in filters)
            NearbyFilterOption(
              theme: theme,
              label: label,
              selected: state.mapFilter == id,
              onTap: () {
                state.mapFilter = id;
                state.mapSel = null;
                state.refresh();
                setPanel(() {});
              },
            ),
          const SizedBox(height: 8),
          NearbyFilterGroup(theme: theme, title: 'Qué significa cada color'),
          for (final (kind, label, icon) in legend)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: pinColor(kind),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(icon, size: 15, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: ui.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
