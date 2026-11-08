import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/common_widgets.dart';
import 'emergency/widgets/sos_countdown_button.dart';

// --- Utilidades de diseño compartidas por las pantallas de emergencia ---

/// Margen lateral de página: 24 (16 en anchos muy estrechos).
double _gutter(double width) => width < 360 ? 16 : 24;

/// Contenido a ancho de lectura (máx. 640) centrado en escritorio.
Widget _readable(Widget child, {double maxWidth = 640}) => Align(
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: SizedBox(width: double.infinity, child: child),
  ),
);

/// Cuadrito de ícono (radio 8) de las filas de opciones.
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

/// Botón principal ámbar, un poco más alto en los momentos de emergencia.
ButtonStyle _primary(NearbyCommunityStyle ui) => ui.action().copyWith(
  minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700),
  ),
);

/// Botón de contorno blanco sobre fondo rojo.
ButtonStyle _onRedOutline() => OutlinedButton.styleFrom(
  foregroundColor: Colors.white,
  side: const BorderSide(color: Colors.white70, width: 1.5),
  minimumSize: const Size.fromHeight(52),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
);

/// Botón relleno blanco sobre fondo rojo (acción principal del momento SOS).
ButtonStyle _onRedFilled() => ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: NearbyColors.sosDark,
  elevation: 0,
  minimumSize: const Size.fromHeight(52),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w700,
  ),
);

