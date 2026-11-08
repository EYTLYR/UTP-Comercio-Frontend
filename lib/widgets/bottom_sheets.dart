import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../services/speech_input.dart';

// --- Piezas comunes de las hojas inferiores ---

/// Cuadrito de ícono de cabecera (radio 12).
Widget _sheetIcon(
  NearbyCommunityStyle ui,
  IconData icon, {
  Color? bg,
  Color? fg,
}) => Container(
  width: 48,
  height: 48,
  decoration: BoxDecoration(
    color: bg ?? ui.blueSoft,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(icon, color: fg ?? ui.ink, size: 24),
);

/// Título de hoja: 20 w700 en tinta.
Widget _sheetTitle(NearbyCommunityStyle ui, String text) => Text(
  text,
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ui.ink,
    letterSpacing: -0.3,
    height: 1.25,
  ),
);

/// Texto de apoyo bajo el título.
Widget _sheetBody(NearbyCommunityStyle ui, String text) => Text(
  text,
  style: TextStyle(color: ui.muted, fontSize: 14, height: 1.45),
);

/// Botón principal ámbar a todo el ancho.
ButtonStyle _sheetPrimary(NearbyCommunityStyle ui) => ui.action().copyWith(
  minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
  ),
);

/// Botón secundario de contorno a todo el ancho.
ButtonStyle _sheetSecondary(NearbyCommunityStyle ui) => ui
    .action(filled: false)
    .copyWith(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

/// Acción terciaria («Cancelar», «Ahora no»).
Widget _sheetDismiss(
  NearbyCommunityStyle ui,
  String label,
  VoidCallback onPressed,
) => Center(
  child: TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(foregroundColor: ui.muted),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  ),
);

