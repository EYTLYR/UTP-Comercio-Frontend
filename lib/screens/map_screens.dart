import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/map_view.dart';

// --- Interactive Map Screen ---
class MapScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const MapScreen({super.key, required this.state, required this.theme});

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

        // Filter chips on top
        Positioned(
          top: NavigationInsets.of(context).top + 10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final id = filters[i][0] as String;
                final label = filters[i][1] as String;
                final icon = filters[i][2] as IconData;
                final isSel = state.mapFilter == id;

                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSel ? theme.btnInk : theme.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(label),
                    ],
                  ),
                  selected: isSel,
                  onSelected: (_) {
                    state.mapFilter = id;
                    state.mapSel = null;
                    state.refresh();
                  },
                  backgroundColor: theme.surface,
                  selectedColor: theme.btnBg,
                  labelStyle: TextStyle(
                    fontFamily: 'Nunito',
                    color: isSel ? theme.btnInk : theme.ink,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: isSel ? theme.btnBg : theme.line),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),

        // Bottom Map Sheet
        Positioned(
          left: 14,
          right: 14,
          bottom: NavigationInsets.of(context).bottom + 14,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              selPin.icon,
                              color: Colors.white,
                              size: 24,
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
                                    fontWeight: FontWeight.w900,
                                    color: theme.ink,
                                    fontSize: 14.5,
                                  ),
                                ),
                                Text(
                                  selPin.sub,
                                  style: TextStyle(
                                    color: theme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              state.mapSel = null;
                              state.refresh();
                            },
                            icon: const Icon(Icons.close),
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.ink,
                                side: BorderSide(color: theme.line, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              icon: Icon(
                                Icons.directions_walk,
                                color: theme.primary,
                                size: 18,
                              ),
                              label: const Text(
                                'Cómo llegar',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: em
                                    ? NearbyColors.sos
                                    : theme.btnBg,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text(
                                'Ver detalle',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
                        spacing: 12,
                        runSpacing: 6,
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.download_done,
                            color: theme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Mapa de tu zona guardado para usar sin conexión · radio 500 m',
                              style: TextStyle(
                                color: theme.muted,
                                fontSize: 12,
                              ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: theme.ink,
          ),
        ),
      ],
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

  const RouteScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final r =
        state.routeTo ??
        {
          'title': 'Punto de reunión · Parque Las Flores',
          'sub': 'Zona segura',
          'icon': Icons.flag,
          'kind': 'safe',
        };

    final isHelp = r['kind'] == 'help' || r['kind'] == 'vuln';
    final col = isHelp
        ? NearbyColors.sos
        : (r['kind'] == 'safe' ? NearbyColors.info : NearbyColors.primary);

    return Stack(
      children: [
        Positioned.fill(
          child: NearbyMapView(
            theme: theme,
            emergency: state.emergency,
            pins: const [],
            showRoute: true,
            routeColor: col,
            routeDestIcon: (r['icon'] as IconData?) ?? Icons.flag,
          ),
        ),

        // Route Card
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.directions_walk,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '4 min',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: theme.ink,
                                ),
                              ),
                              Text(
                                ' · 260 m a pie',
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            r['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Turn-by-turn directions
                _stepRow(Icons.straight, 'Camina 40 m por Jr. Las Flores', col),
                _stepRow(
                  Icons.turn_left,
                  'Gira a la izquierda en la Av. Principal (110 m)',
                  col,
                ),
                _stepRow(
                  Icons.turn_right,
                  'Gira a la derecha en Jr. Los Pinos; llegas en 70 m',
                  col,
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.download_done, color: theme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Ruta disponible sin conexión',
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHelp ? NearbyColors.sos : theme.btnBg,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.where_to_vote, size: 20),
                  label: Text(
                    isHelp ? 'Llegué, avisar que estoy aquí' : 'Ya llegué',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepRow(IconData icon, String text, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: theme.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
