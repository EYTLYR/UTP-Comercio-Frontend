import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/common_widgets.dart';
import 'emergency/widgets/sos_countdown_button.dart';

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
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 34,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar + Header
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
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  state.offline ? Icons.sms : Icons.my_location,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.offline ? 'Modo SMS' : 'Ubicación lista',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Emergencia',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mantén presionado el botón 2 segundos.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Big Center Hold Button
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

                    const SizedBox(height: 18),

                    // Info pills
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

                    const SizedBox(height: 18),

                    // Direct Emergency Call Buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'O llama directo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.45,
                          children: kCalls.map((c) {
                            return PressableScale(
                              scale: 0.96,
                              onTap: () => state.startCall(c.num),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: theme.sosSoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        c.icon,
                                        color: NearbyColors.sos,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            c.num,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: theme.ink,
                                              height: 1.1,
                                            ),
                                          ),
                                          Text(
                                            c.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: theme.muted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
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
  Timer? _deadline;
  static const types = [
    ('salud', 'Salud', Icons.medical_services),
    ('fuego', 'Incendio', Icons.local_fire_department),
    ('robo', 'Robo', Icons.local_police),
    ('sismo', 'Sismo', Icons.house),
    ('violencia', 'Violencia', Icons.front_hand),
    ('otro', 'Otro', Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    _countdown =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _send();
          })
          ..forward();
    _deadline = Timer(const Duration(seconds: 5), _send);
  }

  void _send() {
    if (_sent) return;
    _sent = true;
    _deadline?.cancel();
    _countdown.stop();
    widget.state.go('sos-sent');
    widget.state.sendSos();
  }

  @override
  void dispose() {
    _deadline?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: NearbyColors.sos,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              children: [
                const Text(
                  'Enviando alerta en',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                SosCountdownButton(
                  countdown: _countdown,
                  onCancel: () {
                    _deadline?.cancel();
                    _countdown.stop();
                    widget.state.back();
                  },
                  onComplete: _send,
                ),
                const SizedBox(height: 24),
                const Text(
                  '¿Qué está pasando? (opcional)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types.map((type) {
                      final selected = widget.state.sosType == type.$1;
                      final color = selected
                          ? NearbyColors.sosDark
                          : Colors.white;
                      return SizedBox(
                        width: (constraints.maxWidth - 16) / 3,
                        child: Semantics(
                          button: true,
                          selected: selected,
                          child: InkWell(
                            onTap: () =>
                                setState(() => widget.state.sosType = type.$1),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(type.$3, color: color, size: 26),
                                  const SizedBox(height: 6),
                                  Text(
                                    type.$2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          key: const ValueKey('sos-countdown-actions'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: NearbyColors.sosDark,
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send, size: 20),
                label: const Text(
                  'Enviar ya',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  _deadline?.cancel();
                  _countdown.stop();
                  widget.state.go('home', reset: true);
                  widget.state.toast(
                    'Alerta cancelada. No se envió nada.',
                    icon: 'cancel',
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 2),
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.close, size: 20),
                label: const Text(
                  'Cancelar, fue un error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// --- SOS Sent Screen ---
class SosSentScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

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

    return ListView(
      key: const ValueKey('sos-sent-scroll'),
      padding: EdgeInsets.zero,
      children: [
        // Red Top Header
        Container(
          key: const ValueKey('sos-sent-header'),
          color: NearbyColors.sos,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    state.connected ? state.nowTime() : '10:47',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: NearbyColors.sos,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Alerta enviada',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.connected
                    ? 'Tipo: $typeLabel · tu ubicación actual'
                    : 'Tipo: $typeLabel · ${state.publishWhere}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Body Content
        Container(
          key: const ValueKey('sos-sent-details'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: theme.line),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: theme.cardShadow,
                  ),
                  child: Column(
                    children: off
                        ? [
                            _statusRow(
                              icon: Icons.sms,
                              color: theme.primary,
                              softColor: theme.primarySoft,
                              title: !live
                                  ? 'SMS enviado a 3 contactos y a la brigada'
                                  : state.contacts.isEmpty
                                  ? 'Código SMS listo para la brigada'
                                  : 'Código SMS listo para tus ${state.contacts.length} contactos',
                              subtitle:
                                  'Sin internet: código comprimido de ${state.lastCode?.length ?? 22} caracteres',
                              trailing: Icon(
                                Icons.check_circle,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              icon: Icons.graphic_eq,
                              color: theme.violet,
                              softColor: theme.violetSoft,
                              title: 'Puente de sonido listo',
                              subtitle: 'Pasa el código a celulares cercanos sin señal',
                              trailing: Icon(
                                Icons.check_circle,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              icon: Icons.sync,
                              color: theme.accent,
                              softColor: theme.accentSoft,
                              title: 'Alerta completa en cola',
                              subtitle: 'Se envía apenas vuelva la señal',
                              trailing: Icon(
                                Icons.schedule,
                                color: theme.accentInk,
                              ),
                            ),
                          ]
                        : [
                            _statusRow(
                              icon: Icons.groups,
                              color: NearbyColors.sos,
                              softColor: theme.sosSoft,
                              title: neighborsTitle,
                              subtitle: 'En un radio de 500 m',
                              trailing: Icon(
                                Icons.check_circle,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              icon: Icons.share_location,
                              color: theme.info,
                              softColor: theme.infoSoft,
                              title: contactsTitle,
                              subtitle: contactsSub,
                              trailing: Icon(
                                Icons.check_circle,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              icon: Icons.medical_services,
                              color: theme.violet,
                              softColor: theme.violetSoft,
                              title: live
                                  ? 'Brigada de tu zona notificada'
                                  : 'Brigada Zona 3 notificada',
                              subtitle: brigadeSub,
                              trailing: Icon(
                                Icons.check_circle,
                                color: theme.primary,
                              ),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 12),

                // If offline: code card
                if (off && state.lastCode != null) ...[
                  _buildCodeCard(state.lastCode!),
                  const SizedBox(height: 12),
                ] else ...[
                  // En camino cards
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      border: Border.all(color: theme.line),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: theme.cardShadow,
                    ),
                    child: Column(
                      children: live
                          ? [
                              if (responders.isEmpty)
                                _statusRow(
                                  icon: Icons.hourglass_top,
                                  color: theme.violet,
                                  softColor: theme.violetSoft,
                                  title: 'Esperando a tus vecinos',
                                  subtitle: 'Te avisamos apenas alguien vaya en camino',
                                  trailing: Icon(
                                    Icons.schedule,
                                    color: theme.muted,
                                  ),
                                ),
                              for (final x in responders) ...[
                                _statusRow(
                                  icon: Icons.person,
                                  color: theme.violet,
                                  softColor: theme.violetSoft,
                                  title: x['status'] == 'ARRIVED'
                                      ? '${x['name'] ?? 'Un vecino'} llegó'
                                      : '${x['name'] ?? 'Un vecino'} va en camino',
                                  // Solo distancia y tiempo si el backend los dio
                                  subtitle: [
                                    if (x['distanceM'] != null)
                                      'A ${x['distanceM']} m',
                                    if (x['etaMinutes'] != null)
                                      'llega en ${x['etaMinutes']} min',
                                  ].join(' · '),
                                  trailing: Icon(
                                    Icons.directions_walk,
                                    color: theme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ]
                          : [
                              _statusRow(
                                icon: Icons.person,
                                color: theme.violet,
                                softColor: theme.violetSoft,
                                title: 'Rosa Flores va en camino',
                                subtitle: 'A 150 m · llega en 2 min',
                                trailing: Icon(
                                  Icons.directions_walk,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _statusRow(
                                icon: Icons.medical_services,
                                color: NearbyColors.sos,
                                softColor: theme.sosSoft,
                                title: 'Brigada de primeros auxilios',
                                subtitle: 'Llega en 5 min',
                                trailing: Icon(
                                  Icons.directions_run,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Text(
                  'Llamar a emergencias',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: MediaQuery.textScalerOf(context).scale(78),
                  children: kCalls.map((c) {
                    return InkWell(
                      onTap: () => state.startCall(c.num),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          border: Border.all(color: theme.line),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: theme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: theme.sosSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                c.icon,
                                color: NearbyColors.sos,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    c.num,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: theme.ink,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    c.label,
                                    style: TextStyle(
                                      color: theme.muted,
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
                  }).toList(),
                ),

                const SizedBox(height: 16),
                if (!state.emergency) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      state.activateLocalEmergency();
                      state.go('home', reset: true);
                      state.toast(
                        'Modo emergencia activado en tu app',
                        icon: 'crisis_alert',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NearbyColors.sos,
                      side: const BorderSide(
                        color: NearbyColors.sos,
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.crisis_alert, size: 20),
                    label: const Text(
                      'Activar modo emergencia',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
                    state.sosSafe();
                    state.go('home', reset: true);
                    state.toast(
                      'Avisamos a todos que estás a salvo',
                      icon: 'verified_user',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.btnBg,
                    foregroundColor: theme.btnInk,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.verified_user,
                    color: theme.primary,
                    size: 20,
                  ),
                  label: const Text(
                    'Estoy a salvo · cerrar alerta',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.ink,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
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
        border: Border.all(color: theme.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.violet, size: 18),
              const SizedBox(width: 6),
              Text(
                'Comprimido por IA para SMS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: theme.violet,
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
                  color: theme.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Cabe en 1 SMS',
                style: TextStyle(
                  color: theme.muted,
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
                  onPressed: () => state.openSheet('sonic'),
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
                    state.decoded = false;
                    state.lastCode = code;
                    state.go('puente');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.ink,
                    side: BorderSide(color: theme.line),
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
}

// --- Alerta Recibida de un Vecino ---
class AlertaRecibidaScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const AlertaRecibidaScreen({
    super.key,
    required this.state,
    required this.theme,
  });

  static const _typeLabels = {
    'HEALTH': 'Salud',
    'FIRE': 'Incendio',
    'ROBBERY': 'Robo',
    'EARTHQUAKE': 'Sismo',
    'VIOLENCE': 'Violencia',
    'OTHER': 'Emergencia',
  };

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.crisis_alert, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'ALERTA DE UN VECINO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Pulsing avatar circle
              Container(
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
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 22),

              Text(
                '$who necesita ayuda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // Chips
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: NearbyColors.sosDark,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.directions_run, size: 22),
                label: const Text(
                  'Voy a ayudar',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => state.startCall('106'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70, width: 2),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.medical_services, size: 18),
                      label: const Text(
                        'Llamar al 106',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  // Sin nombre real no hay a quién llamar
                  if (initials.isNotEmpty) const SizedBox(width: 8),
                  if (initials.isNotEmpty) Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => state.startCall(who),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70, width: 2),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: Text(
                        'Llamar a ${who.split(' ').first}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              TextButton(
                onPressed: () {
                  state.respondSos(false);
                  state.go('home', reset: true);
                  state.toast(
                    'Entendido. Avisamos a otros vecinos cercanos.',
                    icon: 'groups',
                  );
                },
                child: const Text(
                  'No puedo ahora',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
