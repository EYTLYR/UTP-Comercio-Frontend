import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/map_view.dart';

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
    final inv = widget.state.buildInventory();
    final resCount = inv.where((e) => kAiTags[e.tag]?.kind == 'res').length;
    final skillCount = inv.where((e) => kAiTags[e.tag]?.kind == 'skill').length;
    final vulnCount = inv.where((e) => kAiTags[e.tag]?.kind == 'vuln').length;

    final filteredList = inv.where((e) {
      if (widget.state.redFilter == 'all') return true;
      return kAiTags[e.tag]?.kind == widget.state.redFilter;
    }).toList();

    return SingleChildScrollView(
      padding: NavigationInsets.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.violet.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.violet.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: theme.violet),
                      const SizedBox(width: 4),
                      Text(
                        'IA Nearby · Protocolo Lázaro',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.violet,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu barrio ya está preparado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'La IA aprende de la solidaridad de cada día: quién presta una escalera, quién sabe primeros auxilios o dónde vive alguien que necesitará ayuda. Así, cuando llega un desastre, no hay que llenar formularios.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    theme: theme,
                    value: '$resCount',
                    label: 'Recursos de rescate',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    theme: theme,
                    value: '$skillCount',
                    label: 'Habilidades útiles',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    theme: theme,
                    value: '$vulnCount',
                    label: 'Alertas preventivas',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _ChipOption(
                  theme: theme,
                  id: 'all',
                  label: 'Todo',
                  icon: Icons.layers,
                  isSelected: widget.state.redFilter == 'all',
                  onTap: () {
                    widget.state.redFilter = 'all';
                    widget.state.refresh();
                  },
                ),
                _ChipOption(
                  theme: theme,
                  id: 'res',
                  label: 'Recursos',
                  icon: Icons.construction,
                  isSelected: widget.state.redFilter == 'res',
                  onTap: () => setState(() => widget.state.redFilter = 'res'),
                ),
                _ChipOption(
                  theme: theme,
                  id: 'skill',
                  label: 'Habilidades',
                  icon: Icons.medical_services,
                  isSelected: widget.state.redFilter == 'skill',
                  onTap: () => setState(() => widget.state.redFilter = 'skill'),
                ),
                _ChipOption(
                  theme: theme,
                  id: 'vuln',
                  label: 'Preventivas',
                  icon: Icons.elderly,
                  isSelected: widget.state.redFilter == 'vuln',
                  onTap: () => setState(() => widget.state.redFilter = 'vuln'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List of cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = filteredList[index];
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

              Color iconColor = theme.violet;
              Color iconBg = theme.violet.withValues(alpha: 0.12);
              if (tag.tone == 'sos') {
                iconColor = NearbyColors.sos;
                iconBg = NearbyColors.sos.withValues(alpha: 0.12);
              } else if (tag.tone == 'acc') {
                iconColor = NearbyColors.accent;
                iconBg = NearbyColors.accent.withValues(alpha: 0.12);
              }

              return Card(
                color: theme.surface,
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(tag.i, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.violet.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: theme.violet,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tag.l,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme.violet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isVuln ? 'Vecino de ${item.zona}' : item.who,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isVuln)
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: NearbyColors.muted,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Detalle visible solo para brigadistas',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Aprendido del ${item.src.toLowerCase()} · ${item.when} · ${item.zona}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.muted,
                                ),
                              ),
                            if (!isVuln && item.txt.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: NearbyColors.muted.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '«${item.txt}»',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: theme.ink,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NearbyColors.muted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.line),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 20,
                    color: NearbyColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Solo con consentimiento. Cada vecino ve en su perfil lo que la IA aprendió de él y puede borrarlo. Los datos de personas vulnerables solo los ven brigadistas verificados.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.muted,
                        height: 1.3,
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
  }
}

