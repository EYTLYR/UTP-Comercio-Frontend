import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../services/speech_input.dart';

class NearbyBottomSheetModal extends StatelessWidget {
  final NearbyThemeData theme;
  final AppState state;

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

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: state.closeSheet,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 460,
              maxHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.viewInsetsOf(context).bottom -
                  24,
            ),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.line,
                        borderRadius: BorderRadius.circular(3),
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
        ),
      ],
    );
  }

  Widget _buildAiRunSheet(BuildContext context) {
    final steps = [
      'Leyendo 127 favores del muro solidario',
      'Revisando 48 oficios y 312 reseñas vecinales',
      'Armando el inventario de supervivencia (${state.buildInventory().length} hallazgos)',
      'Cruzando con ${state.reports.where((r) => r.status != 'a').length} reportes de vecinos vulnerables',
      'Asignando a los vecinos más cercanos',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [NearbyColors.violet, Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'IA cruzando el historial del barrio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lo que los vecinos ofrecieron en el día a día ahora sirve para rescatar.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 18),
        ...List.generate(steps.length, (i) {
          final isDone = i < state.aiStep;
          final isRun = i == state.aiStep;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                if (isDone)
                  Icon(Icons.check_circle, color: theme.primary, size: 22)
                else if (isRun)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.violet,
                    ),
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: theme.line,
                    size: 22,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isDone || isRun
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isDone
                          ? theme.ink
                          : (isRun ? theme.violet : theme.muted),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmSheet(BuildContext context) {
    final yo = state.emSource == 'yo';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.sosSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.crisis_alert, color: theme.sos, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Modo emergencia activo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nearby muestra lo necesario para coordinar ayuda: tablero, recursos, grupos de apoyo y puntos seguros.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _kvRow(
                Icons.campaign,
                'Activado por',
                yo ? 'Ti, al enviar un SOS' : 'Defensa Civil / Municipalidad',
              ),
              const Divider(height: 16),
              _kvRow(
                Icons.schedule,
                'Desde',
                '10:42 · ${yo ? "Alerta personal" : "Sismo en Lima"}',
              ),
              const Divider(height: 16),
              _kvRow(Icons.location_on, 'Zona', 'Zona 3 · Las Flores'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () {
            state.closeSheet();
            state.go('tablero');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.btnBg,
            foregroundColor: theme.btnInk,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(Icons.dashboard, color: theme.primary, size: 20),
          label: const Text(
            'Ver tablero del barrio',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: state.tourTarget('em-exit'),
          onPressed: () => state.openSheet('em-off'),
          style: OutlinedButton.styleFrom(
            foregroundColor: NearbyColors.sos,
            side: const BorderSide(color: NearbyColors.sos, width: 1.5),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.power_settings_new, size: 20),
          label: const Text(
            'Desactivar modo emergencia',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildEmOffSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.primarySoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.verified_user, color: theme.primary, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          '¿Volver al modo normal?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          state.emSource == 'yo'
              ? 'Tú activaste este modo. Al salir, Nearby vuelve a mostrar servicios y el muro de favores.'
              : 'La Municipalidad aún mantiene la emergencia en tu zona. Puedes volver al modo normal en tu app: seguirás recibiendo alertas críticas.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        // Notify contacts checkbox
        InkWell(
          onTap: () {
            state.emNotify = !state.emNotify;
            state.refresh();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sms, color: theme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avisar a mis contactos que estoy a salvo',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.ink,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        'Mamá, Carlos, Sra. Rosa',
                        style: TextStyle(color: theme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: state.emNotify ? theme.primary : Colors.transparent,
                    border: Border.all(
                      color: state.emNotify ? theme.primary : theme.line,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: state.emNotify
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () {
            state.toggleEmergency();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.btnBg,
            foregroundColor: theme.btnInk,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Sí, volver al modo normal',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => state.closeSheet(),
          child: Text(
            'Seguir en modo emergencia',
            style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.infoSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.photo_camera, color: theme.info, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Agregar una foto',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Una foto ayuda a tus vecinos a entender mejor lo que necesitas.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  state.pub.photo = true;
                  state.closeSheet();
                  state.toast('Foto adjunta', icon: 'image');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.btnBg,
                  foregroundColor: theme.btnInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.photo_camera, size: 18),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  state.pub.photo = true;
                  state.closeSheet();
                  state.toast('Foto adjunta', icon: 'image');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.ink,
                  side: BorderSide(color: theme.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Recientes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.ink,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: icons.map((ic) {
            return InkWell(
              onTap: () {
                state.pub.photo = true;
                state.closeSheet();
                state.toast('Foto adjunta', icon: 'image');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Icon(ic, color: theme.primary, size: 32)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => state.closeSheet(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinSheet(BuildContext context, String? groupName) {
    final g =
        kGroups.where((x) => x.name == groupName).firstOrNull ?? kGroups.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.violetSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(g.icon, color: theme.violet, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Unirte a ${g.name}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${g.desc}. Te avisaremos cuando el grupo necesite manos. Puedes salir cuando quieras.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _kvRow(Icons.groups, 'Integrantes', '${g.members} vecinos'),
              const Divider(height: 16),
              _kvRow(
                Icons.schedule,
                'Estado',
                g.live ? 'Activo ahora' : 'Desde las 14:00',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () {
            state.joined[g.name] = true;
            state.closeSheet();
            state.toast('Te uniste a «${g.name}»', icon: 'person_add');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.btnBg,
            foregroundColor: theme.btnInk,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Sí, quiero unirme',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => state.closeSheet(),
            child: Text(
              'Ahora no',
              style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.sosSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.logout, color: theme.sos, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          '¿Cerrar sesión?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tus contactos y tu ficha quedan guardados en tu cuenta. Para volver a entrar solo necesitas tu celular.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            state.closeSheet();
            state.emergency = false;
            state.zoneEm = false;
            state.phoneDraft = '';
            state.go('splash', reset: true);
            state.toast('Cerraste sesión', icon: 'logout');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: NearbyColors.sos,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => state.closeSheet(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kvRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: theme.muted, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: theme.muted, fontSize: 13.5)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: theme.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ],
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
    final classified = widget.state.classify(text);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _voice.listening ? Icons.mic : Icons.mic_none,
          color: theme.violet,
          size: 42,
        ),
        const SizedBox(height: 12),
        Text(
          _voice.listening ? 'Te escucho…' : 'Dilo con tu voz',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Activa el micrófono, cuéntalo con tus palabras y revisa el texto antes de continuar.',
          style: TextStyle(color: theme.muted, fontSize: 13.5),
        ),
        if (_voice.listening) const Center(child: _WaveBars()),
        const SizedBox(height: 14),
        if (_voice.error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(_voice.error!, style: TextStyle(color: theme.sosDark)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const ValueKey('voice-transcript'),
          controller: _text,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: theme.ink),
          decoration: InputDecoration(
            hintText: 'Tu voz aparecerá aquí. También puedes escribir.',
            filled: true,
            fillColor: theme.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
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
          icon: Icon(_voice.listening ? Icons.stop : Icons.mic),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.btnBg,
            foregroundColor: theme.btnInk,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Usar este texto'),
        ),
        TextButton(
          onPressed: widget.state.closeSheet,
          child: const Text('Cancelar'),
        ),
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
    final code = widget.state.lastCode ?? 'NB#SOS!S1@LF245\$P:ALTA';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [NearbyColors.violet, Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.graphic_eq, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Puente de sonido',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: widget.theme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Transmitiendo tu código de celular a celular, sin internet ni señal. Alcance de unos 5 metros.',
          style: TextStyle(color: widget.theme.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1424),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF7BE3C6),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(22, (i) {
                  final h = _transmitting
                      ? 6.0 + (((_anim.value + (i * 0.12)) % 1.0) * 36.0)
                      : 8.0;
                  return Container(
                    width: 5,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: widget.theme.violet,
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
            _transmitting
                ? 'Transmitiendo…'
                : '2 celulares cercanos confirmaron la recepción',
            style: TextStyle(
              color: _transmitting ? widget.theme.violet : widget.theme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => widget.state.closeSheet(),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.btnBg,
            foregroundColor: widget.theme.btnInk,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
