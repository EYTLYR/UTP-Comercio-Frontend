import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import 'nearby_pressable.dart';

/// Zero Layout Shift Empty State built with Emil Kowalski's visual hierarchy:
/// - Centered composition with soft concentric circular icon badge
/// - Anti-jarring height constraints preventing screen content jumps
/// - Tactile primary button feedback via NearbyPressable
class NearbyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? badgeColor;
  final double minHeight;

  const NearbyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.badgeColor,
    this.minHeight = 220.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveBadgeColor = badgeColor ?? effectiveIconColor.withValues(alpha: 0.1);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space24,
            vertical: AppTokens.space32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Concentric soft icon badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: effectiveBadgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: effectiveIconColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 30,
                    color: effectiveIconColor,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTokens.titleMd.copyWith(
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: AppTokens.space6),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTokens.bodyMuted.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                ),
              ),

              // Action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppTokens.space20),
                NearbyPressable(
                  onTap: onAction,
                  scale: AppMotion.pressScale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space20,
                      vertical: AppTokens.space10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      boxShadow: AppTokens.glowShadow(
                        theme.colorScheme.primary,
                        opacity: 0.25,
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      textAlign: TextAlign.center,
                      style: AppTokens.button.copyWith(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