class _StatCard extends StatelessWidget {
  final NearbyThemeData theme;
  final String value;
  final String label;
  const _StatCard({
    required this.theme,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.line),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.violet,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: theme.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final NearbyThemeData theme;
  final String id;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.theme,
    required this.id,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.btnBg : theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? theme.btnBg : theme.line),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? theme.btnInk : theme.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? theme.btnInk : theme.ink,
                ),
              ),
            ],
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
    final live = widget.state.connected;
    final code = _codeController.text;
    final hasCode = code.trim().isNotEmpty;
    final decompressed = decompressSOS(code);
    final isDecoded = widget.state.decoded;
    final gpsLat = decompressed?['lat'] as double?;
    final gpsLng = decompressed?['lng'] as double?;

    return SingleChildScrollView(
      padding: NavigationInsets.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NearbyColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NearbyColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cell_tower,
                        size: 14,
                        color: NearbyColors.accent,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Sin internet · solo SMS y sonido',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NearbyColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mensaje entrante',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'El teléfono del brigadista recibe el código y la IA lo descomprime en el mismo teléfono.',
                  style: TextStyle(fontSize: 13, color: NearbyColors.muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // SMS Bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NearbyColors.muted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NearbyColors.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live
                            ? 'Código SOS recibido'
                            : 'SMS · +51 987 *** 321 · ${widget.state.nowTime()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NearbyColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasCode
                            ? code
                            : 'Aún no recibiste ningún código. Pega abajo el SMS que te llegó.',
                        style: hasCode
                            ? const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: NearbyColors.sos,
                                letterSpacing: 1.1,
                              )
                            : const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: NearbyColors.muted,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NearbyColors.ai,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'Descomprimir con IA',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      setState(() {
                        widget.state.decoded = true;
                      });
                    },
                  )
                else if (decompressed != null) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: NearbyColors.muted.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: NearbyColors.ai,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Reporte descomprimido',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: NearbyColors.ai,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Details grid
                          _DecodedRow(
                            label: 'Tipo',
                            value:
                                '${decompressed['type']}${decompressed['injured'] != null && (decompressed['injured'] as int) > 0 ? " · ${decompressed['injured']} persona${(decompressed['injured'] as int) > 1 ? "s" : ""}" : ""}',
                          ),
                          _DecodedRow(
                            label: 'Lugar',
                            value: decompressed['where'] ?? '',
                          ),
                          _DecodedRow(
                            label: 'Prioridad',
                            value: decompressed['prio'] ?? '',
                            valueColor: decompressed['prio'] == 'Alta'
                                ? NearbyColors.sos
                                : NearbyColors.accent,
                          ),
                          const _DecodedRow(
                            label: 'Canal',
                            value: 'SMS, sin internet',
                          ),
                          // Mini mapa ilustrativo solo en la demo; con sesión
                          // se usa "Ver en el mapa" con el GPS real del código.
                          if (!live) ...[
                          const SizedBox(height: 14),
                          // Mini map container
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: NearbyColors.sos,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.directions_run),
                                  label: const Text(
                                    'Ir ahora',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_location),
                                  label: const Text(
                                    'Al tablero',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.map),
                                label: const Text(
                                  'Ver en el mapa (funciona sin internet)',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => widget.state.openSmsMap(
                                  decompressed['lat'] as double,
                                  decompressed['lng'] as double,
                                  title:
                                      '${decompressed['type']} · ${decompressed['where']}',
                                  sub: 'Prioridad ${decompressed['prio']}',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NearbyColors.sos.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: NearbyColors.sos),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Código no válido. Revisa el formato.',
                            style: TextStyle(
                              color: NearbyColors.sos,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                // Input to test other code
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Probar otro código',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codeController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: NearbyColors.muted.withValues(alpha: 0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: NearbyColors.muted.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.key),
                          label: const Text(
                            'Descomprimir este código',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            setState(() {
                              widget.state.lastCode = _codeController.text;
                              widget.state.decoded = true;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Formato: NB#SOS!{tipo}{personas}@{lugar}\$P:{prioridad}[#G:lat,lng]. Ej. NB#SOS!A2@MC12\$P:ALTA#G:-11.97900,-77.00300. También puedes pegar el SMS completo.',
                          style: TextStyle(
                            fontSize: 10,
                            color: NearbyColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecodedRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DecodedRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: NearbyColors.muted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