/// Accesos directos a los números de emergencia: 2 columnas en móvil, 4 en ancho.
class _CallGrid extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  final bool onRed;

  const _CallGrid({
    required this.state,
    required this.theme,
    this.onRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: constraints.maxWidth >= 560 ? 4 : 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: MediaQuery.textScalerOf(context).scale(66),
        children: kCalls.map((c) {
          return Material(
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: onRed ? BorderSide.none : BorderSide(color: ui.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => state.startCall(c.num),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    _iconSquare(
                      c.icon,
                      bg: theme.sosSoft,
                      fg: theme.sos,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.num,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: ui.ink,
                              height: 1.15,
                            ),
                          ),
                          Text(
                            c.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ui.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- Dedicated SOS Screen ---
class SosScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const SosScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NearbyColors.sos,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final g = _gutter(constraints.maxWidth);
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(g, 12, g, 24),
              child: _readable(
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 36).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Barra superior + encabezado
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PressableScale(
                                scale: 0.92,
                                onTap: () => state.back(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      state.offline
                                          ? Icons.sms
                                          : Icons.my_location,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      state.offline
                                          ? 'Modo SMS'
                                          : 'Ubicación lista',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Emergencia',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mantén presionado el botón 2 segundos.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Botón central de mantener presionado
                      Center(
                        child: SosHoldButton(
                          size: constraints.maxHeight < 680 ? 172 : 196,
                          isLarge: true,
                          onComplete: () {
                            state.sosType = null;
                            state.go('sos-countdown');
                          },
                          onCancelShort: () {
                            state.toast(
                              'Mantén presionado 2 segundos para enviar la alerta',
                              icon: 'touch_app',
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Qué pasa al enviar
                      Column(
                        children: [
                          _whatRow(
                            Icons.groups,
                            'Alerta a los vecinos y la brigada en 500 m',
                          ),
                          const SizedBox(height: 8),
                          _whatRow(
                            Icons.share_location,
                            state.connected && state.contacts.isEmpty
                                ? 'Agrega contactos para compartir tu ubicación'
                                : 'Tu ubicación a ${state.contacts.length} contactos ${state.offline ? "por SMS" : "(en vivo)"}',
                          ),
                          const SizedBox(height: 8),
                          _whatRow(
                            Icons.crisis_alert,
                            'Puedes activar el modo emergencia',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Llamadas directas
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'O llama directo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CallGrid(state: state, theme: theme, onRed: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _whatRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _iconSquare(
            icon,
            bg: Colors.white.withValues(alpha: 0.18),
            fg: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SOS Countdown Screen ---
class SosCountdownScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const SosCountdownScreen({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  State<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends State<SosCountdownScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown;
  bool _sent = false;
  bool _blackoutTotal = false;
  Timer? _deadline;
  Timer? _soundTicker;
  static const types = [
    ('salud', 'Salud', Icons.medical_services),
    ('fuego', 'Incendio', Icons.local_fire_department),
    ('robo', 'Robo', Icons.local_police),
    ('sismo', 'Sismo', Icons.house),
    ('violencia', 'Violencia', Icons.front_hand),
    ('otro', 'Otro', Icons.more_horiz),
  ];

  bool _isSilentCategory(String category) {
    final upper = category.toUpperCase();
    return upper == 'ROBO' ||
        upper == 'ROBBERY' ||
        upper == 'VIOLENCIA' ||
        upper == 'VIOLENCE' ||
        upper == 'DOMESTIC_VIOLENCE';
  }

  @override
  void initState() {
    super.initState();
    final initialType = widget.state.sosType;
    if (initialType != null && _isSilentCategory(initialType)) {
      unawaited(widget.state.setSilentMode(true));
    } else if (!widget.state.isSilentMode) {
      unawaited(SoundService.instance.playSosCountdown());
      _soundTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!widget.state.isSilentMode) {
          unawaited(SoundService.instance.playSosCountdown());
        }
      });
    }
    _countdown =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _send();
          })
          ..forward();
    _deadline = Timer(const Duration(seconds: 5), _send);
  }

  void _selectCategory(String typeKey) {
    widget.state.sosType = typeKey;
    final isSilent = _isSilentCategory(typeKey);
    if (isSilent) {
      _soundTicker?.cancel();
      unawaited(widget.state.setSilentMode(true));
    } else if (widget.state.isSilentMode) {
      unawaited(widget.state.setSilentMode(false));
      if (!_sent) {
        _soundTicker?.cancel();
        _soundTicker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!widget.state.isSilentMode) {
            unawaited(SoundService.instance.playSosCountdown());
          }
        });
      }
    }
    setState(() {});
  }

  void _send() {
    if (_sent) return;
    _sent = true;
    _soundTicker?.cancel();
    _deadline?.cancel();
    _countdown.stop();
    if (!widget.state.isSilentMode) {
      unawaited(SoundService.instance.playSosAlarm());
    }
    widget.state.go('sos-sent');
    widget.state.sendSos();
  }

  void _cancel() {
    _soundTicker?.cancel();
    _deadline?.cancel();
    _countdown.stop();
    unawaited(SoundService.instance.stopSosAlarm());
    unawaited(SoundService.instance.stopAll());
    if (widget.state.isSilentMode) {
      unawaited(widget.state.setSilentMode(false));
    }
    widget.state.go('home', reset: true);
    widget.state.toast(
      'Alerta cancelada. No se envió nada.',
      icon: 'cancel',
    );
  }

  @override
  void dispose() {
    _soundTicker?.cancel();
    _deadline?.cancel();
    _countdown.dispose();
    if (!_sent) {
      unawaited(SoundService.instance.stopSosAlarm());
      unawaited(SoundService.instance.stopAll());
    }
    super.dispose();
  }

  Widget _buildSilentScreen(BuildContext context, double g) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        setState(() => _blackoutTotal = !_blackoutTotal);
      },
      child: ColoredBox(
        color: Colors.black,
        child: SafeArea(
          child: _blackoutTotal
              ? const SizedBox.expand()
              : Padding(
                  padding: EdgeInsets.fromLTRB(g, 16, g, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield, color: Colors.white24, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'MODO SIGILOSO ACTIVO',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            TimeOfDay.now().format(context),
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.white24,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Pantalla apagada simulada',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _countdown,
                        builder: (context, _) {
                          final left = (5 * (1 - _countdown.value)).ceil();
                          return Text(
                            'Enviando auxilio silencioso en ${left}s...',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          'Sonido silenciado · Brillo al mínimo\nLlamadas VoIP entrantes se auto-rechazan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white70,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        icon: const Icon(Icons.send, size: 18, color: Colors.white70),
                        label: const Text('Enviar ya en silencio'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _cancel,
                        child: const Text(
                          'Cancelar alerta',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Doble toque para alternar pantalla 100% apagada',
                        style: TextStyle(
                          color: Colors.white12,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final g = _gutter(bounds.maxWidth);
      if (widget.state.isSilentMode) {
        return _buildSilentScreen(context, g);
      }
      return ColoredBox(
        color: NearbyColors.sos,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(g, 24, g, 16),
                child: _readable(
                  Column(
                    children: [
                      const Text(
                        'Enviando alerta en',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SosCountdownButton(
                        countdown: _countdown,
                        onCancel: _cancel,
                        onComplete: _send,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '¿Qué está pasando? (opcional)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // 3 columnas en móvil, una sola fila de 6 en ancho.
                          final cols = constraints.maxWidth >= 520 ? 6 : 3;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: types.map((type) {
                              final selected =
                                  widget.state.sosType == type.$1;
                              final color = selected
                                  ? NearbyColors.sosDark
                                  : Colors.white;
                              return SizedBox(
                                width:
                                    (constraints.maxWidth - 8 * (cols - 1)) /
                                    cols,
                                child: Semantics(
                                  button: true,
                                  selected: selected,
                                  child: InkWell(
                                    onTap: () => _selectCategory(type.$1),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: .14,
                                              ),
                                        border: Border.all(
                                          color: selected
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: .22,
                                                ),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(type.$3, color: color, size: 24),
                                          const SizedBox(height: 6),
                                          Text(
                                            type.$2,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              key: const ValueKey('sos-countdown-actions'),
              padding: EdgeInsets.fromLTRB(g, 12, g, 24),
              child: _readable(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _send,
                      style: _onRedFilled(),
                      icon: const Icon(Icons.send, size: 20),
                      label: const Text('Enviar ya'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _cancel,
                      style: _onRedOutline(),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text(
                        'Cancelar, fue un error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// --- SOS Sent Screen ---
class SosSentScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const SosSentScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final off = state.offline;
    final typeLabel =
        {
          'salud': 'Salud',
          'fuego': 'Incendio',
          'robo': 'Robo',
          'sismo': 'Sismo',
          'violencia': 'Violencia',
          'otro': 'Otro',
        }[state.sosType] ??
        'General';

    if (off && state.lastCode == null) {
      final gps = state.location.last;
      state.lastCode = compressSOS(
        cat: state.sosType ?? 'otro',
        loc: state.publishWhere,
        prio: 'alta',
        lat: gps != null && gps.real ? gps.lat : null,
        lng: gps != null && gps.real ? gps.lng : null,
      );
    }

    // Con sesión: lo que respondió el backend (POST /sos y GET /sos/{id}).
    final live = state.connected;
    final r = state.sosResult;
    int n(String k) => (r?[k] as num?)?.toInt() ?? 0;
    final neighborsTitle = !live
        ? '32 vecinos alertados'
        : r == null
        ? 'Enviando tu alerta…'
        : '${n('notifiedNeighbors')} vecinos alertados';
    final contactNames = state.contacts
        .map(
          (id) => state.contactBook.where((c) => c.id == id).firstOrNull?.name,
        )
        .whereType<String>()
        .join(', ');
    final contactsTitle = !live
        ? '3 contactos ven tu ubicación'
        : '${r == null ? state.contacts.length : n('contactsNotified')} contactos ven tu ubicación';
    final contactsSub = !live
        ? 'Mamá, Carlos, Sra. Rosa'
        : (contactNames.isEmpty
              ? 'Agrega contactos en tu perfil'
              : contactNames);
    final brigadeSub = !live
        ? '12 brigadistas'
        : r == null
        ? 'Avisando…'
        : '${n('brigadeNotified')} brigadistas';
    final responders = ((state.sosDetail?['responders'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .where((x) => x['status'] != 'DECLINED')
        .toList();

    final check = Icon(Icons.check_circle, color: theme.primary, size: 20);

    final statusRows = off
        ? [
            _statusRow(
              icon: Icons.sms,
              color: ui.ink,
              softColor: ui.blueSoft,
              title: !live
                  ? 'SMS enviado a 3 contactos y a la brigada'
                  : state.contacts.isEmpty
                  ? 'Código SMS listo para la brigada'
                  : 'Código SMS listo para tus ${state.contacts.length} contactos',
              subtitle:
                  'Sin internet: código comprimido de ${state.lastCode?.length ?? 22} caracteres',
              trailing: check,
            ),
            _statusRow(
              icon: Icons.graphic_eq,
              color: ui.ink,
              softColor: ui.blueSoft,
              title: 'Puente de sonido listo',
              subtitle: 'Pasa el código a celulares cercanos sin señal',
              trailing: check,
            ),
            _statusRow(
              icon: Icons.sync,
              color: theme.accentInk,
              softColor: theme.accentSoft,
              title: 'Alerta completa en cola',
              subtitle: 'Se envía apenas vuelva la señal',
              trailing: Icon(Icons.schedule, color: theme.accentInk, size: 20),
            ),
          ]
        : [
            _statusRow(
              icon: Icons.groups,
              color: theme.sos,
              softColor: theme.sosSoft,
              title: neighborsTitle,
              subtitle: 'En un radio de 500 m',
              trailing: check,
            ),
            _statusRow(
              icon: Icons.share_location,
              color: ui.ink,
              softColor: ui.blueSoft,
              title: contactsTitle,
              subtitle: contactsSub,
              trailing: check,
            ),
            _statusRow(
              icon: Icons.medical_services,
              color: ui.ink,
              softColor: ui.blueSoft,
              title: live
                  ? 'Brigada de tu zona notificada'
                  : 'Brigada Zona 3 notificada',
              subtitle: brigadeSub,
              trailing: check,
            ),
          ];

    final onTheWayRows = live
        ? [
            if (responders.isEmpty)
              _statusRow(
                icon: Icons.hourglass_top,
                color: ui.ink,
                softColor: ui.blueSoft,
                title: 'Esperando a tus vecinos',
                subtitle: 'Te avisamos apenas alguien vaya en camino',
                trailing: Icon(Icons.schedule, color: ui.muted, size: 20),
              ),
            for (final x in responders)
              _statusRow(
                icon: Icons.person,
                color: ui.ink,
                softColor: ui.blueSoft,
                title: x['status'] == 'ARRIVED'
                    ? '${x['name'] ?? 'Un vecino'} llegó'
                    : '${x['name'] ?? 'Un vecino'} va en camino',
                // Solo distancia y tiempo si el backend los dio
                subtitle: [
                  if (x['distanceM'] != null) 'A ${x['distanceM']} m',
                  if (x['etaMinutes'] != null)
                    'llega en ${x['etaMinutes']} min',
                ].join(' · '),
                trailing: Icon(
                  Icons.directions_walk,
                  color: theme.primary,
                  size: 20,
                ),
              ),
          ]
        : [
            _statusRow(
              icon: Icons.person,
              color: ui.ink,
              softColor: ui.blueSoft,
              title: 'Rosa Flores va en camino',
              subtitle: 'A 150 m · llega en 2 min',
              trailing: Icon(
                Icons.directions_walk,
                color: theme.primary,
                size: 20,
              ),
            ),
            _statusRow(
              icon: Icons.medical_services,
              color: theme.sos,
              softColor: theme.sosSoft,
              title: 'Brigada de primeros auxilios',
              subtitle: 'Llega en 5 min',
              trailing: Icon(
                Icons.directions_run,
                color: theme.primary,
                size: 20,
              ),
            ),
          ];

    return LayoutBuilder(
      builder: (context, bounds) {
        final g = _gutter(bounds.maxWidth);
        return ListView(
          key: const ValueKey('sos-sent-scroll'),
          padding: EdgeInsets.zero,
          children: [
            // Cabecera roja o sigilosa
            Container(
              key: const ValueKey('sos-sent-header'),
              color: state.isSilentMode
                  ? const Color(0xFF0F172A)
                  : NearbyColors.sos,
              padding: EdgeInsets.fromLTRB(g, 12, g, 32),
              child: _readable(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          state.connected ? state.nowTime() : '10:47',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: state.isSilentMode
                            ? Colors.white12
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isSilentMode
                            ? Icons.security
                            : Icons.check,
                        color: state.isSilentMode
                            ? Colors.amber
                            : NearbyColors.sos,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.isSilentMode
                          ? 'Alerta sigilosa enviada'
                          : 'Alerta enviada',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isSilentMode
                          ? 'Tipo: $typeLabel · Llamadas VoIP y sonidos bloqueados'
                          : (state.connected
                              ? 'Tipo: $typeLabel · tu ubicación actual'
                              : 'Tipo: $typeLabel · ${state.publishWhere}'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Detalle sobre página blanca
            Container(
              key: const ValueKey('sos-sent-details'),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(g, 20, g, 32),
                child: _readable(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.isSilentMode) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.volume_off,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Modo Sigiloso Activo',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tu alerta fue enviada en silencio y el brillo está al mínimo. Para protegerte, las llamadas VoIP entrantes se rechazan automáticamente para que tu teléfono no suene.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => state.go('mensajes'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Abrir Chat Silencioso',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _listCard(statusRows),
                      const SizedBox(height: 12),

                      // Sin internet: tarjeta del código
                      if (off && state.lastCode != null) ...[
                        _buildCodeCard(state.lastCode!),
                        const SizedBox(height: 12),
                      ] else ...[
                        // Quién va en camino
                        _listCard(onTheWayRows),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 8),
                      Text(
                        'Llamar a emergencias',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ui.ink,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CallGrid(state: state, theme: theme),

                      const SizedBox(height: 20),
                      if (!state.isSilentMode) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            if (SoundService.instance.isSosAlarming) {
                              unawaited(SoundService.instance.stopSosAlarm());
                              state.toast('Sirena silenciada', icon: 'volume_off');
                            } else {
                              unawaited(SoundService.instance.playSosAlarm());
                              state.toast('Sirena activada', icon: 'volume_up');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SoundService.instance.isSosAlarming ? NearbyColors.sos : ui.ink,
                            side: BorderSide(
                              color: SoundService.instance.isSosAlarming ? NearbyColors.sos : ui.line,
                              width: 1.5,
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: Icon(
                            SoundService.instance.isSosAlarming ? Icons.volume_off : Icons.volume_up,
                            size: 20,
                          ),
                          label: Text(
                            SoundService.instance.isSosAlarming
                                ? 'Silenciar sirena SOS'
                                : 'Activar sonido de sirena',
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (!state.emergency) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            unawaited(SoundService.instance.stopSosAlarm());
                            state.activateLocalEmergency();
                            state.go('home', reset: true);
                            state.toast(
                              'Modo emergencia activado en tu app',
                              icon: 'crisis_alert',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.sos,
                            side: BorderSide(color: theme.sos, width: 1.5),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.crisis_alert, size: 20),
                          label: const Text('Activar modo emergencia'),
                        ),
                        const SizedBox(height: 10),
                      ],

                      ElevatedButton.icon(
                        onPressed: () async {
                          // Cerrar un SOS activo pide huella, rostro o PIN: nadie más puede apagar tu alerta.
                          if (!await state.confirmIdentity(
                            'Confirma que estás a salvo para cerrar la alerta',
                          )) {
                            return;
                          }
                          await SoundService.instance.stopSosAlarm();
                          unawaited(SoundService.instance.stopAll());
                          await state.sosSafe();
                          state.go('home', reset: true);
                          state.toast(
                            'Avisamos a todos que estás a salvo',
                            icon: 'verified_user',
                          );
                        },
                        style: _primary(ui),
                        icon: const Icon(Icons.verified_user, size: 20),
                        label: const Text('Estoy a salvo · cerrar alerta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tarjeta con borde y filas separadas por líneas finas.
  Widget _listCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: ui.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: ui.line, indent: 12, endIndent: 12),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required Color color,
    required Color softColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _iconSquare(icon, bg: softColor, fg: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ui.ink,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: ui.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _buildCodeCard(String code) {
    return Container(
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
              Icon(Icons.auto_awesome, color: ui.ink, size: 18),
              const SizedBox(width: 8),
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
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: NearbyColors.darkNavy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: NearbyColors.darkPrimaryDark,
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
                  onPressed: () => state.openSheet('sonic'),
                  style: ui.action(),
                  icon: const Icon(Icons.graphic_eq, size: 16),
                  label: const Text('Enviar por sonido'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    state.decoded = false;
                    state.lastCode = code;
                    state.go('puente');
                  },
                  style: ui.action(filled: false),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver brigadista'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Alerta Recibida de un Vecino ---
class AlertaRecibidaScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const AlertaRecibidaScreen({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  State<AlertaRecibidaScreen> createState() => _AlertaRecibidaScreenState();
}

class _AlertaRecibidaScreenState extends State<AlertaRecibidaScreen> {
  static const _typeLabels = {
    'HEALTH': 'Salud',
    'FIRE': 'Incendio',
    'ROBBERY': 'Robo',
    'EARTHQUAKE': 'Sismo',
    'VIOLENCE': 'Violencia',
    'OTHER': 'Emergencia',
  };

  bool _alarmMuted = false;

  @override
  void initState() {
    super.initState();
    unawaited(SoundService.instance.playSosAlarm());
  }

  @override
  void dispose() {
    unawaited(SoundService.instance.stopSosAlarm());
    super.dispose();
  }

  void _toggleAlarm() {
    setState(() => _alarmMuted = !_alarmMuted);
    if (_alarmMuted) {
      unawaited(SoundService.instance.stopSosAlarm());
    } else {
      unawaited(SoundService.instance.playSosAlarm());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // Con sesión solo mostramos lo que llegó del backend; sin datos, textos neutros.
    final live = state.connected;
    final sos = live ? state.incomingSos : null;
    final named = sos?['userName'] as String?;
    final who = named ?? (live ? 'Un vecino' : 'Rosa Flores');
    final initials = live && named == null
        ? ''
        : who
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();
    final type = sos == null
        ? (live ? 'Emergencia' : 'Salud')
        : (_typeLabels[sos['type']] ?? 'Emergencia');
    final distM = (sos?['distanceM'] as num?)?.toInt();
    final String? dist = !live
        ? 'a 150 m'
        : (distM == null ? null : 'a $distM m');
    final minutes = (sos?['minutesAgo'] as num?)?.toInt();
    final String? ago = !live
        ? 'hace 1 min'
        : (minutes == null
              ? null
              : (minutes < 1 ? 'ahora' : 'hace $minutes min'));
    final going = (sos?['goingCount'] as num?)?.toInt() ?? 0;
    final detail = !live
        ? 'Jr. Los Pinos 210 · ubicación en vivo. 31 vecinos más recibieron esta alerta; 2 ya van en camino.'
        : sos == null
        ? 'Ubicación aproximada para proteger su privacidad.'
        : 'Ubicación aproximada para proteger su privacidad. ${going == 0 ? 'Nadie va todavía: tu ayuda cuenta.' : '$going ${going == 1 ? 'vecino ya va' : 'vecinos ya van'} en camino.'}';
    final destLat = sos?['approxLat'] as num?;
    final destLng = sos?['approxLng'] as num?;
    return Container(
      color: NearbyColors.sos,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final g = _gutter(bounds.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(g, 20, g, 24),
              child: _readable(
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (bounds.maxHeight - 44).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.crisis_alert,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'ALERTA DE UN VECINO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _toggleAlarm,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: _alarmMuted ? 0.35 : 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _alarmMuted
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _alarmMuted ? 'Silenciado' : 'Sirena activa',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Avatar con halo
                        Center(
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: initials.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: NearbyColors.sosDark,
                                      size: 48,
                                    )
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                        color: NearbyColors.sosDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          '$who necesita ayuda',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Etiquetas
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            _chip(Icons.medical_services, type),
                            if (dist != null) _chip(Icons.near_me, dist),
                            if (ago != null) _chip(Icons.schedule, ago),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text(
                          detail,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Spacer(),

                        ElevatedButton.icon(
                          onPressed: () {
                            unawaited(SoundService.instance.stopSosAlarm());
                            state.respondSos(true);
                            state.routeTo = {
                              'title': live
                                  ? '$who · $type'
                                  : 'Rosa Flores · Jr. Los Pinos 210',
                              if (live) 'sub': 'Ubicación aproximada',
                              // Coordenadas aproximadas del SOS (GET /sos/nearby)
                              if (destLat != null && destLng != null) ...{
                                'lat': destLat.toDouble(),
                                'lng': destLng.toDouble(),
                              },
                              'icon': Icons.emergency,
                              'kind': 'help',
                            };
                            state.go('ruta', reset: true);
                            state.toast(
                              initials.isEmpty
                                  ? 'Avisamos que vas en camino'
                                  : '${who.split(' ').first} y la brigada saben que vas en camino',
                              icon: 'directions_run',
                            );
                          },
                          style: _onRedFilled(),
                          icon: const Icon(Icons.directions_run, size: 22),
                          label: const Text('Voy a ayudar'),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  unawaited(SoundService.instance.stopSosAlarm());
                                  state.startCall('106');
                                },
                                style: _onRedOutline(),
                                icon: const Icon(
                                  Icons.medical_services,
                                  size: 18,
                                ),
                                label: const Text('Llamar al 106'),
                              ),
                            ),
                            // Sin nombre real no hay a quién llamar
                            if (initials.isNotEmpty) const SizedBox(width: 8),
                            if (initials.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    unawaited(SoundService.instance.stopSosAlarm());
                                    state.startCall(who);
                                  },
                                  style: _onRedOutline(),
                                  icon: const Icon(Icons.call, size: 18),
                                  label: Text(
                                    'Llamar a ${who.split(' ').first}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              unawaited(SoundService.instance.stopSosAlarm());
                              state.respondSos(false);
                              state.go('home', reset: true);
                              state.toast(
                                'Entendido. Avisamos a otros vecinos cercanos.',
                                icon: 'groups',
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text(
                              'No puedo ahora',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
