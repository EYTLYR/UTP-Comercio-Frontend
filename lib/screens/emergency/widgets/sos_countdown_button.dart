import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/theme/app_tokens.dart';

/// Interactive SOS countdown button featuring:
/// - 5-second countdown with HapticFeedback.heavyImpact() triggered at every second tick
/// - Continuous concentric fluid ripple waves pulsing outwards
/// - Spring physics on touch/hold (scale feedback)
/// - High visibility circular progress ring and animated digits
class SosCountdownButton extends StatefulWidget {
  final Animation<double> countdown;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const SosCountdownButton({
    super.key,
    required this.countdown,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  State<SosCountdownButton> createState() => _SosCountdownButtonState();
}

class _SosCountdownButtonState extends State<SosCountdownButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  int _lastTickSecond = 5;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    widget.countdown.addListener(_checkHapticTick);
  }

  void _checkHapticTick() {
    final currentSecond = ((1 - widget.countdown.value) * 5).ceil().clamp(0, 5);
    if (currentSecond != _lastTickSecond && currentSecond > 0) {
      _lastTickSecond = currentSecond;
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    widget.countdown.removeListener(_checkHapticTick);
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabledAnimations = MediaQuery.disableAnimationsOf(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHolding = true),
      onTapUp: (_) => setState(() => _isHolding = false),
      onTapCancel: () => setState(() => _isHolding = false),
      child: AnimatedScale(
        scale: _isHolding ? 0.94 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric fluid ripple waves
              if (!disabledAnimations)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      final t = _waveController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Wave 1 (Outer)
                          Transform.scale(
                            scale: 0.9 + (t * 0.35),
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: (1.0 - t) * 0.35,
                                  ),
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                          // Wave 2 (Inner delayed)
                          Transform.scale(
                            scale: 0.85 + (((t + 0.5) % 1.0) * 0.3),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: (1.0 - ((t + 0.5) % 1.0)) * 0.45,
                                  ),
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Solid Circular Core
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Progress Ring
                    AnimatedBuilder(
                      animation: widget.countdown,
                      builder: (context, _) {
                        return SizedBox(
                          width: 162,
                          height: 162,
                          child: CircularProgressIndicator(
                            key: const ValueKey('sos-countdown-ring'),
                            value: (1.0 - widget.countdown.value).clamp(0.0, 1.0),
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.22),
                          ),
                        );
                      },
                    ),

                    // Animated Countdown Number
                    AnimatedBuilder(
                      animation: widget.countdown,
                      builder: (context, _) {
                        final seconds =
                            ((1 - widget.countdown.value) * 5).ceil().clamp(0, 5);
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) {
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: AppMotion.easeOut,
                                ),
                              ),
                              child: FadeTransition(opacity: anim, child: child),
                            );
                          },
                          child: Text(
                            '$seconds',
                            key: ValueKey<int>(seconds),
                            style: const TextStyle(
                              fontFamily: AppTokens.fontFamily,
                              color: Colors.white,
                              fontSize: 74,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

