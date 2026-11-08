import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import 'nearby_logo.dart';

/// Ancho desde el que la app usa navegación lateral (escritorio y tablet horizontal).
const double kDesktopBreakpoint = 900;

/// Ancho máximo del contenido en escritorio (el mapa usa todo el ancho).
const double kDesktopContentMaxWidth = 1100;

/// Navegación lateral de escritorio: las mismas secciones que la barra inferior del celular, más Mensajes
/// y Perfil, el botón ámbar de Publicar y el SOS siempre a mano.
class NearbySideNav extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  const NearbySideNav({super.key, required this.state, required this.theme});

  static String _current(String screen) => switch (screen) {
    'home' || 'tablero' => 'home',
    'servicios' || 'svc' => 'servicios',
    'chat' || 'mensajes' => 'mensajes',
    'municipalidad' || 'muni-registro' => 'municipalidad',
    _ => screen,
  };

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    final em = state.emergency;
    final current = _current(state.screen);
    final items = <(String, IconData, String)>[
      ('home', Icons.home_outlined, 'Inicio'),
      if (em) ...[
        ('apoyo', Icons.diversity_3_outlined, 'Apoyo'),
        ('recursos', Icons.inventory_2_outlined, 'Recursos'),
        ('tablero', Icons.dashboard_outlined, 'Tablero'),
      ] else ...[
        ('servicios', Icons.handyman_outlined, 'Servicios'),
        ('muro', Icons.volunteer_activism_outlined, 'Muro'),
      ],
      ('mapa', Icons.map_outlined, 'Mapa'),
      if (state.connected) ('mensajes', Icons.chat_bubble_outline, 'Mensajes'),
      ('perfil', Icons.person_outline, 'Mi perfil'),
      if (state.isAdmin) ('municipalidad', Icons.account_balance_outlined, 'Panel'),
    ];

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(right: BorderSide(color: ui.line)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const NearbyLogo(width: 34),
                    const SizedBox(width: 10),
                    Text(
                      'Nearby',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ui.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: state.tourTarget('nav-publicar'),
                onPressed: () => state.selectTab('publicar'),
                style: ui.action(),
                icon: const Icon(Icons.add, size: 20),
                label: Text(em ? 'Reportar' : 'Publicar'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final (id, icon, label) in items)
                      _SideNavItem(
                        key: const {
                          'home',
                          'servicios',
                          'muro',
                          'mapa',
                          'apoyo',
                          'recursos',
                        }.contains(id)
                            ? state.tourTarget('nav-$id')
                            : null,
                        icon: icon,
                        label: label,
                        selected: current == id,
                        badge: id == 'mensajes' ? state.unreadMessages : 0,
                        ui: ui,
                        onTap: () => const {
                          'home',
                          'servicios',
                          'muro',
                          'mapa',
                          'apoyo',
                          'recursos',
                        }.contains(id)
                            ? state.selectTab(id)
                            : state.go(id),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ui.ivory,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: ui.ink, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.visibleZoneName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ui.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => state.go('sos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NearbyColors.sos,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                icon: const Icon(Icons.emergency, size: 20),
                label: const Text('SOS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final NearbyCommunityStyle ui;
  final VoidCallback onTap;
  const _SideNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.ui,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: selected ? ui.blueSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 22, color: selected ? ui.ink : ui.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? ui.ink : ui.muted,
                  ),
                ),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NearbyColors.sos,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
