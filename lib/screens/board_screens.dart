import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

// --- Utilidades de diseño de los tableros ---

/// Margen lateral de página: 24 (16 en anchos muy estrechos).
double _gutter(double width) => width < 360 ? 16 : 24;

/// Columnas para listas de tarjetas: 1 en móvil, 2 desde 700, 3 desde 1050.
int _columns(double width) => width >= 1050 ? 3 : (width >= 700 ? 2 : 1);

/// Encabezado de pantalla: título grande en tinta y subtítulo gris.
Widget _pageHeader(
  NearbyCommunityStyle ui,
  String title,
  String subtitle,
  double gutter,
) => Padding(
  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ui.ink,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(color: ui.muted, fontSize: 14)),
    ],
  ),
);

/// Encabezado de sección (16–17 w700) con un dato opcional a la derecha.
Widget _sectionHeader(
  NearbyCommunityStyle ui,
  String title,
  double gutter, {
  String? trailing,
}) => Padding(
  padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 12),
  child: Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ui.ink,
            letterSpacing: -0.2,
          ),
        ),
      ),
      if (trailing != null)
        Text(trailing, style: TextStyle(color: ui.muted, fontSize: 12.5)),
    ],
  ),
);

/// Cuadrito de ícono (radio 8) de filas y tarjetas.
Widget _iconSquare(
  IconData icon, {
  required Color bg,
  required Color fg,
  double size = 40,
}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(icon, color: fg, size: size * 0.5),
);

/// Tarjeta blanca con borde fino y radio 12.
BoxDecoration _cardBox(NearbyThemeData theme, NearbyCommunityStyle ui) =>
    BoxDecoration(
      color: theme.surface,
      border: Border.all(color: ui.line),
      borderRadius: BorderRadius.circular(12),
    );

/// Etiqueta de radio 8 (texto tinta, fondo suave).
Widget _tag(
  NearbyCommunityStyle ui,
  String label, {
  required Color bg,
  IconData? icon,
  Color? iconColor,
  Color? textColor,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  // Text.rich: el texto largo se parte en líneas sin depender de un Row flexible.
  child: Text.rich(
    TextSpan(
      children: [
        if (icon != null) ...[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(icon, size: 14, color: iconColor ?? ui.ink),
          ),
          const TextSpan(text: ' '),
        ],
        TextSpan(text: label),
      ],
    ),
    style: TextStyle(
      color: textColor ?? ui.ink,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  ),
);

/// Botón a todo el ancho en móvil y de ancho cómodo (máx. 560) en escritorio.
Widget _wideButton(Widget button) => Align(
  alignment: Alignment.centerLeft,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: SizedBox(width: double.infinity, child: button),
  ),
);

