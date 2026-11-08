import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/map_view.dart';

// --- Utilidades de diseño ---

/// Margen lateral de página: 24 (16 en anchos muy estrechos).
double _gutter(double width) => width < 360 ? 16 : 24;

/// Columnas para listas de tarjetas: 1 en móvil, 2 desde 700, 3 desde 1050.
int _columns(double width) => width >= 1050 ? 3 : (width >= 700 ? 2 : 1);

/// Contenido a ancho de lectura (máx. 640), alineado a la izquierda como Inicio.
Widget _readable(Widget child, {double maxWidth = 640}) => Align(
  alignment: Alignment.topLeft,
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: SizedBox(width: double.infinity, child: child),
  ),
);

/// Cuadrito de ícono (radio 8).
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

/// Etiqueta pequeña de radio 8 con ícono.
Widget _badge(
  IconData icon,
  String label, {
  required Color bg,
  required Color fg,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(icon, size: 14, color: fg),
        ),
        const TextSpan(text: ' '),
        TextSpan(text: label),
      ],
    ),
    style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w600),
  ),
);

/// Encabezado de pantalla: etiqueta, título grande y descripción.
Widget _header(
  NearbyCommunityStyle ui, {
  required Widget badge,
  required String title,
  required String subtitle,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    badge,
    const SizedBox(height: 12),
    Text(
      title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ui.ink,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    ),
    const SizedBox(height: 6),
    Text(
      subtitle,
      style: TextStyle(fontSize: 14, color: ui.muted, height: 1.45),
    ),
  ],
);

/// Rejilla de tarjetas con altura natural; en cada fila las tarjetas se igualan.
class _CardGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  static const double spacing = 12;

  const _CardGrid({required this.children, required this.columns});

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : spacing),
              child: children[i],
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
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : spacing),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(
                      child: j < rows[r].length
                          ? rows[r][j]
                          : const SizedBox(),
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

class RedScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData? theme;
  const RedScreen({super.key, required this.state, this.theme});

  @override
  State<RedScreen> createState() => _RedScreenState();
}