class NearbyBottomSheetModal extends StatelessWidget {
  final NearbyThemeData theme;
  final AppState state;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const NearbyBottomSheetModal({
    super.key,
    required this.theme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state.sheet == null) return const SizedBox.shrink();

    final type = state.sheet!['type'] as String;
    final id = state.sheet!['id'];
    final side = MediaQuery.sizeOf(context).width < 360 ? 16.0 : 24.0;

    return TweenAnimationBuilder<double>(
      key: ValueKey('sheet_${type}_$id'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: const Cubic(0.32, 0.72, 0.0, 1.0), // iOS drawer curve
      builder: (context, progress, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: state.closeSheet,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.5 * progress),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionalTranslation(
                translation: Offset(0, 1.0 - progress),
                child: child,
              ),
            ),
          ],
        );
      },
      // En pantallas anchas la hoja queda centrada y legible (máx. 560).
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight:
              MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom -
              24,
        ),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(side, 12, side, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Asa para arrastrar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: ui.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (type == 'ai-run')
                _buildAiRunSheet(context)
              else if (type == 'voice')
                _VoiceSheet(theme: theme, state: state)
              else if (type == 'sonic')
                _SonicSheet(theme: theme, state: state)
              else if (type == 'em')
                _buildEmSheet(context)
              else if (type == 'em-off')
                _buildEmOffSheet(context)
              else if (type == 'photo')
                _buildPhotoSheet(context)
              else if (type == 'join')
                _buildJoinSheet(context, id as String?)
              else if (type == 'logout')
                _buildLogoutSheet(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Panel marfil con filas «etiqueta · valor» separadas por líneas.
  Widget _infoPanel(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: ui.ivory,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: ui.line),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _buildAiRunSheet(BuildContext context) {
    final steps = [
      'Leyendo ${state.posts.length} favores del muro solidario',
      'Revisando ${state.services.length} oficios y ${state.services.fold(0, (sum, s) => sum + s.vb)} recomendaciones vecinales',
      'Armando el inventario de supervivencia (${state.buildInventory().length} hallazgos)',
      'Cruzando con ${state.reports.where((r) => r.status != 'a').length} reportes de vecinos vulnerables',
      'Asignando a los vecinos más cercanos',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(ui, Icons.auto_awesome),
        const SizedBox(height: 16),
        _sheetTitle(ui, 'IA cruzando el historial del barrio'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          'Lo que los vecinos ofrecieron en el día a día ahora sirve para rescatar.',
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: ui.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(steps.length, (i) {
              final isDone = i < state.aiStep;
              final isRun = i == state.aiStep;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: ui.line,
                      indent: 12,
                      endIndent: 12,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Center(
                            child: isDone
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.primary,
                                    size: 22,
                                  )
                                : isRun
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: ui.ink,
                                    ),
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: ui.muted.withValues(alpha: 0.5),
                                    size: 22,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isDone || isRun
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDone || isRun ? ui.ink : ui.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEmSheet(BuildContext context) {
    final yo = state.emSource == 'yo';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(
          ui,
          Icons.crisis_alert,
          bg: theme.sosSoft,
          fg: theme.sos,
        ),
        const SizedBox(height: 16),
        _sheetTitle(ui, 'Modo emergencia activo'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          'Nearby muestra lo necesario para coordinar ayuda: tablero, recursos, grupos de apoyo y puntos seguros.',
        ),
        const SizedBox(height: 16),
        _infoPanel([
          _kvRow(
            Icons.campaign_outlined,
            'Activado por',
            yo
                ? 'Ti, desde tu app'
                : !state.connected
                ? 'Defensa Civil / Municipalidad'
                : switch (state.zoneModeSource) {
                    'AUTO_SOS' => 'Automático: varios SOS en tu zona',
                    'USER' => 'Un vecino de tu zona',
                    _ => 'La Municipalidad de tu zona',
                  },
          ),
          _kvRow(
            Icons.schedule,
            'Desde',
            !state.connected
                ? '10:42 · ${yo ? "Alerta personal" : "Sismo en Lima"}'
                : _since(state.emergencySince),
          ),
          if (!yo || !state.connected)
            _kvRow(
              Icons.info_outline,
              'Motivo',
              !state.connected
                  ? (yo ? 'Alerta personal' : 'Sismo en Lima')
                  : (state.zoneModeReason?.isNotEmpty == true
                        ? state.zoneModeReason!
                        : 'Sin motivo indicado'),
            )
          else
            _kvRow(Icons.info_outline, 'Motivo', 'Alerta personal'),
          _kvRow(Icons.location_on_outlined, 'Zona', state.zoneName),
        ]),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            state.closeSheet();
            state.go('tablero');
          },
          style: _sheetPrimary(ui),
          icon: const Icon(Icons.dashboard_outlined, size: 20),
          label: const Text('Ver tablero del barrio'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: state.tourTarget('em-exit'),
          onPressed: () => state.openSheet('em-off'),
          style: _sheetSecondary(ui),
          icon: const Icon(Icons.power_settings_new, size: 20),
          label: const Text('Desactivar modo emergencia'),
        ),
      ],
    );
  }

  /// Nombres reales de mis contactos de emergencia.
  String _contactNames() {
    final names = state.contacts
        .map(
          (id) => state.contactBook.where((c) => c.id == id).firstOrNull?.name,
        )
        .whereType<String>()
        .join(', ');
    return names.isEmpty ? 'Aún no tienes contactos de emergencia' : names;
  }

  Widget _buildEmOffSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(ui, Icons.verified_user_outlined),
        const SizedBox(height: 16),
        _sheetTitle(ui, '¿Volver al modo normal?'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          state.emSource == 'yo'
              ? 'Tú activaste este modo. Al salir, Nearby vuelve a mostrar servicios y el muro de favores.'
              : 'La Municipalidad aún mantiene la emergencia en tu zona. Puedes volver al modo normal en tu app: seguirás recibiendo alertas críticas.',
        ),
        const SizedBox(height: 16),
        // Casilla: avisar a mis contactos
        Semantics(
          checked: state.emNotify,
          child: Material(
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: ui.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                state.emNotify = !state.emNotify;
                state.refresh();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ui.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sms_outlined, color: ui.ink, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avisar a mis contactos que estoy a salvo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ui.ink,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _contactNames(),
                            style: TextStyle(color: ui.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: state.emNotify ? ui.ink : Colors.transparent,
                        border: Border.all(
                          color: state.emNotify ? ui.ink : ui.muted,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: state.emNotify
                          ? Icon(Icons.check, color: theme.surface, size: 16)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            state.toggleEmergency();
          },
          style: _sheetPrimary(ui),
          child: const Text('Sí, volver al modo normal'),
        ),
        const SizedBox(height: 4),
        _sheetDismiss(
          ui,
          'Seguir en modo emergencia',
          () => state.closeSheet(),
        ),
      ],
    );
  }

  Widget _buildPhotoSheet(BuildContext context) {
    final icons = [
      Icons.construction,
      Icons.handyman,
      Icons.inventory_2,
      Icons.house,
      Icons.pets,
      Icons.local_florist,
    ];
    void attach() {
      state.pub.photo = true;
      state.closeSheet();
      state.toast('Foto adjunta', icon: 'image');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(ui, Icons.photo_camera_outlined),
        const SizedBox(height: 16),
        _sheetTitle(ui, 'Agregar una foto'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          'Una foto ayuda a tus vecinos a entender mejor lo que necesitas.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: attach,
                style: _sheetPrimary(ui),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: attach,
                style: _sheetSecondary(ui),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Recientes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ui.ink,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            // 3 por fila en móvil; una sola fila de 6 en hojas anchas.
            crossAxisCount: constraints.maxWidth >= 440 ? 6 : 3,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: icons.map((ic) {
              return Material(
                color: ui.ivory,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: attach,
                  child: Center(child: Icon(ic, color: ui.ink, size: 28)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sheetDismiss(ui, 'Cancelar', () => state.closeSheet()),
      ],
    );
  }

  Widget _buildJoinSheet(BuildContext context, String? groupName) {
    final g =
        state.groups.where((x) => x.name == groupName).firstOrNull ??
        (state.groups.isNotEmpty ? state.groups.first : kGroups.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(ui, g.icon),
        const SizedBox(height: 16),
        _sheetTitle(ui, 'Unirte a ${g.name}'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          '${g.desc}. Te avisaremos cuando el grupo necesite manos. Puedes salir cuando quieras.',
        ),
        const SizedBox(height: 16),
        _infoPanel([
          _kvRow(Icons.groups_outlined, 'Integrantes', '${g.members} vecinos'),
          _kvRow(
            Icons.schedule,
            'Estado',
            g.live ? 'Activo ahora' : 'Sin actividad ahora',
          ),
        ]),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            state.joinGroup(g);
            state.closeSheet();
            state.toast('Te uniste a «${g.name}»', icon: 'person_add');
          },
          style: _sheetPrimary(ui),
          child: const Text('Sí, quiero unirme'),
        ),
        const SizedBox(height: 4),
        _sheetDismiss(ui, 'Ahora no', () => state.closeSheet()),
      ],
    );
  }

  Widget _buildLogoutSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(ui, Icons.logout),
        const SizedBox(height: 16),
        _sheetTitle(ui, '¿Cerrar sesión?'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          'Tus contactos y tu ficha quedan guardados en tu cuenta. Para volver a entrar solo necesitas tu celular.',
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            state.closeSheet();
            state.logout();
          },
          style: _sheetPrimary(ui),
          child: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 4),
        _sheetDismiss(ui, 'Cancelar', () => state.closeSheet()),
      ],
    );
  }

  /// «Hoy 10:42» o «07/11 10:42».
  static String _since(DateTime? t) {
    if (t == null) return 'Hace un momento';
    final now = DateTime.now();
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return 'Hoy $hm';
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} $hm';
  }

  Widget _kvRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ui.muted, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: ui.muted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: ui.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Real microphone input. Text is always reviewed before use. ---