/// Estadísticas: un panel marfil compacto en móvil y tres bloques en ancho.
Widget _statsPanel(
  NearbyCommunityStyle ui,
  List<(String, String)> stats, {
  required bool wide,
}) {
  Widget stat((String, String) s, {required bool big}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        s.$1,
        style: TextStyle(
          color: ui.ink,
          fontSize: big ? 26 : 22,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        s.$2,
        style: TextStyle(
          color: ui.muted,
          fontSize: big ? 12 : 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  if (wide) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ui.ivory,
                borderRadius: BorderRadius.circular(12),
              ),
              child: stat(stats[i], big: true),
            ),
          ),
        ],
      ],
    );
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
    decoration: BoxDecoration(
      color: ui.ivory,
      borderRadius: BorderRadius.circular(12),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) Container(width: 1, color: ui.line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: stat(stats[i], big: false),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Pestañas subrayadas (como el muro solidario).
Widget _underlineTabs(
  NearbyCommunityStyle ui,
  List<(String, String)> items,
  String selected,
  ValueChanged<String> onSelect,
) => DecoratedBox(
  decoration: BoxDecoration(
    border: Border(bottom: BorderSide(color: ui.line)),
  ),
  child: Row(
    children: items.map((item) {
      final isSel = item.$1 == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSel,
          child: InkWell(
            onTap: () => onSelect(item.$1),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSel ? ui.accent : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                      color: isSel ? ui.ink : ui.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  ),
);

/// Rejilla de tarjetas con altura natural; en cada fila las tarjetas se igualan.
class _CardGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;

  const _CardGrid({
    required this.children,
    required this.columns,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: child,
            ),
        ],
      );
    }
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += columns) {
      rows.add(
        children.sublist(
          i,
          i + columns > children.length ? children.length : i + columns,
        ),
      );
    }
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(
                      child: j < row.length ? row[j] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// --- Tablero Humanitario ---
class TableroScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const TableroScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final f = state.tabFilter;
    final list = state.reports
        .where((r) => f == 'all' || r.status == f)
        .toList();
    final pendCount = state.reports.where((r) => r.status != 'a').length;

    return LayoutBuilder(
      builder: (context, bounds) {
        final w = bounds.maxWidth;
        final g = _gutter(w);
        return ListView(
          padding:
              NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
          children: [
            _pageHeader(
              ui,
              'Ayuda humanitaria',
              'Reportes geolocalizados de vecinos en situación vulnerable.',
              g,
            ),

            // Estadísticas
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _statsPanel(ui, [
                (
                  '${state.connected ? state.reports.length : state.reports.length + 14}',
                  'Reportes',
                ),
                ('$pendCount', 'Por atender'),
                (
                  state.connected
                      ? '${state.reports.where((r) => r.status == 'a').length}'
                      : '11',
                  'Atendidos',
                ),
              ], wide: w >= 600),
            ),
            const SizedBox(height: 16),

            // Plan de asignación
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _buildAiPanel(context),
            ),
            const SizedBox(height: 16),

            // Filtro por estado
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _underlineTabs(
                ui,
                const [
                  ('all', 'Todos'),
                  ('p', 'Pendientes'),
                  ('c', 'En camino'),
                  ('a', 'Atendidos'),
                ],
                state.tabFilter,
                (id) {
                  state.tabFilter = id;
                  state.refresh();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Lista de reportes
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _CardGrid(
                columns: _columns(w),
                children: list.map((r) => _buildReportCard(r)).toList(),
              ),
            ),

            // Aviso de privacidad
            Padding(
              padding: EdgeInsets.fromLTRB(g, 4, g, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ui.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: ui.ink, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Las direcciones exactas solo son visibles para brigadistas verificados. Los reportes se cierran cuando alguien confirma la atención.',
                        style: TextStyle(
                          color: ui.ink,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reportar vecino vulnerable
            Padding(
              padding: EdgeInsets.fromLTRB(g, 12, g, 0),
              child: _wideButton(
                ElevatedButton.icon(
                  onPressed: () {
                    state.pub.reset(step: 2, type: 'vulnerable');
                    state.go('publicar');
                  },
                  style: ui.action(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Reportar vecino vulnerable'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAiPanel(BuildContext context) {
    if (state.aiStatus != 'done') {
      return _wideButton(
        ElevatedButton.icon(
          onPressed: () => state.runAi(),
          style: ui.action().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          ),
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text('Activar IA: cruzar historial y asignar rescates'),
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
        color: ui.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _iconSquare(Icons.auto_awesome, bg: theme.surface, fg: ui.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan de acción generado en ${state.aiMs.toStringAsFixed(1)} ms',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ui.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalAssigned vecinos asignados · $prevCount vecinos vulnerables detectados sin reporte',
                  style: TextStyle(color: ui.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => state.go('red'),
            style: TextButton.styleFrom(foregroundColor: ui.ink),
            child: const Text(
              'Red',
              style: TextStyle(fontWeight: FontWeight.w700),
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

    // Asignación del plan, si ya se generó
    List<HistoryItem>? missions;
    if (state.aiStatus == 'done' && r.status != 'a') {
      missions =
          state.aiMissions[r.id] ??
          (state.aiMissions[r.id] = state.assignMission(r));
    }
    final notified = state.aiNotified[r.id] == true;

    // La prioridad se lee en el color del cuadrito del ícono.
    final prioSoft = isDone
        ? theme.primarySoft
        : (r.prio == 'alta' ? theme.sosSoft : theme.accentSoft);
    final prioColor = isDone
        ? theme.primaryDark
        : (r.prio == 'alta' ? theme.sos : theme.accentInk);

    final statusSoft = r.status == 'p'
        ? theme.sosSoft
        : (r.status == 'c' ? theme.accentSoft : theme.primarySoft);
    final statusInk = r.status == 'p'
        ? theme.sosDark
        : (r.status == 'c' ? theme.accentInk : theme.primaryDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardBox(theme, ui),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.ai) ...[
            _tag(
              ui,
              'Detectado por IA · nadie lo reportó',
              bg: ui.blueSoft,
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              _iconSquare(v.icon, bg: prioSoft, fg: prioColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.who,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ui.ink,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${r.where} · ${r.time}',
                      style: TextStyle(color: ui.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.detail,
            style: TextStyle(color: ui.ink, fontSize: 13, height: 1.4),
          ),

          // Asignación sugerida
          if (missions != null && missions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ui.blueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: ui.ink, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ASIGNACIÓN IA',
                        style: TextStyle(
                          color: ui.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...missions.map((a) {
                    final tg = kAiTags[a.tag]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(tg.i, size: 18, color: ui.ink),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  color: ui.ink,
                                ),
                                children: [
                                  TextSpan(
                                    text: a.who == state.userName
                                        ? 'Tú'
                                        : a.who,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' · ${tg.l}\n'),
                                  TextSpan(
                                    text: '${a.src} ${a.when}: «${a.txt}»',
                                    style: TextStyle(
                                      color: ui.muted,
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
                  const SizedBox(height: 4),
                  if (notified)
                    _tag(
                      ui,
                      'Notificados · ${missions.map((a) => a.who.split(" ").first).join(" y ")} van en camino',
                      bg: theme.primarySoft,
                      icon: Icons.notifications_active,
                      iconColor: theme.primaryDark,
                      textColor: theme.primaryDark,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => state.notifyAiMission(r.id),
                        style: ui.action().copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size.fromHeight(44),
                          ),
                        ),
                        icon: const Icon(Icons.send, size: 16),
                        label: Text(
                          'Notificar a ${missions.length == 1 ? missions.first.who.split(" ").first : "${missions.length} vecinos"}',
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
              _tag(
                ui,
                isGoing
                    ? 'Vas en camino'
                    : (r.status == 'p'
                          ? 'Pendiente'
                          : (r.status == 'c'
                                ? 'En camino · ${r.by ?? ""}'
                                : 'Atendido')),
                bg: statusSoft,
                icon: r.status == 'p'
                    ? Icons.schedule
                    : (r.status == 'c'
                          ? Icons.directions_walk
                          : Icons.check_circle),
                iconColor: statusInk,
                textColor: statusInk,
              ),

              if (r.status == 'p' && !isGoing)
                ElevatedButton(
                  onPressed: () {
                    state.goToReport(r);
                    state.toast(
                      'Te asignaste el reporte. La brigada lo sabe.',
                      icon: 'directions_run',
                    );
                  },
                  style: ui.action().copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                  child: const Text('Voy yo'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    state.mapFilter = 'vuln';
                    state.mapSel = null;
                    state.go('mapa');
                  },
                  style: ui.action(filled: false),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Mapa'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Recursos Críticos ---
class RecursosScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const RecursosScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final curRes =
        state.resources.where((r) => r.id == state.resSel).firstOrNull ??
        state.resources.first;
    final offers = state.resOffers.where((o) => o.res == curRes.id).toList();

    return LayoutBuilder(
      builder: (context, bounds) {
        final w = bounds.maxWidth;
        final g = _gutter(w);
        return ListView(
          padding:
              NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
          children: [
            _pageHeader(
              ui,
              'Recursos críticos',
              'Economía solidaria: coordina y comparte lo que hay y lo que falta.',
              g,
            ),

            // Recursos: 2 columnas en móvil, 4 en ancho
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _CardGrid(
                columns: w >= 700 ? 4 : 2,
                spacing: 10,
                children: state.resources
                    .map((x) => _resourceTile(x))
                    .toList(),
              ),
            ),

            // Publicaciones del recurso elegido
            _sectionHeader(
              ui,
              curRes.label,
              g,
              trailing: '${offers.length} publicaciones',
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _CardGrid(
                columns: _columns(w),
                children: offers.map((o) => _offerCard(o)).toList(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(g, 4, g, 0),
              child: _wideButton(
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
                        style: ui.action(filled: false),
                        icon: const Icon(Icons.back_hand_outlined, size: 18),
                        label: const Text('Necesito'),
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
                        style: ui.action(),
                        icon: const Icon(
                          Icons.volunteer_activism_outlined,
                          size: 18,
                        ),
                        label: const Text('Ofrezco'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _resourceTile(ResourceItem x) {
    final isSel = x.id == state.resSel;
    final total = x.have + x.need;
    final havePercent = total > 0 ? (x.have / total) : 0.5;

    return Semantics(
      button: true,
      selected: isSel,
      child: Material(
        color: isSel ? ui.ivory : theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSel ? ui.ink : ui.line,
            width: isSel ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            state.resSel = x.id;
            state.refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _iconSquare(x.icon, bg: ui.blueSoft, fg: ui.ink, size: 36),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        x.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ui.ink,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Balance: lo que hay frente a lo que falta
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (havePercent * 100).round(),
                          child: Container(color: theme.primary),
                        ),
                        Expanded(
                          flex: ((1.0 - havePercent) * 100).round(),
                          child: Container(color: theme.sos),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hay ${x.have}',
                      style: TextStyle(
                        color: ui.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Faltan ${x.need}',
                      style: TextStyle(
                        color: ui.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _offerCard(ResOfferItem o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardBox(theme, ui),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tag(
                ui,
                o.type == 'need' ? 'SE NECESITA' : 'DISPONIBLE',
                bg: o.type == 'need' ? ui.ivory : ui.blueSoft,
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Icon(Icons.location_on_outlined, size: 14, color: ui.muted),
              const SizedBox(width: 4),
              Flexible(
                flex: 4,
                child: Text(
                  o.where,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ui.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            o.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ui.ink,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: ui.blueSoft,
                foregroundColor: ui.ink,
                child: Text(
                  o.user.split(' ').map((w) => w[0]).take(2).join(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  o.user,
                  style: TextStyle(color: ui.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Grupos de Apoyo ---
class ApoyoScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const ApoyoScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bounds) {
        final w = bounds.maxWidth;
        final g = _gutter(w);
        return ListView(
          padding:
              NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
          children: [
            _pageHeader(
              ui,
              'Grupos de apoyo',
              'Servicios y grupos activos para situaciones críticas.',
              g,
            ),

            // Grupos
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _CardGrid(
                columns: _columns(w),
                children: state.groups.map((gr) => _groupCard(gr)).toList(),
              ),
            ),

            // Vecinos con oficio disponibles en la emergencia
            _sectionHeader(ui, 'Vecinos con oficio disponibles', g),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: g),
              child: _CardGrid(
                columns: _columns(w),
                spacing: 10,
                children: state.services
                    .where((s) => s.emerg)
                    .map((s) => _serviceRow(s))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _groupCard(GroupItem g) {
    final isJoined = state.joined[g.name] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardBox(theme, ui),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconSquare(g.icon, bg: ui.blueSoft, fg: ui.ink, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ui.ink,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      g.desc,
                      style: TextStyle(color: ui.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tag(
                ui,
                g.live ? 'Activo ahora' : 'Sin actividad ahora',
                bg: ui.ivory,
                icon: g.live ? Icons.radio_button_checked : Icons.schedule,
                iconColor: g.live ? theme.primaryDark : theme.accentInk,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${g.members} vecinos',
                  style: TextStyle(
                    color: ui.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => state.startCall(g.name),
                  style: ui.action(filled: false),
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Contactar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isJoined
                    ? Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: ui.ivory,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.primaryDark,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Ya eres parte',
                                style: TextStyle(
                                  color: ui.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => state.openSheet('join', id: g.name),
                        style: ui.action(),
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text('Unirme'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceRow(ServiceItem s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardBox(theme, ui),
      child: Row(
        children: [
          _iconSquare(s.icon, bg: ui.blueSoft, fg: ui.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ui.ink,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${s.job} · ${s.dist}',
                  style: TextStyle(color: ui.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => state.startCall(s.name),
            style: ui.action(filled: false).copyWith(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }
}
