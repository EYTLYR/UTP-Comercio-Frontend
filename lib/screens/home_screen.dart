import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/common_widgets.dart';

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
    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        // Greeting
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${state.firstName}',
                style: TextStyle(
                  color: theme.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '¿Qué necesitas hoy?',
                style: TextStyle(
                  color: theme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // SOS Card
        NearbySosCard(theme: theme, state: state),

        // Zone emergency banner if zone still in emergency
        if (state.zoneEm)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Section "Día a día"
        _buildSectionHeader('Día a día'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 154 * theme.scaleFactor,
            children: [
              _buildTile(
                icon: Icons.handyman,
                color: theme.primary,
                softColor: theme.primarySoft,
                title: 'Buscar un servicio',
                subtitle: 'Oficios con Visto Bueno',
                onTap: () => state.go('servicios'),
              ),
              _buildTile(
                icon: Icons.back_hand,
                color: theme.accent,
                softColor: theme.accentSoft,
                title: 'Pedir un favor',
                subtitle: 'Sin dinero, entre vecinos',
                onTap: () {
                  state.pub.reset(step: 2, type: 'need');
                  state.go('publicar');
                },
              ),
              _buildTile(
                icon: Icons.volunteer_activism,
                color: theme.info,
                softColor: theme.infoSoft,
                title: 'Ofrecer ayuda',
                subtitle: 'Presta, dona o enseña',
                onTap: () {
                  state.pub.reset(step: 2, type: 'offer');
                  state.go('publicar');
                },
              ),
              _buildTile(
                icon: Icons.map,
                color: theme.violet,
                softColor: theme.violetSoft,
                title: 'Ver el mapa',
                subtitle: 'Lo que hay cerca de ti',
                onTap: () => state.go('mapa'),
              ),
            ],
          ),
        ),

        // AI Summary Banner
        if (state.isBrigade)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                            style: TextStyle(color: theme.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.muted),
                  ],
                ),
              ),
            ),
          ),

        // Recommended Services Horizontal Scroll
        _buildSectionHeader(
          'Recomendados por tus vecinos',
          actionText: 'Ver todos',
          onAction: () => state.go('servicios'),
        ),
        SizedBox(
          height: 154 * theme.scaleFactor,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.services.take(5).length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = state.services[i];
              return InkWell(
                onTap: () {
                  state.selService = s.id;
                  state.go('svc');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 150,
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _toneSoft(s.tone),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          s.icon,
                          color: _toneColor(s.tone),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.ink,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        s.job,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.muted, fontSize: 11.5),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: theme.primaryDark,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${s.vb + (state.vbGiven[s.id] == true ? 1 : 0)}',
                              style: TextStyle(
                                color: theme.primaryDark,
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
              );
            },
          ),
        ),

        // In the wall right now
        _buildSectionHeader(
          'En el muro ahora',
          actionText: 'Ver muro',
          onAction: () => state.go('muro'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: state.posts
                .take(2)
                .map((p) => _buildPostCard(p))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextButton.icon(
            onPressed: () => state.startTour('main'),
            icon: const Icon(Icons.touch_app_outlined),
            label: const Text('Aprende tocando la app (1 minuto)'),
          ),
        ),
      ],
    );
  }

  // --- Emergency Home ---
  Widget _buildEmergencyHome(BuildContext context) {
    final pendingCount = state.reports.where((r) => r.status != 'a').length;

    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        // Greeting
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.firstName}, mantén la calma',
                style: TextStyle(
                  color: theme.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tu barrio se está organizando',
                style: TextStyle(
                  color: theme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // SOS Card
        NearbySosCard(theme: theme, state: state),

        // Check-in card "¿Cómo estás?"
        Container(
          key: state.tourTarget('checkin'),
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.line),
            borderRadius: BorderRadius.circular(18),
            boxShadow: theme.cardShadow,
          ),
          child: state.checkin
              ? Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: theme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marcaste que estás bien',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.ink,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            state.contacts.isEmpty
                                ? 'Avisamos a la brigada de tu zona.'
                                : 'Avisamos a tus ${state.contacts.length} contactos y a la brigada.',
                            style: TextStyle(color: theme.muted, fontSize: 12),
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
                        fontWeight: FontWeight.w900,
                        color: theme.ink,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu respuesta llega a tus contactos y al tablero del barrio.',
                      style: TextStyle(color: theme.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PressableScale(
                            scale: 0.96,
                            onTap: () async {
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
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: NearbyColors.brandTurquoise,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 18, color: NearbyColors.onPrimary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Estoy bien',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: NearbyColors.onPrimary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PressableScale(
                            scale: 0.96,
                            onTap: () => state.go('sos'),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(color: NearbyColors.sos, width: 1.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.emergency, size: 18, color: NearbyColors.sos),
                                  SizedBox(width: 6),
                                  Text(
                                    'Necesito ayuda',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: NearbyColors.sos,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),

        // AI Plan Button / Active summary
        if (state.isBrigade)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: state.aiStatus == 'done'
                ? InkWell(
                    onTap: () => state.go('tablero'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.violet.withValues(alpha: 0.14),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  NearbyColors.violet,
                                  NearbyColors.navy2,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
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
                                  'Plan de rescate con IA activo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: theme.ink,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${state.aiMissions.values.fold(0, (sum, m) => sum + m.length)} vecinos asignados · ver misiones',
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
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      state.go('tablero');
                      state.runAi();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NearbyColors.violet,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 22),
                    label: const Text(
                      'Generar plan de rescate con IA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
          ),

        // Section "Coordinar ayuda" (2x2 grid)
        _buildSectionHeader('Coordinar ayuda'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 154 * theme.scaleFactor,
            children: [
              _buildTile(
                icon: Icons.elderly,
                color: NearbyColors.sos,
                softColor: theme.sosSoft,
                title: 'Reportar vecino',
                subtitle: 'Adultos mayores, heridos…',
                onTap: () {
                  state.pub.reset(step: 2, type: 'vulnerable');
                  state.go('publicar');
                },
              ),
              _buildTile(
                icon: Icons.inventory_2,
                color: theme.accent,
                softColor: theme.accentSoft,
                title: 'Recursos críticos',
                subtitle: 'Agua, víveres, energía',
                onTap: () => state.go('recursos'),
              ),
              _buildTile(
                icon: Icons.diversity_3,
                color: theme.violet,
                softColor: theme.violetSoft,
                title: 'Grupos de apoyo',
                subtitle: 'Brigadas y oficios',
                onTap: () => state.go('apoyo'),
              ),
              _buildTile(
                icon: Icons.flag,
                color: theme.info,
                softColor: theme.infoSoft,
                title: 'Puntos seguros',
                subtitle: 'Reunión y refugios',
                onTap: () {
                  state.mapFilter = 'safe';
                  state.mapSel = null;
                  state.go('mapa');
                },
              ),
            ],
          ),
        ),

        // Section "Tablero del barrio" with stats
        _buildSectionHeader(
          'Tablero del barrio',
          actionText: state.isBrigade ? 'Ver todo' : null,
          onAction: state.isBrigade ? () => state.go('tablero') : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatCard(
                '${state.connected ? state.reports.length : state.reports.length + 14}',
                'Reportes',
              ),
              const SizedBox(width: 8),
              _buildStatCard('$pendingCount', 'Por atender'),
              const SizedBox(width: 8),
              // Sin conteo real de "a salvo": mostramos los atendidos
              _buildStatCard(
                '${state.reports.where((r) => r.status == 'a').length}',
                'Atendidos',
              ),
            ],
          ),
        ),

        // Urgent Reports previews
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: state.reports.where((r) => r.status != 'a').take(2).map((
              r,
            ) {
              return _buildReportPreview(r);
            }).toList(),
          ),
        ),

        // Exit emergency mode banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: InkWell(
            onTap: () => state.openSheet('em-off'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surface,
                border: Border.all(color: theme.line),
                borderRadius: BorderRadius.circular(18),
                boxShadow: theme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.verified_user,
                      color: theme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Ya pasó la emergencia?',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: theme.ink,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Vuelve al modo normal de Nearby',
                          style: TextStyle(color: theme.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helpers ---
  Widget _buildSectionHeader(
    String title, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.ink,
              letterSpacing: -0.2,
            ),
          ),
          if (actionText != null)
            PressableScale(
              onTap: onAction,
              scale: 0.95,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryDark,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: theme.primaryDark),
                  ],
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
  }) {
    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: theme.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: theme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.ink,
                    fontSize: 13.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.muted, fontSize: 11),
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
      margin: const EdgeInsets.only(bottom: 10),
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

  Widget _buildStatCard(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: theme.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: theme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.ink,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: theme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview(ReportItem r) {
    final v =
        kVulnCats.where((x) => x.id == r.cat).firstOrNull ?? kVulnCats.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(left: BorderSide(color: NearbyColors.sos, width: 5)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.sosSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(v.icon, color: NearbyColors.sos, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.who,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.ink,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      '${r.where} · ${r.time}',
                      style: TextStyle(color: theme.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.detail, style: TextStyle(color: theme.ink, fontSize: 12.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: r.status == 'p' ? theme.sosSoft : theme.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      r.status == 'p' ? Icons.schedule : Icons.directions_walk,
                      size: 14,
                      color: r.status == 'p'
                          ? NearbyColors.sosDark
                          : NearbyColors.accentInk,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.status == 'p' ? 'Pendiente' : 'En camino',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: r.status == 'p'
                            ? NearbyColors.sosDark
                            : NearbyColors.accentInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  state.goToReport(r);
                  state.toast(
                    'Te asignaste el reporte. La brigada lo sabe.',
                    icon: 'directions_run',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NearbyColors.sos,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Voy yo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'green':
        return NearbyColors.primary;
      case 'blue':
        return NearbyColors.info;
      case 'amber':
        return NearbyColors.accent;
      case 'red':
        return NearbyColors.sos;
      case 'violet':
        return NearbyColors.violet;
      default:
        return NearbyColors.primary;
    }
  }

  Color _toneSoft(String tone) {
    switch (tone) {
      case 'green':
        return theme.primarySoft;
      case 'blue':
        return theme.infoSoft;
      case 'amber':
        return theme.accentSoft;
      case 'red':
        return theme.sosSoft;
      case 'violet':
        return theme.violetSoft;
      default:
        return theme.primarySoft;
    }
  }
}