class _VoiceSheet extends StatefulWidget {
  final NearbyThemeData theme;
  final AppState state;
  const _VoiceSheet({required this.theme, required this.state});
  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  late final SpeechInput _voice;
  final _text = TextEditingController();
  String _lastTranscript = '';
  bool _usingText = false;

  @override
  void initState() {
    super.initState();
    _voice = widget.state.voice;
    _voice.addListener(_onVoice);
  }

  void _onVoice() {
    if (!mounted) return;
    if (_voice.transcript != _lastTranscript) {
      _lastTranscript = _voice.transcript;
      _text.value = TextEditingValue(
        text: _lastTranscript,
        selection: TextSelection.collapsed(offset: _lastTranscript.length),
      );
    }
    setState(() {});
  }

  Future<void> _useText() async {
    if (_usingText) return;
    setState(() => _usingText = true);
    await _voice.stop();
    if (!mounted) return;
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _usingText = false);
      return;
    }
    final classified = await widget.state.classifyRemote(text);
    if (!mounted) return;
    widget.state.pub.reset(
      step: 2,
      type: classified['type'] as String?,
      cat: classified['cat'] as String?,
      text: text,
    );
    widget.state.pub.ai = classified;
    widget.state.closeSheet();
    if (widget.state.screen != 'publicar') widget.state.go('publicar');
    widget.state.toast(
      'Revisa el texto y la categoría antes de publicar.',
      icon: 'auto_awesome',
    );
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoice);
    _voice.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ui = NearbyCommunityStyle(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _sheetIcon(
            ui,
            _voice.listening ? Icons.mic : Icons.mic_none,
            bg: _voice.listening ? ui.accent : ui.blueSoft,
            fg: _voice.listening ? ui.onAccent : ui.ink,
          ),
        ),
        const SizedBox(height: 16),
        _sheetTitle(ui, _voice.listening ? 'Te escucho…' : 'Dilo con tu voz'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          'Activa el micrófono, cuéntalo con tus palabras y revisa el texto antes de continuar.',
        ),
        if (_voice.listening) const Center(child: _WaveBars()),
        const SizedBox(height: 16),
        if (_voice.error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _voice.error!,
              style: TextStyle(color: theme.sosDark, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const ValueKey('voice-transcript'),
          controller: _text,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: ui.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tu voz aparecerá aquí. También puedes escribir.',
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
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _voice.preparing || _usingText
              ? null
              : () async {
                  if (_voice.listening) {
                    await _voice.stop();
                  } else {
                    await _voice.start();
                  }
                },
          style: _sheetSecondary(ui),
          icon: Icon(_voice.listening ? Icons.stop : Icons.mic, size: 20),
          label: Text(
            _voice.preparing
                ? 'Preparando micrófono…'
                : _voice.listening
                ? 'Detener micrófono'
                : 'Activar micrófono',
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _text.text.trim().isEmpty || _usingText ? null : _useText,
          style: _sheetPrimary(ui),
          child: const Text('Usar este texto'),
        ),
        const SizedBox(height: 4),
        _sheetDismiss(ui, 'Cancelar', widget.state.closeSheet),
      ],
    );
  }
}

