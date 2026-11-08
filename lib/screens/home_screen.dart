import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/interactions.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const HomeScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (state.emergency) {
      return _buildEmergencyHome(context);
    }
    return _buildNormalHome(context);
  }

  // --- Normal Home ---
  Widget _buildNormalHome(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    return LayoutBuilder(
      builder: (context, constraints) {
        // < 700: diseño móvil. ≥ 700: rejillas más anchas. ≥ 900: dos columnas.
        final wide = constraints.maxWidth >= 700;
        final split = constraints.maxWidth >= 900;
        // Margen lateral común a todas las secciones.
        final gutter = constraints.maxWidth < 360 ? 16.0 : 24.0;

        // Greeting
        final greeting = Padding(
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${state.firstName}',
                style: TextStyle(
                  color: ui.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¿Qué necesitas hoy?',
                style: TextStyle(
                  color: ui.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        );

        // Zone emergency banner if zone still in emergency
        final Widget? zoneBanner = state.zoneEm
            ? Container(
                margin: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.sosSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.crisis_alert, color: theme.sosDark, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'La emergencia sigue activa en tu zona',
                            style: TextStyle(
                              color: theme.sosDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Saliste del modo emergencia en tu app.',
                            style: TextStyle(
                              color: theme.sosDark.withValues(alpha: 0.8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        state.emergency = true;
                        state.emSource = 'zona';
                        state.refresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NearbyColors.sos,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null;

        // Section "Día a día"
        final dayGrid = Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: GridView.count(
            crossAxisCount: wide && !split ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
            mainAxisExtent: (theme.lg ? 154 : 102) * theme.scaleFactor,
            children: [
              NearbyHover(
                child: _buildTile(
                  icon: Icons.handyman_outlined,
                  color: ui.onAccent,
                  softColor: ui.accent,
                  homeStyle: ui,
                  featured: true,
                  title: 'Buscar un servicio',
                  subtitle: 'Oficios del barrio',
                  onTap: () => state.go('servicios'),
                ),
              ),
              NearbyHover(
                child: _buildTile(
                  icon: Icons.favorite_border_rounded,
                  color: ui.ink,
                  softColor: ui.blueSoft,
                  homeStyle: ui,
                  title: 'Pedir un favor',
                  subtitle: 'Entre vecinos',
                  onTap: () {
                    state.pub.reset(step: 2, type: 'need');
                    state.go('publicar');
                  },
                ),
              ),
              NearbyHover(
                child: _buildTile(
                  icon: Icons.add_rounded,
                  color: ui.ink,
                  softColor: ui.blueSoft,
                  homeStyle: ui,
                  title: 'Ofrecer ayuda',
                  subtitle: 'Presta, dona o enseña',
                  onTap: () {
                    state.pub.reset(step: 2, type: 'offer');
                    state.go('publicar');
                  },
                ),
              ),
              NearbyHover(
                child: _buildTile(
                  icon: Icons.map_outlined,
                  color: ui.ink,
                  softColor: ui.blueSoft,
                  homeStyle: ui,
                  title: 'Ver el mapa',
                  subtitle: 'Explora tu zona',
                  onTap: () => state.go('mapa'),
                ),
              ),
            ],
          ),
        );

        // AI Summary Banner
        final Widget? brigadeBanner = state.isBrigade
            ? Padding(
                padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
                child: PressableScale(
                  onTap: () => state.go('red'),
                  scale: 0.98,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.violet.withValues(alpha: 0.12),
                          theme.violet.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(
                        color: theme.violet.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [NearbyColors.violet, NearbyColors.navy2],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
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
                                'Tu barrio ya está preparado',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: theme.ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'La IA detectó ${state.buildInventory().where((e) => kAiTags[e.tag]?.kind != "vuln").length} recursos y habilidades de rescate en los favores de cada día',
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.muted),
                      ],
                    ),
                  ),
                ),
              )
            : null;

        final hero = <Widget>[
          greeting,
          // SOS Card
          NearbySosCard(theme: theme, state: state),
          ?zoneBanner,
        ];
        final shortcuts = <Widget>[
          _buildSectionHeader('Día a día', homeStyle: ui, gutter: gutter),
          dayGrid,
          ?brigadeBanner,
        ];

        return ListView(
          padding:
              NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
          children: [
            Divider(height: 1, indent: 24, endIndent: 24, color: ui.line),
            if (split)
              _splitColumns(hero, shortcuts)
            else ...[
              ...hero,
              ...shortcuts,
            ],

            // Recommended Services Horizontal Scroll
            _buildSectionHeader(
              'Recomendados por tus vecinos',
              homeStyle: ui,
              gutter: gutter,
              actionText: 'Ver todos',
              onAction: () => state.go('servicios'),
            ),
            SizedBox(
              height: 100 * theme.scaleFactor,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                scrollDirection: Axis.horizontal,
                itemCount: state.services.take(5).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final s = state.services[i];
                  return NearbyHover(
                    child: InkWell(
                      onTap: () {
                        state.selService = s.id;
                        state.go('svc');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 164 * theme.scaleFactor,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          border: Border.all(color: ui.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: ui.blueSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(s.icon, color: ui.ink, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: ui.ink,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        s.job,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: ui.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ui.ivory,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: ui.ink, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s.vb + (state.vbGiven[s.id] == true ? 1 : 0)}',
                                    style: TextStyle(
                                      color: ui.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // In the wall right now
            _buildSectionHeader(
              'En el muro ahora',
              homeStyle: ui,
              gutter: gutter,
              actionText: 'Ver muro',
              onAction: () => state.go('muro'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: _cardRows(
                state.posts
                    .take(2)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NearbyHover(child: _buildPostCard(p)),
                      ),
                    )
                    .toList(),
                wide ? 2 : 1,
              ),
            ),
            Padding(
              // El ícono del botón queda alineado con el margen.
              padding: EdgeInsets.fromLTRB(gutter - 12, 12, gutter, 0),
              child: TextButton.icon(
                onPressed: () => state.startTour('main'),
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('Aprende tocando la app (1 minuto)'),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Emergency Home ---
  Widget _buildEmergencyHome(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    final pendingCount = state.reports.where((r) => r.status != 'a').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // < 700: diseño móvil. ≥ 700: rejillas más anchas. ≥ 900: dos columnas.
        final wide = constraints.maxWidth >= 700;
        final split = constraints.maxWidth >= 900;
        // Margen lateral común a todas las secciones.
        final gutter = constraints.maxWidth < 360 ? 16.0 : 24.0;

        // Greeting
        final greeting = Padding(
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.firstName}, mantén la calma',
                style: TextStyle(
                  color: ui.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tu barrio se está organizando',
                style: TextStyle(
                  color: ui.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
            ],
          ),
        );

        // Check-in card "¿Cómo estás?"
        final checkinCard = Container(
          key: state.tourTarget('checkin'),
          margin: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: ui.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: state.checkin
              ? Row(
                  children: [
                    _iconSquare(Icons.check_circle, ui.ink, ui.blueSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marcaste que estás bien',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ui.ink,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            state.contacts.isEmpty
                                ? 'Avisamos a la brigada de tu zona.'
                                : 'Avisamos a tus ${state.contacts.length} contactos y a la brigada.',
                            style: TextStyle(color: ui.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cómo estás?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ui.ink,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu respuesta llega a tus contactos y al tablero del barrio.',
                      style: TextStyle(color: ui.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              state.checkin = true;
                              state.refresh();
                              final sent = await state.sendCheckIn(true);
                              state.toast(
                                sent == null
                                    ? 'Avisamos a tus contactos que estás bien'
                                    : 'Avisamos a tus $sent contactos que estás bien',
                                icon: 'check_circle',
                              );
                            },
                            style: ui.action(),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text(
                              'Estoy bien',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          // Rojo: pedir ayuda es una acción de emergencia.
                          child: OutlinedButton.icon(
                            onPressed: () => state.go('sos'),
                            style: ui
                                .action(filled: false)
                                .copyWith(
                                  foregroundColor: const WidgetStatePropertyAll(
                                    NearbyColors.sos,
                                  ),
                                  side: const WidgetStatePropertyAll(
                                    BorderSide(
                                      color: NearbyColors.sos,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                            icon: const Icon(Icons.emergency, size: 18),
                            label: const Text(
                              'Necesito ayuda',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );

        // Plan de rescate: panel informativo o botón principal
        final Widget? aiPlan = state.isBrigade
            ? Padding(
                padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
                child: state.aiStatus == 'done'
                    ? NearbyHover(
                        child: Material(
                          color: ui.blueSoft,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => state.go('tablero'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  _iconSquare(
                                    Icons.auto_awesome,
                                    ui.ink,
                                    theme.surface,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plan de rescate con IA activo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: ui.ink,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${state.aiMissions.values.fold(0, (sum, m) => sum + m.length)} vecinos asignados · ver misiones',
                                          style: TextStyle(
                                            color: ui.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: ui.ink),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          state.go('tablero');
                          state.runAi();
                        },
                        style: ui.action().copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Generar plan de rescate con IA'),
                      ),
              )
            : null;

        // Section "Coordinar ayuda" (2x2 grid)
        final coordGrid = Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: GridView.count(
            crossAxisCount: wide && !split ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: (theme.lg ? 154 : 112) * theme.scaleFactor,
            children: [
              NearbyHover(
                child: _buildTile(
                  icon: Icons.elderly,
                  // Rojo: personas en riesgo.
                  color: NearbyColors.sos,
                  softColor: theme.sosSoft,
                  homeStyle: ui,
                  title: 'Reportar vecino',
                  subtitle: 'Adultos mayores, heridos…',
                  onTap: () {
                    state.pub.reset(step: 2, type: 'vulnerable');
                    state.go('publicar');
                  },
                ),
              ),
              NearbyHover(
                child: _buildTile(
                  icon: Icons.inventory_2_outlined,
                  color: ui.ink,
                  softColor: ui.blueSoft,
                  homeStyle: ui,
                  title: 'Recursos críticos',
                  subtitle: 'Agua, víveres, energía',
                  onTap: () => state.go('recursos'),
                ),
              ),
              NearbyHover(
                child: _buildTile(
                  icon: Icons.diversity_3_outlined,
                  color: ui.ink,
                  softColor: ui.blueSoft,
                  homeStyle: ui,
                  title: 'Grupos de apoyo',
                  subtitle: 'Brigadas y oficios',
                  onTap: () => state.go('apoyo'),
                ),
              ),
              NearbyHover(
                child: _buildTile(
                  icon: Icons.flag_outlined,
                  color: ui.ink,
                  softColor: ui.blueSoft,
                  homeStyle: ui,
                  title: 'Puntos seguros',
                  subtitle: 'Reunión y refugios',
                  onTap: () {
                    state.mapFilter = 'safe';
                    state.mapSel = null;
                    state.go('mapa');
                  },
                ),
              ),
            ],
          ),
        );

        // Section "Tablero del barrio" with stats
        final stats = Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              _buildStatCard(
                '${state.connected ? state.reports.length : state.reports.length + 14}',
                'Reportes',
                ui,
              ),
              const SizedBox(width: 8),
              _buildStatCard('$pendingCount', 'Por atender', ui),
              const SizedBox(width: 8),
              // Vecinos que dijeron «Estoy bien» desde que empezó la emergencia
              _buildStatCard(
                state.connected
                    ? '${state.zoneDashboard['safeCheckIns'] ?? 0}'
                    : '64',
                'A salvo',
                ui,
              ),
            ],
          ),
        );

        // Urgent Reports previews
        final reports = Padding(
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
          child: _cardRows(
            state.reports.where((r) => r.status != 'a').take(2).map((r) {
              return _buildReportPreview(r, ui);
            }).toList(),
            wide && !split ? 2 : 1,
          ),
        );

        // Exit emergency mode banner
        final exitBanner = Padding(
          padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
          child: NearbyHover(
            child: Material(
              color: theme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: ui.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => state.openSheet('em-off'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _iconSquare(Icons.verified_user, ui.ink, ui.blueSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Ya pasó la emergencia?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ui.ink,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Vuelve al modo normal de Nearby',
                              style: TextStyle(color: ui.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: ui.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final hero = <Widget>[
          greeting,
          // SOS Card: la misma que en el modo normal (trae su margen de 24)
          NearbySosCard(theme: theme, state: state),
          checkinCard,
          ?aiPlan,
        ];
        final board = <Widget>[
          _buildSectionHeader('Coordinar ayuda', homeStyle: ui, gutter: gutter),
          coordGrid,
          _buildSectionHeader(
            'Tablero del barrio',
            homeStyle: ui,
            gutter: gutter,
            actionText: state.isBrigade ? 'Ver todo' : null,
            onAction: state.isBrigade ? () => state.go('tablero') : null,
          ),
          stats,
          reports,
          exitBanner,
        ];

        return ListView(
          padding:
              NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
          children: [
            Divider(
              height: 1,
              indent: gutter,
              endIndent: gutter,
              color: ui.line,
            ),
            if (split) _splitColumns(hero, board) else ...[...hero, ...board],
          ],
        );
      },
    );
  }

  // Cuadrito de ícono (radio 8) de las tarjetas.
  Widget _iconSquare(IconData icon, Color color, Color bg) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  // --- Responsive helpers ---
  // Dos columnas alineadas arriba (pantallas anchas).
  Widget _splitColumns(List<Widget> left, List<Widget> right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: right,
          ),
        ),
      ],
    );
  }

  // Reparte tarjetas en filas de [cols] columnas con su altura natural.
  Widget _cardRows(List<Widget> items, int cols) {
    if (cols <= 1) return Column(children: items);
    return Column(
      children: [
        for (var i = 0; i < items.length; i += cols)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(
                  child: i + j < items.length
                      ? items[i + j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
      ],
    );
  }

  // --- Helpers ---
  Widget _buildSectionHeader(
    String title, {
    String? actionText,
    VoidCallback? onAction,
    required NearbyCommunityStyle homeStyle,
    double gutter = 24,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: actionText == null ? 18 : 14,
                fontWeight: FontWeight.w700,
                color: homeStyle.ink,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionText != null)
            PressableScale(
              onTap: onAction,
              scale: 0.95,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: homeStyle.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required Color softColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required NearbyCommunityStyle homeStyle,
    bool featured = false,
  }) {
    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: featured ? homeStyle.ivory : theme.surface,
          border: Border.all(color: homeStyle.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(icon, color: color, size: 22)),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: homeStyle.ink,
                  size: 20,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: homeStyle.ink,
                    fontSize: 12.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: homeStyle.muted,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostItem p) {
    final isDone = state.helped[p.id] == true;
    final catObj = kPostCats.where((c) => c.id == p.cat).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.type == 'need'
                      ? theme.accentSoft
                      : theme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.type == 'need' ? 'NECESITA' : 'OFRECE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: p.type == 'need'
                        ? theme.accentInk
                        : theme.primaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (catObj != null)
                Row(
                  children: [
                    Icon(catObj.icon, size: 16, color: theme.muted),
                    const SizedBox(width: 4),
                    Text(
                      catObj.short ?? catObj.label,
                      style: TextStyle(
                        color: theme.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: theme.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.violetSoft,
                child: Text(
                  p.user.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.violet,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                p.user,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: theme.ink,
                ),
              ),
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: theme.muted,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                '${p.dist} · ${p.time}',
                style: TextStyle(color: theme.muted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => state.helpPost(p.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? theme.primarySoft : theme.primarySoft,
              foregroundColor: theme.primaryDark,
              elevation: 0,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(
              isDone
                  ? Icons.check_circle
                  : (p.type == 'need'
                        ? Icons.volunteer_activism
                        : Icons.front_hand),
              size: 18,
            ),
            label: Text(
              isDone
                  ? 'Le avisamos a ${p.user.split(" ").first}'
                  : (p.type == 'need' ? 'Yo te ayudo' : 'Me interesa'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, NearbyCommunityStyle ui) {
    final style = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: ui.ink,
      height: 1.1,
    );
    final value = int.tryParse(number);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ui.ivory,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            value == null
                ? Text(number, style: style)
                : NearbyCountUp(value: value, style: style),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: ui.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview(ReportItem r, NearbyCommunityStyle ui) {
    final v =
        kVulnCats.where((x) => x.id == r.cat).firstOrNull ?? kVulnCats.first;
    final pending = r.status == 'p';
    // Etiqueta de prioridad: roja si está pendiente, ámbar si ya van en camino.
    final tagBg = pending ? theme.sosSoft : theme.accentSoft;
    final tagInk = pending ? theme.sosDark : theme.accentInk;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: ui.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconSquare(v.icon, NearbyColors.sos, theme.sosSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.who,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ui.ink,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      '${r.where} · ${r.time}',
                      style: TextStyle(color: ui.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pending ? Icons.schedule : Icons.directions_walk,
                      size: 13,
                      color: tagInk,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pending ? 'Pendiente' : 'En camino',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tagInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.detail, style: TextStyle(color: ui.ink, fontSize: 12.5)),
          const SizedBox(height: 12),
          Divider(height: 1, color: ui.line),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                state.goToReport(r);
                state.toast(
                  'Te asignaste el reporte. La brigada lo sabe.',
                  icon: 'directions_run',
                );
              },
              style: ui.action().copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(96, 40)),
              ),
              child: const Text('Voy yo'),
            ),
          ),
        ],
      ),
    );
  }
}
