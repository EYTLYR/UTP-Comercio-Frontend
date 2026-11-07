import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

/// Zero Layout Shift Shimmer Skeleton placeholder.
/// Built with pre-calculated bounds matching real cards, text lines, and avatar dimensions
/// to prevent jarring content jumps during asynchronous loads.
class NearbySkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry margin;

  const NearbySkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppTokens.radiusMd,
    this.shape = BoxShape.rectangle,
    this.margin = EdgeInsets.zero,
  });

  /// Skeleton for text lines
  factory NearbySkeleton.line({
    double? width,
    double height = 14.0,
    double borderRadius = AppTokens.radiusXs,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 4.0),
  }) {
    return NearbySkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }

  /// Skeleton for avatars / circles
  factory NearbySkeleton.circle({
    required double size,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return NearbySkeleton(
      width: size,
      height: size,
      shape: BoxShape.circle,
      margin: margin,
    );
  }

  /// Skeleton for a complete list card
  factory NearbySkeleton.card({
    double height = 80.0,
    double borderRadius = AppTokens.radiusMd,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(
      horizontal: AppTokens.space16,
      vertical: AppTokens.space6,
    ),
  }) {
    return NearbySkeleton(
      width: double.infinity,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }

  @override
  State<NearbySkeleton> createState() => _NearbySkeletonState();
}

class _NearbySkeletonState extends State<NearbySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _anim = Tween<double>(begin: 0.05, end: 0.13).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final baseColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;

        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _anim.value),
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

