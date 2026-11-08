import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

/// Ancho máximo del flujo de publicar en escritorio.
const double _kMaxWidth = 720;

/// Margen lateral: el mismo de Inicio (24; 16 en pantallas muy angostas).
double _sideFor(double width) => width < 360 ? 16.0 : 24.0;

class PublishScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const PublishScreen({super.key, required this.state, required this.theme});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  late TextEditingController _textController;

  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);

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

  /// Botón principal: ámbar; en modo emergencia conserva el rojo SOS.
  ButtonStyle get _primaryStyle {
    final base = ui.action().copyWith(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? ui.line
            : (widget.state.emergency ? NearbyColors.sos : ui.accent),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? ui.muted
            : (widget.state.emergency ? Colors.white : ui.onAccent),
      ),
    );
    return base;
  }

  ButtonStyle get _secondaryStyle => ui
      .action(filled: false)
      .copyWith(minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)));

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;

    return ColoredBox(
      color: theme.surface,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = _sideFor(box.maxWidth);
          // En escritorio la columna de lectura (720) queda alineada a la izquierda, como Inicio.
          final width = box.maxWidth < _kMaxWidth + side * 2
              ? box.maxWidth
              : _kMaxWidth + side * 2;
          return Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  // Encabezado por pasos: «PUBLICAR / 01 DE 03» + barritas
                  Padding(
                    padding: EdgeInsets.fromLTRB(side, 4, side, 8),
                    child: _stepHeader(p.step),
                  ),

                  // Contenido del paso
                  Expanded(
                    child: p.step == 1
                        ? _buildStep1(context, side)
                        : (p.step == 2
                              ? _buildStep2(context, side)
                              : _buildStep3(context, side)),
                  ),

                  // Pie del paso 2
                  if (p.step == 2)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(side, 12, side, 16),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        border: Border(top: BorderSide(color: ui.line)),
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
                            style: _primaryStyle,
                            icon: const Icon(Icons.send, size: 18),
                            label: Text(_getSubmitLabel()),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.cat != null
                                ? 'Último toque'
                                : 'Elige una opción para continuar',
                            style: TextStyle(color: ui.muted, fontSize: 11.5),
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
    );
  }

  Widget _stepHeader(int step) {
    const labels = ['Tipo', 'Detalle', 'Listo'];
    final current = step.clamp(1, 3);
    final section = widget.state.emergency ? 'REPORTAR' : 'PUBLICAR';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$section / 0$current DE 03',
                style: TextStyle(
                  color: ui.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(
              labels[current - 1],
              style: TextStyle(
                color: ui.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3].map((i) {
            final color = i == current
                ? ui.accent
                : (i < current ? ui.ink : ui.line);
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _pageTitle(String title, String? subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ui.ink,
          letterSpacing: -0.5,
          height: 1.15,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: ui.muted, fontSize: 14)),
      ],
    ],
  );

  Widget _iconSquare(
    IconData icon, {
    Color? bg,
    Color? fg,
    double size = 40,
    double iconSize = 20,
  }) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg ?? ui.blueSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: fg ?? ui.ink, size: iconSize),
  );

  Widget _buildStep1(BuildContext context, double side) {
    final theme = widget.theme;
    final state = widget.state;
    final types = state.emergency ? kEmTypes : kTypes;

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 16, side, 24),
      children: [
        _pageTitle(
          '¿Qué quieres ${state.emergency ? "reportar" : "publicar"}?',
          'Solo 3 toques: tipo, categoría y listo.',
        ),
        const SizedBox(height: 24),

        // Atajo por voz: panel tinta
        Material(
          color: ui.panel,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => state.openSheet('voice'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _iconSquare(
                    Icons.mic,
                    bg: ui.accent,
                    fg: ui.onAccent,
                    size: 48,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dilo con tu voz',
                          style: TextStyle(
                            color: ui.onPanel,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'La IA marca el tipo, la categoría y la ubicación por ti',
                          style: TextStyle(
                            color: ui.onPanel.withValues(alpha: 0.8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: ui.onPanel, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: ui.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o elige tú mismo',
                style: TextStyle(color: ui.muted, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: ui.line)),
          ],
        ),
        const SizedBox(height: 16),

        // Tipos: filas con ícono, en una tarjeta con borde
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: ui.line),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < types.length; i++) ...[
                if (i > 0) Divider(height: 1, color: ui.line),
                _typeRow(types[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeRow(PublishType t) {
    final state = widget.state;
    final red = t.tone == 'red';
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: t.id == 'need' ? state.tourTarget('publish-type') : null,
        onTap: () {
          state.pub.type = t.id;
          state.pub.cat = null;
          state.pub.step = 2;
          state.refresh();
          state.checkTourEvent('ptype');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _iconSquare(
                t.icon,
                bg: red ? _toneSoft(t.tone) : ui.blueSoft,
                fg: red ? _toneColor(t.tone) : ui.ink,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ui.ink,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.desc,
                      style: TextStyle(color: ui.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: ui.ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(BuildContext context, double side) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;
    final all = [...kTypes, ...kEmTypes];
    final curType = all.where((t) => t.id == p.type).firstOrNull ?? all.first;
    final categories = _getCategoriesForType(p.type);
    final redType = curType.tone == 'red';

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 16, side, 24),
      children: [
        // Tipo elegido con «Cambiar»
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                decoration: BoxDecoration(
                  color: ui.ivory,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      curType.icon,
                      color: redType ? _toneColor(curType.tone) : ui.ink,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        curType.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ui.ink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {
                p.step = 1;
                state.refresh();
              },
              style: TextButton.styleFrom(
                foregroundColor: ui.ink,
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('Cambiar'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          curType.q,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ui.ink,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),

        // Lo que detectó la IA
        if (p.ai != null && p.ai!['label'] != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ui.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: ui.ink, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: ui.ink,
                      ),
                      children: [
                        const TextSpan(
                          text: 'IA detectó: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
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

        // Categorías: 2 columnas en móvil, 3 en anchos mayores
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 520 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 108 * theme.scaleFactor,
              padding: EdgeInsets.zero,
              children: categories.map((c) {
                final isSel = p.cat == c.id;
                return _categoryTile(c, isSel);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        // Detalle
        Text(
          'Detalle (opcional)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ui.ink,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: ui.line),
            borderRadius: BorderRadius.circular(12),
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
                    color: ui.ink,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: curType.ph,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => p.text = val,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _squareButton(
                    Icons.mic,
                    'Dictar con tu voz',
                    () => state.openSheet('voice'),
                  ),
                  const SizedBox(height: 6),
                  _squareButton(
                    Icons.photo_camera,
                    'Adjuntar foto',
                    () => state.openSheet('photo'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Foto adjunta
        if (p.photo) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ui.ivory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ui.line),
            ),
            child: Row(
              children: [
                if (p.photoBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(p.photoBytes!),
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: ui.blueSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image, color: ui.ink, size: 28),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.photoName ?? 'Foto adjunta',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ui.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Se publicará junto a tu solicitud',
                        style: TextStyle(color: ui.muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cambiar foto',
                  icon: Icon(Icons.edit_outlined, size: 18, color: ui.ink),
                  onPressed: () => state.openSheet('photo'),
                ),
                IconButton(
                  tooltip: 'Quitar foto',
                  icon: Icon(Icons.close, size: 18, color: NearbyColors.sos),
                  onPressed: () {
                    p.photo = false;
                    p.photoBytes = null;
                    p.photoName = null;
                    p.photoPath = null;
                    state.refresh();
                  },
                ),
              ],
            ),
          ),
        ],

        // Ubicación
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            color: ui.ivory,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _iconSquare(Icons.my_location, bg: theme.surface, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: ui.muted,
                    ),
                    children: [
                      TextSpan(
                        text: p.ai?['loc'] == null && widget.state.pubLocating
                            ? 'Buscando dónde estás…'
                            : widget.state.publishWhere,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ui.ink,
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
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ui.ink,
                          ),
                        )
                      : Icon(Icons.refresh, color: ui.ink, size: 20),
                ),
            ],
          ),
        ),

        if (p.type == 'vulnerable') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
                    'Solo brigadistas verificados ven la dirección exacta. Los demás vecinos ven la zona aproximada.',
                    style: TextStyle(color: ui.ink, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _categoryTile(CategoryItem c, bool isSel) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;
    return Material(
      color: isSel ? ui.blueSoft : theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSel ? ui.ink : ui.line,
          width: isSel ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: c.id == 'herramientas'
            ? state.tourTarget('publish-category')
            : null,
        onTap: () {
          p.cat = c.id;
          state.refresh();
          state.checkTourEvent('pcat');
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconSquare(
                    c.icon,
                    bg: isSel ? ui.accent : ui.blueSoft,
                    fg: isSel ? ui.onAccent : ui.ink,
                    size: 38,
                  ),
                  const Spacer(),
                  if (isSel) Icon(Icons.check_circle, color: ui.ink, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  c.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.2,
                    color: ui.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _squareButton(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: ui.blueSoft,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: ui.ink, size: 20),
            ),
          ),
        ),
      );

  Widget _buildStep3(BuildContext context, double side) {
    final theme = widget.theme;
    final state = widget.state;
    final p = state.pub;
    final off = state.offline;

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 32, side, 32),
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: off
                  ? ui.ivory
                  : (state.emergency ? theme.sosSoft : ui.blueSoft),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              off ? Icons.cloud_sync_outlined : Icons.check_circle_outline,
              color: state.emergency && !off ? NearbyColors.sos : ui.ink,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          off
              ? 'Guardado en tu teléfono'
              : (p.type == 'vulnerable' ? 'Reporte enviado' : '¡Publicado!'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ui.ink,
            letterSpacing: -0.5,
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
          style: TextStyle(color: ui.muted, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 24),

        if (off && p.type == 'vulnerable' && state.lastCode != null) ...[
          _buildCompressedCodeCard(state.lastCode!),
          const SizedBox(height: 20),
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
          style: _primaryStyle,
          child: Text(
            p.type == 'vulnerable'
                ? 'Ver tablero'
                : (p.type == 'service'
                      ? 'Ver servicios'
                      : (state.emergency ? 'Ver recursos' : 'Ver en el muro')),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: state.tourTarget('publish-home'),
          onPressed: () => state.selectTab('home'),
          style: _secondaryStyle,
          icon: const Icon(Icons.home_outlined, size: 18),
          label: const Text('Volver al inicio'),
        ),
      ],
    );
  }

  Widget _buildCompressedCodeCard(String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        border: Border.all(color: ui.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconSquare(Icons.auto_awesome, size: 32, iconSize: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Comprimido por IA para SMS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ui.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ui.panel,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: ui.onPanel,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${code.length} de 25 caracteres',
                style: TextStyle(color: ui.muted, fontSize: 11.5),
              ),
              Text(
                'Cabe en 1 SMS',
                style: TextStyle(color: ui.muted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.state.openSheet('sonic'),
                  style: ui.action(),
                  icon: const Icon(Icons.graphic_eq, size: 16),
                  label: const Text(
                    'Enviar por sonido',
                    overflow: TextOverflow.ellipsis,
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
                  style: ui.action(filled: false),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text(
                    'Ver brigadista',
                    overflow: TextOverflow.ellipsis,
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
