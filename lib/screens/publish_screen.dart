import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

class PublishScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const PublishScreen({super.key, required this.state, required this.theme});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.state.pub.text);
    if (widget.state.connected) widget.state.locateForPublish();
  }

  @override
  void didUpdateWidget(covariant PublishScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_textController.text != widget.state.pub.text) {
      _textController.text = widget.state.pub.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;

    return Column(
      children: [
        // 3 Steps progress header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: ['Tipo', 'Detalle', 'Listo'].asMap().entries.map((entry) {
              final idx = entry.key;
              final label = entry.value;
              final isOn = p.step >= (idx + 1);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: isOn
                              ? (state.emergency
                                    ? NearbyColors.sos
                                    : theme.primary)
                              : theme.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${idx + 1}. $label',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isOn ? theme.ink : theme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Step Content
        Expanded(
          child: p.step == 1
              ? _buildStep1(context)
              : (p.step == 2 ? _buildStep2(context) : _buildStep3(context)),
        ),

        // Footer in Step 2
        if (p.step == 2)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border(top: BorderSide(color: theme.line)),
            ),
            child: Column(
              children: [
                ElevatedButton.icon(
                  key: state.tourTarget('publish-submit'),
                  onPressed: p.cat != null
                      ? () {
                          p.text = _textController.text;
                          state.finishPublish();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.emergency
                        ? NearbyColors.sos
                        : theme.btnBg,
                    foregroundColor: state.emergency
                        ? Colors.white
                        : theme.btnInk,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(
                    _getSubmitLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.cat != null
                      ? 'Último toque'
                      : 'Elige una opción para continuar',
                  style: TextStyle(color: theme.muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final types = state.emergency ? kEmTypes : kTypes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          '¿Qué quieres ${state.emergency ? "reportar" : "publicar"}?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: theme.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Solo 3 toques: tipo, categoría y listo.',
          style: TextStyle(color: theme.muted, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // AI Voice CTA
        InkWell(
          onTap: () => state.openSheet('voice'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NearbyColors.violet, NearbyColors.navy2],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: NearbyColors.violet.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dilo con tu voz',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'La IA marca el tipo, la categoría y la ubicación por ti',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'o elige tú mismo',
            style: TextStyle(color: theme.muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Type cards
        ...types.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              key: t.id == 'need' ? state.tourTarget('publish-type') : null,
              onTap: () {
                state.pub.type = t.id;
                state.pub.cat = null;
                state.pub.step = 2;
                state.refresh();
                state.checkTourEvent('ptype');
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.line),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: theme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _toneSoft(t.tone),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(t.icon, color: _toneColor(t.tone), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: theme.ink,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.desc,
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 12.5,
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
          );
        }),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;
    final all = [...kTypes, ...kEmTypes];
    final curType = all.where((t) => t.id == p.type).firstOrNull ?? all.first;
    final categories = _getCategoriesForType(p.type);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Selected pill type with "Cambiar"
        Row(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
              decoration: BoxDecoration(
                color: theme.surface,
                border: Border.all(color: theme.line),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(curType.icon, color: _toneColor(curType.tone), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    curType.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.ink,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      p.step = 1;
                      state.refresh();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Cambiar',
                        style: TextStyle(
                          color: theme.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Text(
          curType.q,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: theme.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // AI Detection label if exists
        if (p.ai != null && p.ai!['label'] != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.violet.withValues(alpha: 0.14),
                  theme.violet.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: theme.violet.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.violet, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: theme.ink,
                      ),
                      children: [
                        TextSpan(
                          text: 'IA detectó: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: theme.violet,
                          ),
                        ),
                        TextSpan(text: '${p.ai!["label"]}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Category grid (2 columns)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 118 * theme.scaleFactor,
          children: categories.map((c) {
            final isSel = p.cat == c.id;
            return InkWell(
              key: c.id == 'herramientas'
                  ? state.tourTarget('publish-category')
                  : null,
              onTap: () {
                p.cat = c.id;
                state.refresh();
                state.checkTourEvent('pcat');
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSel
                      ? (state.emergency ? theme.sosSoft : theme.primarySoft)
                      : theme.surface,
                  border: Border.all(
                    color: isSel
                        ? (state.emergency ? NearbyColors.sos : theme.primary)
                        : theme.line,
                    width: isSel ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSel
                            ? (state.emergency
                                  ? NearbyColors.sos
                                  : theme.primary)
                            : theme.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        c.icon,
                        color: isSel ? Colors.white : theme.ink,
                        size: 20,
                      ),
                    ),
                    Text(
                      c.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: theme.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Detail field
        Text(
          'Detalle (opcional)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.ink,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.line),
            borderRadius: BorderRadius.circular(18),
            boxShadow: theme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: theme.ink,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: curType.ph,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => p.text = val,
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () => state.openSheet('voice'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.mic, color: theme.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => state.openSheet('photo'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_camera,
                        color: theme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Photo attached tag if true
        if (p.photo) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                decoration: BoxDecoration(
                  color: theme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, color: theme.primaryDark, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Foto adjunta',
                      style: TextStyle(
                        color: theme.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        p.photo = false;
                        state.refresh();
                      },
                      child: Icon(
                        Icons.close,
                        color: theme.primaryDark,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        // Location row
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.my_location, color: theme.info, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: theme.muted,
                  ),
                  children: [
                    TextSpan(
                      text: p.ai?['loc'] == null && widget.state.pubLocating
                          ? 'Buscando dónde estás…'
                          : widget.state.publishWhere,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.ink,
                      ),
                    ),
                    if (!widget.state.pubLocating || p.ai?['loc'] != null)
                      TextSpan(
                        text: p.ai?['loc'] != null
                            ? ' · ubicación detectada por la IA'
                            : widget.state.pubFromGps
                            ? ' · tu ubicación actual'
                            : ' · tu dirección guardada',
                      ),
                  ],
                ),
              ),
            ),
            if (widget.state.connected && p.ai?['loc'] == null)
              IconButton(
                tooltip: 'Actualizar mi ubicación',
                visualDensity: VisualDensity.compact,
                onPressed: widget.state.pubLocating
                    ? null
                    : widget.state.locateForPublish,
                icon: widget.state.pubLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: theme.info, size: 20),
              ),
          ],
        ),

        if (p.type == 'vulnerable') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(14),
              boxShadow: theme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock, color: theme.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solo brigadistas verificados ven la dirección exacta. Los demás vecinos ven la zona aproximada.',
                    style: TextStyle(color: theme.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;
    final off = state.offline;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: off
                  ? theme.accentSoft
                  : (state.emergency ? theme.sosSoft : theme.primarySoft),
              shape: BoxShape.circle,
            ),
            child: Icon(
              off ? Icons.cloud_sync : Icons.check_circle,
              color: off
                  ? NearbyColors.accent
                  : (state.emergency ? NearbyColors.sos : theme.primary),
              size: 54,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          off
              ? 'Guardado en tu teléfono'
              : (p.type == 'vulnerable' ? 'Reporte enviado' : '¡Publicado!'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          off
              ? (p.type == 'vulnerable'
                    ? 'Sin internet: la IA comprimió tu reporte y lo envió por SMS a la brigada. Se publicará completo cuando vuelva la señal.'
                    : 'No hay conexión. Se publicará automáticamente cuando vuelva la señal.')
              : (p.type == 'vulnerable'
                    ? 'La brigada y los vecinos cercanos ya lo ven en el tablero de ayuda humanitaria.'
                    : 'Tus vecinos en 500 m ya lo pueden ver y responder.'),
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.muted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),

        if (off && p.type == 'vulnerable' && state.lastCode != null) ...[
          _buildCompressedCodeCard(state.lastCode!),
          const SizedBox(height: 16),
        ],

        ElevatedButton(
          onPressed: () {
            if (p.type == 'vulnerable') {
              state.go(state.isBrigade ? 'tablero' : 'home', reset: true);
            } else if (p.type == 'service') {
              state.go('servicios', reset: true);
            } else if (state.emergency) {
              state.go('recursos', reset: true);
            } else {
              state.go('muro', reset: true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: state.emergency ? NearbyColors.sos : theme.btnBg,
            foregroundColor: state.emergency ? Colors.white : theme.btnInk,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            p.type == 'vulnerable'
                ? 'Ver tablero'
                : (p.type == 'service'
                      ? 'Ver servicios'
                      : (state.emergency ? 'Ver recursos' : 'Ver en el muro')),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: state.tourTarget('publish-home'),
          onPressed: () => state.selectTab('home'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.ink,
            side: BorderSide(color: theme.line),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.home, size: 18),
          label: const Text(
            'Volver al inicio',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildCompressedCodeCard(String code) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        border: Border.all(color: widget.theme.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.theme.violet, size: 18),
              const SizedBox(width: 6),
              Text(
                'Comprimido por IA para SMS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: widget.theme.violet,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF041128),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
                color: Color(0xFF6FE6D6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${code.length} de 25 caracteres',
                style: TextStyle(
                  color: widget.theme.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Cabe en 1 SMS',
                style: TextStyle(
                  color: widget.theme.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.state.openSheet('sonic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearbyColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.graphic_eq, size: 16),
                  label: const Text(
                    'Enviar por sonido',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.state.decoded = false;
                    widget.state.lastCode = code;
                    widget.state.go('puente');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.theme.ink,
                    side: BorderSide(color: widget.theme.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    'Ver brigadista',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<CategoryItem> _getCategoriesForType(String? type) {
    if (type == 'need' || type == 'offer') return kPostCats;
    if (type == 'service') {
      return kServCats.where((c) => c.id != 'all').toList();
    }
    if (type == 'vulnerable') return kVulnCats;
    return kResources
        .map((r) => CategoryItem(id: r.id, label: r.label, icon: r.icon))
        .toList();
  }

  String _getSubmitLabel() {
    final all = [...kTypes, ...kEmTypes];
    final cur = all.where((t) => t.id == widget.state.pub.type).firstOrNull;
    return cur?.cta ?? 'Publicar';
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
        return widget.theme.primarySoft;
      case 'blue':
        return widget.theme.infoSoft;
      case 'amber':
        return widget.theme.accentSoft;
      case 'red':
        return widget.theme.sosSoft;
      case 'violet':
        return widget.theme.violetSoft;
      default:
        return widget.theme.primarySoft;
    }
  }
}
