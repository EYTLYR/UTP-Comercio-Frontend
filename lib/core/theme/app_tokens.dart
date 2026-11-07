import 'package:flutter/material.dart';

/// Design Tokens: Spacing Scale, Concentric Radii, Soft Multilayer Shadows & Typography
/// Built adhering strictly to Emil Kowalski's Design Engineering standards.
class AppTokens {
  AppTokens._();

  // --- Spacing Scale (Base 4px / 8px grid) ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // --- Border Radii Base Tokens ---
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;

  /// Concentric Corner Radii Formula:
  /// Outer Radius = Inner Radius + Padding
  /// Prevents corner awkwardness where inner corners bulge into outer borders.
  static double concentricOuter(double innerRadius, double padding) {
    return innerRadius + padding;
  }

  static double concentricInner(double outerRadius, double padding) {
    return (outerRadius - padding).clamp(0.0, outerRadius);
  }

  static BorderRadius concentricBorderRadius(double outerRadius, double padding) {
    return BorderRadius.circular(concentricInner(outerRadius, padding));
  }

  // --- Multilayer Soft Shadows ---
  // Emil Kowalski rule: Avoid single harsh dark shadows. Use dual layers:
  // Layer 1: Ambient diffusion (broad, low opacity)
  // Layer 2: Direct keylight (sharp, minimal offset)

  static List<BoxShadow> softShadow({Color? tint, double opacity = 1.0}) {
    final baseColor = tint ?? const Color(0xFF0C1524);
    return [
      BoxShadow(
        color: baseColor.withValues(alpha: 0.03 * opacity),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: baseColor.withValues(alpha: 0.05 * opacity),
        blurRadius: 16,
        spreadRadius: -2,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> cardShadow({Color? tint, double opacity = 1.0}) {
    final baseColor = tint ?? const Color(0xFF15233A);
    return [
      BoxShadow(
        color: baseColor.withValues(alpha: 0.02 * opacity),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: baseColor.withValues(alpha: 0.04 * opacity),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.7),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.4),
        blurRadius: 24,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ];
  }

  // --- Typography Specs ---
  static const String fontFamily = 'Nunito';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
    height: 1.15,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.1,
  );
}

