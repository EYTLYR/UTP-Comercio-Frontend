import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../screens/roles_screens.dart';
import 'nearby_logo.dart';
import 'zone_picker.dart';

// --- Animated SOS Hold Button ---
class SosHoldButton extends StatefulWidget {
  final double size;
  final bool isLarge;
  final VoidCallback onComplete;
  final VoidCallback? onCancelShort;

  const SosHoldButton({
    super.key,
    this.size = 148,
    this.isLarge = false,
    required this.onComplete,
    this.onCancelShort,
  });

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulse;
  bool _isHolding = false;
  int? _holdingPointer;
  Offset? _pointerOrigin;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isHolding = false);
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDown() {
    setState(() => _isHolding = true);
    _controller.forward(from: 0.0);
  }

  void _onUp() {
    if (_controller.status != AnimationStatus.completed) {
      final wasActive = _isHolding;
      setState(() => _isHolding = false);
      _controller.reset();
      if (wasActive) {
        widget.onCancelShort?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_holdingPointer != null || event.buttons != 1) return;
        _holdingPointer = event.pointer;
        _pointerOrigin = event.position;
        _onDown();
      },
      onPointerMove: (event) {
        if (event.pointer == _holdingPointer &&
            (event.position - _pointerOrigin!).distance > 18) {
          _holdingPointer = null;
          _onUp();
        }
      },
      onPointerUp: (event) {
        if (event.pointer != _holdingPointer) return;
        _holdingPointer = null;
        _onUp();
      },
      onPointerCancel: (event) {
        if (event.pointer != _holdingPointer) return;
        _holdingPointer = null;
        _onUp();
      },
      child: AnimatedScale(
        scale: _isHolding ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _pulse]),
            builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (!_isHolding && !MediaQuery.disableAnimationsOf(context))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: 0.96 + _pulse.value * 0.22,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: (1 - _pulse.value) * 0.4,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      startAngle: 0,
                      endAngle: math.pi * 2,
                      transform: const GradientRotation(-math.pi / 2),
                      colors: const [Colors.white, Color(0x42FFFFFF)],
                      stops: [_controller.value, _controller.value],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: _isHolding ? 0.6 : 0.25,
                        ),
                        blurRadius: 18,
                        spreadRadius: _isHolding ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x15000000),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SOS',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            fontSize: widget.isLarge ? 54 : 36,
                            color: NearbyColors.sos,
                            letterSpacing: 1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'MANTENER',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: widget.isLarge ? 13 : 11,
                            color: NearbyColors.sosDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
    );
  }
}

// --- Top Bar ---
class NearbyTopBar extends StatelessWidget {
  final NearbyThemeData theme;
  final AppState state;

