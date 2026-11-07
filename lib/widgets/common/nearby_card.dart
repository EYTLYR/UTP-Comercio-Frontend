import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import 'nearby_pressable.dart';

/// Base card component built adhering strictly to Emil Kowalski's rules:
/// - Concentric outer radii (outerRadius = innerRadius + padding)
/// - Subtle 1px anti-harsh border (alpha: 0.08 - 0.12)
/// - Dual-layer soft shadow for physical realism
/// - Smooth AnimatedSize transition to avoid jarring layout pops
class NearbyCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double outerRadius;
  final List<BoxShadow>? customShadows;
  final bool animateSize;
  final Clip clipBehavior;

  const NearbyCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.outerRadius = AppTokens.radiusMd,
    this.customShadows,
    this.animateSize = true,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = backgroundColor ?? theme.cardColor;
    final defaultBorderColor = borderColor ?? theme.dividerColor.withValues(alpha: 0.12);

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: defaultBorderColor,
          width: borderWidth,
        ),
        boxShadow: customShadows ?? AppTokens.cardShadow(tint: theme.shadowColor),
      ),
      clipBehavior: clipBehavior,
      padding: padding,
      child: child,
    );

    if (animateSize) {
      content = AnimatedSize(
        duration: AppMotion.normal,
        curve: AppMotion.easeOut,
        alignment: Alignment.topCenter,
        child: content,
      );
    }

    if (onTap != null || onLongPress != null) {
      return NearbyPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        scale: AppMotion.subtlePressScale,
        child: content,
      );
    }

    return content;
  }
}