class _WaveBars extends StatefulWidget {
  const _WaveBars();

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final val = (_anim.value + (i * 0.18)) % 1.0;
              final height = 14.0 + (val * 42.0);
              return Container(
                width: 7,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: NearbyColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// --- Sonic Sound Bridge Modal ---
class _SonicSheet extends StatefulWidget {
  final NearbyThemeData theme;
  final AppState state;

  const _SonicSheet({required this.theme, required this.state});

  @override
  State<_SonicSheet> createState() => _SonicSheetState();
}

class _SonicSheetState extends State<_SonicSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _transmitting = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _transmitting = false);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(widget.theme);
    // Con sesión no hay código de ejemplo: sin SOS previo no hay nada que transmitir.
    final code =
        widget.state.lastCode ??
        (widget.state.connected ? null : 'NB#SOS!S1@LF245\$P:ALTA');
    final sending = _transmitting && code != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetIcon(ui, Icons.graphic_eq),
        const SizedBox(height: 16),
        _sheetTitle(ui, 'Puente de sonido'),
        const SizedBox(height: 6),
        _sheetBody(
          ui,
          code == null
              ? 'Aún no tienes un código SOS. Se genera cuando envías una alerta sin internet.'
              : 'Transmitiendo tu código de celular a celular, sin internet ni señal. Alcance de unos 5 metros.',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: NearbyColors.darkNavy,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code ?? 'Sin código todavía',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: NearbyColors.darkPrimaryDark,
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return SizedBox(
              height: 48,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(22, (i) {
                  final h = sending
                      ? 6.0 + (((_anim.value + (i * 0.12)) % 1.0) * 36.0)
                      : 8.0;
                  return Container(
                    width: 5,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: ui.ink,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            sending
                ? 'Transmitiendo…'
                : code == null
                ? 'Nada que transmitir'
                : widget.state.connected
                ? 'Código emitido. Pide a quien esté cerca que abra el Puente.'
                : '2 celulares cercanos confirmaron la recepción',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sending
                  ? ui.ink
                  : (code == null ? ui.muted : widget.theme.primaryDark),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => widget.state.closeSheet(),
          style: _sheetPrimary(ui),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
