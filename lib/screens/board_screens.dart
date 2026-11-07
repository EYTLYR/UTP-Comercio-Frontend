import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

// --- Tablero Humanitario ---
class TableroScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const TableroScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final f = state.tabFilter;
    final list = state.reports
        .where((r) => f == 'all' || r.status == f)
        .toList();
    final pendCount = state.reports.where((r) => r.status != 'a').length;

    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayuda humanitaria',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reportes geolocalizados de vecinos en situación vulnerable.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
            ],
          ),
        ),

        // 3 Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatCard('${state.reports.length + 14}', 'Reportes'),
              const SizedBox(width: 8),
              _buildStatCard('$pendCount', 'Por atender'),
              const SizedBox(width: 8),
              _buildStatCard('11', 'Atendidos'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // AI Panel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildAiPanel(context),
        ),
        const SizedBox(height: 12),

        // Status Filter Chips
        SizedBox(
          height: 40,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children:
                [
                  ['all', 'Todos'],
                  ['p', 'Pendientes'],
                  ['c', 'En camino'],
                  ['a', 'Atendidos'],
                ].map((entry) {
                  final id = entry[0];
                  final label = entry[1];
                  final isSel = state.tabFilter == id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(label),
                      selected: isSel,
                      onSelected: (_) {
                        state.tabFilter = id;
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: isSel ? theme.btnBg : theme.line,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Reports list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: list.map((r) => _buildReportCard(r)).toList(),
          ),
        ),

        // Privacy notice
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock, color: theme.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Las direcciones exactas solo son visibles para brigadistas verificados. Los reportes se cierran cuando alguien confirma la atención.',
                    style: TextStyle(color: theme.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Button to report vulnerable neighbor
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ElevatedButton.icon(
            onPressed: () {
              state.pub.reset(step: 2, type: 'vulnerable');
              state.go('publicar');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NearbyColors.sos,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Reportar vecino vulnerable',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiPanel(BuildContext context) {
    if (state.aiStatus != 'done') {
      return ElevatedButton.icon(
        onPressed: () => state.runAi(),
        style: ElevatedButton.styleFrom(
          backgroundColor: NearbyColors.violet,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: const Text(
          'Activar IA: cruzar historial y asignar rescates',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      );
    }

    final totalAssigned = state.aiMissions.values.fold(
      0,
      (sum, m) => sum + m.length,
    );
    final prevCount = state.reports.where((r) => r.ai).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.violet.withValues(alpha: 0.14),
            theme.violet.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: theme.violet.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NearbyColors.violet, Color(0xFF8B5CF6)],
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
                  'Plan de acción generado en ${state.aiMs.toStringAsFixed(1)} ms',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: theme.ink,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  '$totalAssigned vecinos asignados · $prevCount vecinos vulnerables detectados sin reporte',
                  style: TextStyle(color: theme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => state.go('red'),
            child: Text(
              'Red',
              style: TextStyle(
                color: theme.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportItem r) {
    final v =
        kVulnCats.where((x) => x.id == r.cat).firstOrNull ?? kVulnCats.first;
    final isDone = r.status == 'a';
    final isGoing = state.going[r.id] == true;

    // AI Assignment box if plan completed
    List<HistoryItem>? missions;
    if (state.aiStatus == 'done' && r.status != 'a') {
      missions =
          state.aiMissions[r.id] ??
          (state.aiMissions[r.id] = state.assignMission(r));
    }
    final notified = state.aiNotified[r.id] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          left: BorderSide(
            color: isDone
                ? theme.primary
                : (r.prio == 'alta' ? NearbyColors.sos : NearbyColors.accent),
            width: 5,
          ),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.ai) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NearbyColors.violet, Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Detectado por IA · nadie lo reportó',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.sosSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(v.icon, color: NearbyColors.sos, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.who,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: theme.ink,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      '${r.where} · ${r.time}',
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.detail,
            style: TextStyle(color: theme.ink, fontSize: 13, height: 1.35),
          ),

          // AI Box if available
          if (missions != null && missions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.violetSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.violet, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ASIGNACIÓN IA',
                        style: TextStyle(
                          color: theme.violet,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...missions.map((a) {
                    final tg = kAiTags[a.tag]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(tg.i, size: 18, color: theme.violet),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12.5,
                                  color: theme.ink,
                                ),
                                children: [
                                  TextSpan(
                                    text: a.who == state.userName
                                        ? 'Tú'
                                        : a.who,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(text: ' · ${tg.l}\n'),
                                  TextSpan(
                                    text: '${a.src} ${a.when}: «${a.txt}»',
                                    style: TextStyle(
                                      color: theme.muted,
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  if (notified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: theme.primaryDark,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Notificados · ${missions.map((a) => a.who.split(" ").first).join(" y ")} van en camino',
                            style: TextStyle(
                              color: theme.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => state.notifyAiMission(r.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NearbyColors.violet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      icon: const Icon(Icons.send, size: 16),
                      label: Text(
                        'Notificar a ${missions.length == 1 ? missions.first.who.split(" ").first : "${missions.length} vecinos"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: r.status == 'p'
                      ? theme.sosSoft
                      : (r.status == 'c'
                            ? theme.accentSoft
                            : theme.primarySoft),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      r.status == 'p'
                          ? Icons.schedule
                          : (r.status == 'c'
                                ? Icons.directions_walk
                                : Icons.check_circle),
                      size: 14,
                      color: r.status == 'p'
                          ? NearbyColors.sosDark
                          : (r.status == 'c'
                                ? NearbyColors.accentInk
                                : theme.primaryDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGoing
                          ? 'Vas en camino'
                          : (r.status == 'p'
                                ? 'Pendiente'
                                : (r.status == 'c'
                                      ? 'En camino · ${r.by ?? ""}'
                                      : 'Atendido')),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: r.status == 'p'
                            ? NearbyColors.sosDark
                            : (r.status == 'c'
                                  ? NearbyColors.accentInk
                                  : theme.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),

              if (r.status == 'p' && !isGoing)
                ElevatedButton(
                  onPressed: () {
                    state.going[r.id] = true;
                    state.refresh();
                    state.toast(
                      'Te asignaste el reporte. La brigada lo sabe.',
                      icon: 'directions_run',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearbyColors.sos,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Voy yo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    state.mapFilter = 'vuln';
                    state.mapSel = null;
                    state.go('mapa');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.ink,
                    side: BorderSide(color: theme.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text(
                    'Mapa',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
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
          borderRadius: BorderRadius.circular(16),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Recursos Críticos ---
class RecursosScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const RecursosScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final curRes =
        kResources.where((r) => r.id == state.resSel).firstOrNull ??
        kResources.first;
    final offers = state.resOffers.where((o) => o.res == curRes.id).toList();

    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recursos críticos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Economía solidaria: coordina y comparte lo que hay y lo que falta.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
            ],
          ),
        ),

        // 2x2 Resource Tiles Grid with Proportions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: kResources.map((x) {
              final isSel = x.id == state.resSel;
              final total = x.have + x.need;
              final havePercent = total > 0 ? (x.have / total) : 0.5;

              return InkWell(
                onTap: () {
                  state.resSel = x.id;
                  state.refresh();
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(
                      color: isSel ? theme.ink : theme.line,
                      width: isSel ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _toneSoft(x.tone),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              x.icon,
                              color: _toneColor(x.tone),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              x.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: theme.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Balance Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (havePercent * 100).round(),
                                child: Container(color: theme.primary),
                              ),
                              Expanded(
                                flex: ((1.0 - havePercent) * 100).round(),
                                child: Container(color: NearbyColors.sos),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hay ${x.have}',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Faltan ${x.need}',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Selected resource offers/needs header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                curRes.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                ),
              ),
              Text(
                '${offers.length} publicaciones',
                style: TextStyle(color: theme.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),

        // Offers and Needs cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ...offers.map((o) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: theme.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: o.type == 'need'
                                  ? theme.accentSoft
                                  : theme.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              o.type == 'need' ? 'SE NECESITA' : 'DISPONIBLE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: o.type == 'need'
                                    ? theme.accentInk
                                    : theme.primaryDark,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: theme.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                o.where,
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        o.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.ink,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: theme.violetSoft,
                            child: Text(
                              o.user.split(' ').map((w) => w[0]).take(2).join(),
                              style: TextStyle(
                                fontSize: 9,
                                color: theme.violet,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            o.user,
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        state.pub.reset(
                          step: 2,
                          type: 'needres',
                          cat: state.resSel,
                        );
                        state.go('publicar');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NearbyColors.sos,
                        side: const BorderSide(
                          color: NearbyColors.sos,
                          width: 1.5,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.back_hand, size: 18),
                      label: const Text(
                        'Necesito',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.pub.reset(
                          step: 2,
                          type: 'offerres',
                          cat: state.resSel,
                        );
                        state.go('publicar');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.btnBg,
                        foregroundColor: theme.btnInk,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.volunteer_activism,
                        color: theme.primary,
                        size: 18,
                      ),
                      label: const Text(
                        'Ofrezco',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

// --- Grupos de Apoyo ---
class ApoyoScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ApoyoScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grupos de apoyo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Servicios y grupos activos para situaciones críticas.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
            ],
          ),
        ),

        // Groups list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: kGroups.map((g) {
              final isJoined = state.joined[g.name] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _toneSoft(g.tone),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            g.icon,
                            color: _toneColor(g.tone),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: theme.ink,
                                  fontSize: 14.5,
                                ),
                              ),
                              Text(
                                g.desc,
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: g.live
                                ? theme.primarySoft
                                : theme.accentSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                g.live
                                    ? Icons.radio_button_checked
                                    : Icons.schedule,
                                size: 12,
                                color: g.live
                                    ? theme.primaryDark
                                    : NearbyColors.accentInk,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                g.live ? 'Activo ahora' : 'Desde las 14:00',
                                style: TextStyle(
                                  color: g.live
                                      ? theme.primaryDark
                                      : NearbyColors.accentInk,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${g.members} vecinos',
                          style: TextStyle(
                            color: theme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => state.startCall(g.name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primarySoft,
                              foregroundColor: theme.primaryDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text(
                              'Contactar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isJoined
                              ? Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: theme.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: theme.primaryDark,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Ya eres parte',
                                          style: TextStyle(
                                            color: theme.primaryDark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () =>
                                      state.openSheet('join', id: g.name),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.ink,
                                    side: BorderSide(color: theme.line),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add, size: 16),
                                  label: const Text(
                                    'Unirme',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Available service workers in emergency
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'Vecinos con oficio disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: state.services.where((s) => s.emerg).map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.line),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _toneSoft(s.tone),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(s.icon, color: _toneColor(s.tone), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: theme.ink,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${s.job} · ${s.dist}',
                            style: TextStyle(color: theme.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => state.startCall(s.name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.btnBg,
                        foregroundColor: theme.btnInk,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Llamar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
