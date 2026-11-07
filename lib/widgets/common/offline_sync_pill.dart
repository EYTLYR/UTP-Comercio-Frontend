import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../state/app_state.dart';
import 'nearby_pressable.dart';

/// Dynamic Island style floating status pill.
/// Monitors the network connection, SQLite outbox queue, and real-time synchronization.
/// Uses AnimatedSwitcher and AnimatedContainer for fluid transitions without layout shifts.
class OfflineSyncPill extends StatefulWidget {
  final AppState state;
  final VoidCallback? onTap;

  const OfflineSyncPill({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  State<OfflineSyncPill> createState() => _OfflineSyncPillState();
}

class _OfflineSyncPillState extends State<OfflineSyncPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isOffline = state.offline || !state.connected;
    final totalPending = state.pending;

    // Sincronizando activamente
    final isSyncing = state.busy && !isOffline;

    if (isSyncing) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
    } else {
      if (_spinCtrl.isAnimating) _spinCtrl.stop();
    }

    // Determine state visual parameters
    late final Color bgColor;
    late final Color textColor;
    late final IconData iconData;
    late final String label;
    late final bool showPill;

    if (isOffline) {
      bgColor = const Color(0xFF1E293B);
      textColor = const Color(0xFFF59E0B);
      iconData = Icons.cloud_off_rounded;
      label = totalPending > 0
          ? 'Sin señal · $totalPending en cola'
          : 'Modo sin conexión';
      showPill = true;
    } else if (totalPending > 0) {
      bgColor = const Color(0xFF15233A);
      textColor = const Color(0xFF38BDF8);
      iconData = Icons.sync_rounded;
      label = isSyncing
          ? 'Sincronizando $totalPending evento(s)...'
          : '$totalPending envío(s) pendiente(s)';
      showPill = true;
    } else if (isSyncing) {
      bgColor = const Color(0xFF15233A);
      textColor = const Color(0xFF34D399);
      iconData = Icons.sync_rounded;
      label = 'Sincronizando...';
      showPill = true;
    } else {
      // Estado normal sincronizado: mostrar cápsula discreta o permitir ocultarse
      showPill = false;
      bgColor = Colors.transparent;
      textColor = Colors.transparent;
      iconData = Icons.check_circle_outline;
      label = '';
    }

    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: AppMotion.enterInitialScale,
                end: 1.0,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: !showPill
          ? const SizedBox.shrink(key: ValueKey('pill-hidden'))
          : NearbyPressable(
              key: ValueKey('pill-$label'),
              onTap: widget.onTap ??
                  () {
                    state.flushPendingNow();
                  },
              scale: 0.96,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space14,
                  vertical: AppTokens.space6,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: textColor.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: AppTokens.softShadow(
                    tint: Colors.black,
                    opacity: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSyncing)
                      RotationTransition(
                        turns: _spinCtrl,
                        child: Icon(iconData, color: textColor, size: 15),
                      )
                    else
                      Icon(iconData, color: textColor, size: 15),
                    const SizedBox(width: AppTokens.space6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