  const NearbyTopBar({super.key, required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final em = state.emergency;
    final topBarBg = em ? NearbyColors.navy : Colors.transparent;

    return Container(
      color: topBarBg,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          // Brandmark logo
          PressableScale(
            onTap: () => state.selectTab('home'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: em
                    ? Colors.white.withValues(alpha: 0.08)
                    : theme.surface,
                border: Border.all(
                  color: em ? Colors.white.withValues(alpha: 0.16) : theme.line,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: em ? null : theme.cardShadow,
              ),
              child: Center(
                child: NearbyLogo(
                  width: 28,
                  inkColor: em ? Colors.white : theme.logoInk,
                  gapColor: em ? NearbyColors.navy : theme.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Zone badge
          Expanded(
            child: PressableScale(
              key: const ValueKey('zone-map'),
              onTap: () {
                state.selectTab('mapa');
                showZonePicker(context, state, theme);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: em
                      ? Colors.white.withValues(alpha: 0.08)
                      : theme.surface,
                  border: Border.all(
                    color: em
                        ? Colors.white.withValues(alpha: 0.16)
                        : theme.line,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: em ? null : theme.cardShadow,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: em ? const Color(0xFFFF8A98) : theme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.visibleZoneName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: em ? Colors.white : theme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Mini SOS button (when not on home)
          if (state.screen != 'home') ...[
            PressableScale(
              onTap: () => state.go('sos'),
              scale: 0.94,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: NearbyColors.sos,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66D7263D),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Mensajes (con los no leídos)
          if (state.connected) ...[
            PressableScale(
              onTap: () => state.go('mensajes'),
              scale: 0.94,
              child: Tooltip(
                message: 'Mensajes',
                child: Badge(
                  isLabelVisible: state.unreadMessages > 0,
                  label: Text('${state.unreadMessages}'),
                  backgroundColor: NearbyColors.sos,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.line),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: theme.ink,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Avatar del vecino
          PressableScale(
            key: state.tourTarget('profile'),
            onTap: () => state.go('perfil'),
            child: ProfilePhotoAvatar(state: state, size: 42),
          ),
        ],
      ),
    );
  }
}

// --- Top Bar Back ---
class NearbyTopBarBack extends StatelessWidget {
  final NearbyThemeData theme;
  final AppState state;
  final String title;
  final bool emergencyStyle;

  const NearbyTopBarBack({
    super.key,
    required this.theme,
    required this.state,
    required this.title,
    this.emergencyStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          PressableScale(
            key: state.tourTarget('back'),
            onTap: () => state.back(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: emergencyStyle
                    ? Colors.white.withValues(alpha: .08)
                    : theme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: emergencyStyle
                      ? Colors.white.withValues(alpha: .2)
                      : theme.line,
                ),
                boxShadow: emergencyStyle ? null : theme.cardShadow,
              ),
              child: Icon(
                Icons.arrow_back,
                color: emergencyStyle ? Colors.white : theme.ink,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: emergencyStyle ? Colors.white : theme.ink,
              ),
            ),
          ),
          PressableScale(
            onTap: () => state.go('sos'),
            scale: 0.94,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: NearbyColors.sos,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66D7263D),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 17),
                  SizedBox(width: 4),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Emergency Banner ---
class NearbyEmergencyBanner extends StatelessWidget {
  final AppState state;

  const NearbyEmergencyBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: state.tourTarget('em-banner'),
      onTap: () => state.openSheet('em'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: const BoxDecoration(
          color: NearbyColors.navy,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NearbyColors.sos,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.crisis_alert,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modo emergencia activo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    state.emSource == 'yo'
                        ? 'Activado por ti · toca para opciones'
                        : state.connected
                        ? 'Activado por la Municipalidad · toca para opciones'
                        : 'Sismo en Lima · desde las 10:42 · toca para opciones',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (state.isBrigade)
              ElevatedButton(
                onPressed: () => state.go('tablero'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: NearbyColors.sosDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Tablero',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Offline Banner ---
class NearbyOfflineBanner extends StatelessWidget {
  final AppState state;

  const NearbyOfflineBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NearbyColors.brandNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Color(0xFFF6C35B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontFamily: 'Poppins',
                ),
                children: [
                  const TextSpan(
                    text: 'Sin conexión. ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text:
                        'La app sigue funcionando${state.pending > 0 ? " · ${state.pending} envío(s) pendiente(s)" : ""}. El SOS se envía por SMS.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Bottom Navigation ---
class NearbyBottomNav extends StatelessWidget {
  final NearbyThemeData theme;
  final AppState state;

  const NearbyBottomNav({super.key, required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final em = state.emergency;
    final tabs = em
        ? [
            _NavTab('home', Icons.home, 'Inicio'),
            _NavTab('apoyo', Icons.diversity_3, 'Apoyo'),
            _NavTab('publicar', Icons.add, 'Reportar', isFab: true),
            _NavTab('recursos', Icons.inventory_2, 'Recursos'),
            _NavTab('mapa', Icons.map, 'Mapa'),
          ]
        : [
            _NavTab('home', Icons.home, 'Inicio'),
            _NavTab('servicios', Icons.handyman, 'Servicios'),
            _NavTab('publicar', Icons.add, 'Publicar', isFab: true),
            _NavTab('muro', Icons.volunteer_activism, 'Muro'),
            _NavTab('mapa', Icons.map, 'Mapa'),
          ];

    final cur = _currentTab(state.screen);

    final activeColor = em ? theme.sosDark : theme.primaryDark;
    final fabColor = theme.hc
        ? theme.btnBg
        : (em ? theme.sos : NearbyColors.brandTurquoise);
    final fabInk = theme.hc
        ? theme.btnInk
        : (em ? Colors.white : NearbyColors.onPrimary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: tabs.map((tab) {
            final selected = cur == tab.id && !tab.isFab;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                child: PressableScale(
                  key: state.tourTarget('nav-${tab.id}'),
                  onTap: () => state.selectTab(tab.id),
                  scale: tab.isFab ? 0.92 : 0.96,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tab.isFab)
                          Container(
                            key: const ValueKey('publish-floating-button'),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: fabColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.bg, width: 5),
                              boxShadow: [
                                BoxShadow(
                                  color: fabColor.withValues(alpha: 0.32),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: fabInk,
                              size: 32,
                            ),
                          )
                        else
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? (em ? theme.sosSoft : theme.primarySoft)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              tab.icon,
                              color: selected ? activeColor : theme.muted,
                              size: 23,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected || tab.isFab
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected ? activeColor : theme.muted,
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
    );
  }

  String _currentTab(String screen) {
    switch (screen) {
      case 'home':
      case 'tablero':
        return 'home';
      case 'servicios':
      case 'svc':
        return 'servicios';
      case 'apoyo':
        return 'apoyo';
      case 'muro':
        return 'muro';
      case 'recursos':
        return 'recursos';
      case 'mapa':
        return 'mapa';
      case 'publicar':
        return 'publicar';
      default:
        return '';
    }
  }
}

class _NavTab {
  final String id;
  final IconData icon;
  final String label;
  final bool isFab;

  _NavTab(this.id, this.icon, this.label, {this.isFab = false});
}

// --- Home SOS Card ---
class NearbySosCard extends StatelessWidget {
  final NearbyThemeData theme;
  final AppState state;

  const NearbySosCard({super.key, required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.3,
          colors: [Color(0xFFEE4A5E), Color(0xFFD7263D), Color(0xFFAE172C)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66D7263D),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Estás en peligro?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Mantén presionado el botón 2 segundos',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Center hold button
          SosHoldButton(
            key: state.tourTarget('sos'),
            size: 148,
            onComplete: () {
              if (state.tourName != null) {
                state.toast(
                  '¡Muy bien! Así se envía una alerta. En el tutorial no se envía nada.',
                  icon: 'verified',
                );
                state.checkTourEvent('sos-hold');
              } else {
                state.sosType = null;
                state.go('sos-countdown');
              }
            },
            onCancelShort: () {
              state.toast(
                'Mantén presionado 2 segundos para enviar la alerta',
                icon: 'touch_app',
              );
            },
          ),

          const SizedBox(height: 12),
          const Text(
            'Avisa a vecinos en 500 m, a tus contactos y a la brigada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Equal cells preserve the prototype's three-column layout.
          EmergencyCallShortcuts(state: state),
        ],
      ),
    );
  }
}

/// Same size for all three shortcuts; stack content together when scaled text
/// cannot fit beside the icon, rather than breaking a service name mid-word.
class EmergencyCallShortcuts extends StatelessWidget {
  final AppState state;
  const EmergencyCallShortcuts({super.key, required this.state});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final calls = kCalls.take(3).toList();
      final width = (bounds.maxWidth - 16) / 3;
      const labelStyle = TextStyle(
        color: Colors.white70,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      );
      final stacked = calls.any((call) {
        final painter = TextPainter(
          text: TextSpan(
            text: call.label,
            style: DefaultTextStyle.of(context).style.merge(labelStyle),
          ),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        final needsSpace = painter.width > width - 46;
        painter.dispose();
        return needsSpace;
      });
      return IntrinsicHeight(
        child: Row(
          key: state.tourTarget('calls'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < calls.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: 'Llamar a ${calls[i].label}, ${calls[i].num}',
                  child: InkWell(
                    onTap: () => state.startCall(calls[i].num),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      key: ValueKey('sos-call-${calls[i].num}'),
                      constraints: const BoxConstraints(minHeight: 50),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .28),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: stacked
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  calls[i].icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                _details(calls[i], labelStyle, true),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(
                                  calls[i].icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _details(calls[i], labelStyle, false),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
  Widget _details(CallItem call, TextStyle labelStyle, bool centered) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Text(
        call.num,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
          height: 1.1,
        ),
      ),
      Text(
        call.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: labelStyle,
      ),
    ],
  );
}

// --- Emil Kowalski Tactile Pressable Scale ---
/// Adds subtle scale(0.97) feedback on press with ease-out timing.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: const Cubic(0.23, 1.0, 0.32, 1.0),
        child: widget.child,
      ),
    );
  }
}

// --- Emil Kowalski Staggered Entrance Animation ---
/// Staggers items cascading into the view with subtle translation (8px),
/// starting scale (0.96 -> 1.0) and opacity (0 -> 1) within 240ms.
/// Respects accessibility / prefers-reduced-motion.
class StaggeredEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final int delayMs;
  final Duration duration;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayMs = 40,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: (index * delayMs).clamp(0, 320)),
      curve: const Cubic(0.23, 1.0, 0.32, 1.0),
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 8),
            child: Transform.scale(
              scale: 0.96 + (value * 0.04),
              child: childWidget,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// --- Floating Toast Message ---
class NearbyToastWidget extends StatefulWidget {
  final String message;
  final String? icon;
  final VoidCallback? onDismiss;
  const NearbyToastWidget({
    super.key,
    required this.message,
    this.icon,
    this.onDismiss,
  });
  @override
  State<NearbyToastWidget> createState() => _NearbyToastWidgetState();
}

class _NearbyToastWidgetState extends State<NearbyToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: AppState.toastDuration,
  )..forward();
  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  static const _icons = <String, IconData>{
    'sms': Icons.sms,
    'verified': Icons.verified,
    'verified_user': Icons.verified,
    'crisis_alert': Icons.crisis_alert,
    'flood': Icons.flood,
    'shield_person': Icons.shield,
    'close': Icons.close,
    'cloud_off': Icons.cloud_off,
    'cloud_done': Icons.cloud_done,
    'auto_awesome': Icons.auto_awesome,
    'touch_app': Icons.touch_app,
    'celebration': Icons.celebration,
    'error': Icons.error,
    'lock': Icons.lock,
    'info': Icons.info,
    'location_on': Icons.location_on,
    'campaign': Icons.campaign,
    'waving_hand': Icons.waving_hand,
    'logout': Icons.logout,
    'delete': Icons.delete,
    'cancel': Icons.cancel,
    'groups': Icons.groups,
    'person_add': Icons.person_add,
    'directions_run': Icons.directions_run,
    'notifications_active': Icons.notifications_active,
    'add_location': Icons.add_location,
    'check_circle': Icons.check_circle,
    'warning': Icons.warning_amber,
  };
  @override
  Widget build(BuildContext context) => Positioned(
    left: 12,
    right: 12,
    bottom: 12,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: const Cubic(0.23, 1.0, 0.32, 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: Dismissible(
          key: ValueKey(widget.message),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismiss?.call(),
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0).abs() > 150) {
                widget.onDismiss?.call();
              }
            },
            child: Material(
              color: const Color(0xFF0B2D6B),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              elevation: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        Icon(
                          _icons[widget.icon] ?? Icons.info_outline,
                          color: const Color(0xFF00BFA6),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onDismiss,
                          tooltip: 'Cerrar aviso',
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _timer,
                    builder: (_, _) => LinearProgressIndicator(
                      value: 1 - _timer.value,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFF00BFA6),
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