class _RedScreenState extends State<RedScreen> {
  @override
  Widget build(BuildContext context) {
    final theme =
        widget.theme ??
        NearbyThemeData.build(
          dark: widget.state.dark,
          lg: widget.state.lg,
          hc: widget.state.hc,
          emergency: widget.state.emergency,
        );
    final ui = NearbyCommunityStyle(theme);
    final inv = widget.state.buildInventory();
    final resCount = inv.where((e) => kAiTags[e.tag]?.kind == 'res').length;
    final skillCount = inv.where((e) => kAiTags[e.tag]?.kind == 'skill').length;
    final vulnCount = inv.where((e) => kAiTags[e.tag]?.kind == 'vuln').length;

    final filteredList = inv.where((e) {
      if (widget.state.redFilter == 'all') return true;
      return kAiTags[e.tag]?.kind == widget.state.redFilter;
    }).toList();

    return LayoutBuilder(
      builder: (context, bounds) {
        final w = bounds.maxWidth;
        final g = _gutter(w);
        final showTabIcons = w >= 480;
        return SingleChildScrollView(
          padding: NavigationInsets.of(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(g, 12, g, 16),
                child: _header(
                  ui,
                  badge: _badge(
                    Icons.auto_awesome,
                    'IA Nearby · Protocolo Lázaro',
                    bg: ui.blueSoft,
                    fg: ui.ink,
                  ),
                  title: 'Tu barrio ya está preparado',
                  subtitle:
                      'La IA aprende de la solidaridad de cada día: quién presta una escalera, quién sabe primeros auxilios o dónde vive alguien que necesitará ayuda. Así, cuando llega un desastre, no hay que llenar formularios.',
                ),
              ),
              // Resumen
              Padding(
                padding: EdgeInsets.symmetric(horizontal: g),
                child: _StatsPanel(
                  ui: ui,
                  wide: w >= 600,
                  stats: [
                    ('$resCount', 'Recursos de rescate'),
                    ('$skillCount', 'Habilidades útiles'),
                    ('$vulnCount', 'Alertas preventivas'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Filtros como pestañas subrayadas
              Padding(
                padding: EdgeInsets.symmetric(horizontal: g),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: ui.line)),
                  ),
                  child: Row(
                    children: [
                      _ChipOption(
                        ui: ui,
                        id: 'all',
                        label: 'Todo',
                        icon: Icons.layers_outlined,
                        showIcon: showTabIcons,
                        isSelected: widget.state.redFilter == 'all',
                        onTap: () {
                          widget.state.redFilter = 'all';
                          widget.state.refresh();
                        },
                      ),
                      _ChipOption(
                        ui: ui,
                        id: 'res',
                        label: 'Recursos',
                        icon: Icons.construction,
                        showIcon: showTabIcons,
                        isSelected: widget.state.redFilter == 'res',
                        onTap: () =>
                            setState(() => widget.state.redFilter = 'res'),
                      ),
                      _ChipOption(
                        ui: ui,
                        id: 'skill',
                        label: 'Habilidades',
                        icon: Icons.medical_services_outlined,
                        showIcon: showTabIcons,
                        isSelected: widget.state.redFilter == 'skill',
                        onTap: () =>
                            setState(() => widget.state.redFilter = 'skill'),
                      ),
                      _ChipOption(
                        ui: ui,
                        id: 'vuln',
                        label: 'Preventivas',
                        icon: Icons.elderly,
                        showIcon: showTabIcons,
                        isSelected: widget.state.redFilter == 'vuln',
                        onTap: () =>
                            setState(() => widget.state.redFilter = 'vuln'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tarjetas: 1, 2 o 3 columnas según el ancho
              Padding(
                padding: EdgeInsets.symmetric(horizontal: g),
                child: _CardGrid(
                  columns: _columns(w),
                  children: filteredList
                      .map((item) => _inventoryCard(theme, ui, item))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: g),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ui.blueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: ui.ink,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Solo con consentimiento. Cada vecino ve en su perfil lo que la IA aprendió de él y puede borrarlo. Los datos de personas vulnerables solo los ven brigadistas verificados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: ui.ink,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _inventoryCard(
    NearbyThemeData theme,
    NearbyCommunityStyle ui,
    HistoryItem item,
  ) {
    final tag =
        kAiTags[item.tag] ??
        AiTag(
          l: item.tag ?? 'Recurso',
          i: Icons.auto_awesome,
          tone: 'ai',
          kind: 'res',
          kw: const [],
        );
    final isVuln = tag.kind == 'vuln';

    // El tono solo cambia en avisos sensibles (rojo) o de atención (ámbar).
    Color iconColor = ui.ink;
    Color iconBg = ui.blueSoft;
    if (tag.tone == 'sos') {
      iconColor = theme.sos;
      iconBg = theme.sosSoft;
    } else if (tag.tone == 'acc') {
      iconColor = theme.accentInk;
      iconBg = theme.accentSoft;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ui.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconSquare(tag.i, bg: iconBg, fg: iconColor, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(Icons.auto_awesome, tag.l, bg: ui.ivory, fg: ui.ink),
                const SizedBox(height: 8),
                Text(
                  isVuln ? 'Vecino de ${item.zona}' : item.who,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ui.ink,
                  ),
                ),
                const SizedBox(height: 2),
                if (isVuln)
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: ui.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Detalle visible solo para brigadistas',
                          style: TextStyle(fontSize: 11.5, color: ui.muted),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Aprendido del ${item.src.toLowerCase()} · ${item.when} · ${item.zona}',
                    style: TextStyle(fontSize: 11.5, color: ui.muted),
                  ),
                if (!isVuln && item.txt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ui.ivory,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '«${item.txt}»',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ui.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen en marfil: panel compacto en móvil, tres bloques en ancho.
class _StatsPanel extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final List<(String, String)> stats;
  final bool wide;

  const _StatsPanel({
    required this.ui,
    required this.stats,
    required this.wide,
  });

  Widget _stat((String, String) s, {required bool big}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        s.$1,
        style: TextStyle(
          fontSize: big ? 26 : 22,
          fontWeight: FontWeight.w700,
          color: ui.ink,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        s.$2,
        style: TextStyle(
          fontSize: big ? 12 : 11,
          color: ui.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
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
                child: _stat(stats[i], big: true),
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
                  child: _stat(stats[i], big: false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pestaña subrayada del filtro de la red de rescate.
class _ChipOption extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String id;
  final String label;
  final IconData icon;
  final bool showIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.ui,
    required this.id,
    required this.label,
    required this.icon,
    required this.showIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? ui.ink : ui.muted;
    return Expanded(
      child: Semantics(
        key: ValueKey('red-filter-$id'),
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? ui.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon) ...[
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================================= */
/*                          MODO BRIGADISTA (PUENTE)                         */
/* ========================================================================= */

class PuenteScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData? theme;
  const PuenteScreen({super.key, required this.state, this.theme});

  @override
  State<PuenteScreen> createState() => _PuenteScreenState();
}

class _PuenteScreenState extends State<PuenteScreen> {
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: (widget.state.lastCode != null && widget.state.lastCode!.isNotEmpty)
          ? widget.state.lastCode!
          // Con sesión no hay código de ejemplo: se espera uno real.
          : (widget.state.connected ? '' : 'NB#SOS!H1@LP340\$P:ALTA'),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        widget.theme ??
        NearbyThemeData.build(
          dark: widget.state.dark,
          lg: widget.state.lg,
          hc: widget.state.hc,
          emergency: widget.state.emergency,
        );
    final ui = NearbyCommunityStyle(theme);
    final live = widget.state.connected;
    final code = _codeController.text;
    final hasCode = code.trim().isNotEmpty;
    final decompressed = decompressSOS(code);
    final isDecoded = widget.state.decoded;
    final gpsLat = decompressed?['lat'] as double?;
    final gpsLng = decompressed?['lng'] as double?;

    final card = BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ui.line),
    );

    return LayoutBuilder(
      builder: (context, bounds) {
        final g = _gutter(bounds.maxWidth);
        return SingleChildScrollView(
          padding: NavigationInsets.of(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(g, 12, g, 24),
            child: _readable(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(
                    ui,
                    badge: Align(
                      alignment: Alignment.centerLeft,
                      child: _badge(
                        Icons.cell_tower,
                        'Sin internet · solo SMS y sonido',
                        bg: theme.accentSoft,
                        fg: theme.accentInk,
                      ),
                    ),
                    title: 'Mensaje entrante',
                    subtitle:
                        'El teléfono del brigadista recibe el código y la IA lo descomprime en el mismo teléfono.',
                  ),
                  const SizedBox(height: 20),

                  // Mensaje recibido
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ui.ivory,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          live
                              ? 'Código SOS recibido'
                              : 'SMS · +51 987 *** 321 · ${widget.state.nowTime()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ui.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasCode
                              ? code
                              : 'Aún no recibiste ningún código. Pega abajo el SMS que te llegó.',
                          style: hasCode
                              ? TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.sos,
                                  letterSpacing: 1.1,
                                )
                              : TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: ui.muted,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sin código no hay nada que descomprimir
                  if (!hasCode)
                    const SizedBox.shrink()
                  else if (!isDecoded)
                    ElevatedButton.icon(
                      style: ui.action(),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Descomprimir con IA'),
                      onPressed: () {
                        setState(() {
                          widget.state.decoded = true;
                        });
                      },
                    )
                  else if (decompressed != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _iconSquare(
                                Icons.auto_awesome,
                                bg: ui.blueSoft,
                                fg: ui.ink,
                                size: 32,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Reporte descomprimido',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ui.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Detalle
                          _DecodedRow(
                            ui: ui,
                            label: 'Tipo',
                            value:
                                '${decompressed['type']}${decompressed['injured'] != null && (decompressed['injured'] as int) > 0 ? " · ${decompressed['injured']} persona${(decompressed['injured'] as int) > 1 ? "s" : ""}" : ""}',
                          ),
                          Divider(height: 1, color: ui.line),
                          _DecodedRow(
                            ui: ui,
                            label: 'Lugar',
                            value: decompressed['where'] ?? '',
                          ),
                          Divider(height: 1, color: ui.line),
                          _DecodedRow(
                            ui: ui,
                            label: 'Prioridad',
                            value: decompressed['prio'] ?? '',
                            valueColor: decompressed['prio'] == 'Alta'
                                ? theme.sos
                                : theme.accentInk,
                          ),
                          Divider(height: 1, color: ui.line),
                          _DecodedRow(
                            ui: ui,
                            label: 'Canal',
                            value: 'SMS, sin internet',
                          ),
                          // Mini mapa ilustrativo solo en la demo; con sesión
                          // se usa "Ver en el mapa" con el GPS real del código.
                          if (!live) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: NearbyMapView(
                                  theme:
                                      widget.theme ??
                                      NearbyThemeData.build(
                                        dark: false,
                                        lg: false,
                                        hc: false,
                                        emergency: true,
                                      ),
                                  emergency: true,
                                  pins: const [
                                    MapPin(
                                      id: 'mini-vuln',
                                      kind: 'vuln',
                                      title: 'Emergencia',
                                      sub: 'Reporte recibido por SMS',
                                      x: 66,
                                      y: 58,
                                      icon: Icons.emergency,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ui.action(),
                                  icon: const Icon(
                                    Icons.directions_run,
                                    size: 18,
                                  ),
                                  label: const Text('Ir ahora'),
                                  onPressed: () {
                                    widget.state.routeTo = {
                                      'title':
                                          decompressed['where'] ??
                                          (live
                                              ? 'Lugar del reporte'
                                              : 'Jr. Los Pinos 340'),
                                      'sub':
                                          '${decompressed['type']} · prioridad ${decompressed['prio']}',
                                      // GPS del SMS (#G:lat,lng) si vino
                                      if (gpsLat != null && gpsLng != null) ...{
                                        'lat': gpsLat,
                                        'lng': gpsLng,
                                      },
                                      'icon': Icons.emergency,
                                      'kind': 'help',
                                    };
                                    widget.state.emergency = true;
                                    widget.state.zoneEm = true;
                                    widget.state.go('ruta');
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: ui.action(filled: false),
                                  icon: const Icon(
                                    Icons.add_location_alt_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Al tablero'),
                                  onPressed: () {
                                    widget.state.addReportFromPuente(
                                      decompressed,
                                      code: code,
                                    );
                                    widget.state.go('tablero', reset: true);
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (decompressed['lat'] is double &&
                              decompressed['lng'] is double) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: ui.action(filled: false),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text(
                                'Ver en el mapa (funciona sin internet)',
                              ),
                              onPressed: () => widget.state.openSmsMap(
                                decompressed['lat'] as double,
                                decompressed['lng'] as double,
                                title:
                                    '${decompressed['type']} · ${decompressed['where']}',
                                sub: 'Prioridad ${decompressed['prio']}',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.sosSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.sosDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Código no válido. Revisa el formato.',
                              style: TextStyle(
                                color: theme.sosDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Probar otro código
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Probar otro código',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ui.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeController,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: ui.ink,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: ui.ivory,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: ui.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: ui.ink, width: 1.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: ui.line),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: ui.action(filled: false),
                          icon: const Icon(Icons.key_outlined, size: 18),
                          label: const Text('Descomprimir este código'),
                          onPressed: () {
                            setState(() {
                              widget.state.lastCode = _codeController.text;
                              widget.state.decoded = true;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Formato: NB#SOS!{tipo}{personas}@{lugar}\$P:{prioridad}[#G:lat,lng]. Ej. NB#SOS!A2@MC12\$P:ALTA#G:-11.97900,-77.00300. También puedes pegar el SMS completo.',
                          style: TextStyle(
                            fontSize: 11,
                            color: ui.muted,
                            height: 1.4,
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
    );
  }
}

class _DecodedRow extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String label;
  final String value;
  final Color? valueColor;

  const _DecodedRow({
    required this.ui,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: ui.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ui.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
