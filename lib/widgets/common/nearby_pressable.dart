import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/app_motion.dart';

/// Universal tactile pressable wrapper implementing Emil Kowalski's
/// Design Engineering philosophy:
/// - Subtle scale(0.97) feedback on press
/// - Strong custom ease-out curve Cubic(0.23, 1, 0.32, 1)
/// - Sub-160ms snappy duration
/// - Light tactile haptic feedback (HapticFeedback.lightImpact)
class NearbyPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const NearbyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = AppMotion.pressScale,
    this.duration = AppMotion.fast,
    this.curve = AppMotion.easeOut,
    this.enableHaptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<NearbyPressable> createState() => _NearbyPressableState();
}

class _NearbyPressableState extends State<NearbyPressable> {
  bool _pressed = false;

  bool get _isInteractive => widget.onTap != null || widget.onLongPress != null;

  void _handleTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    setState(() => _pressed = true);
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    setState(() => _pressed = false);
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final disabledAnimations = MediaQuery.disableAnimationsOf(context);

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: (_pressed && !disabledAnimations) ? widget.scale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

