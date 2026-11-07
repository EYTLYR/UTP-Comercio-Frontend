import 'package:flutter/widgets.dart';

/// Design Engineering Motion Tokens & Physical Constants
/// Direct implementation of Emil Kowalski's animation philosophy.
class AppMotion {
  AppMotion._();

  // --- Durations (UI actions stay under 300-350ms) ---
  /// Instant feedback for button presses, micro-taps, active state (100–160ms)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard UI transitions: dropdowns, selects, sheet reveals (180–250ms)
  static const Duration normal = Duration(milliseconds: 220);

  /// Major layout shifts, modals, drawers, toasts (250–350ms)
  static const Duration slow = Duration(milliseconds: 350);

  /// Hold-to-confirm deliberate progress (2000ms)
  static const Duration holdConfirm = Duration(milliseconds: 2000);

  /// Snappy release timing after deliberate hold (asymmetric timing)
  static const Duration holdRelease = Duration(milliseconds: 200);

  // --- Easing Curves (Custom cubic-beziers with real punch) ---
  /// Strong ease-out for UI interactions.
  /// Starts fast, decelerates gracefully: cubic-bezier(0.23, 1, 0.32, 1).
  /// Never use Curves.easeIn on UI elements.
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out for on-screen continuous morphing & movement:
  /// cubic-bezier(0.77, 0, 0.175, 1).
  static const Curve easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// iOS-like bottom sheet / drawer curve:
  /// cubic-bezier(0.32, 0.72, 0, 1).
  static const Curve drawer = Cubic(0.32, 0.72, 0.0, 1.0);

  /// Standard ease-out cubic for general transitions
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// High deceleration ease-in-out for fluid state transitions
  static const Curve easeInOutQuart = Curves.easeInOutQuart;

  // --- Scale Constants (Never scale from 0.0) ---
  /// Active button press tactile scale factor
  static const double pressScale = 0.97;

  /// Subtle press scale for small cards & icons
  static const double subtlePressScale = 0.98;

  /// Entry animation starting scale.
  /// "Nothing in the real world appears from nothing. Start from 0.95+."
  static const double enterInitialScale = 0.96;

  /// Entry animation starting translateY offset in dp
  static const double enterInitialOffsetY = 8.0;

  // --- Springs (Apple Style physical parameters) ---
  /// Apple-style responsive spring for gestures and cards (stiff, rapid settle)
  static const SpringDescription responsiveSpring = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 20.0,
  );

  /// Bouncy tactile spring for sheet dismiss and playful interactions (bounce: ~0.15)
  static const SpringDescription playfulSpring = SpringDescription(
    mass: 0.9,
    stiffness: 220.0,
    damping: 16.0,
  );

  /// Heavy drawer spring with high damping to prevent overshooting boundaries
  static const SpringDescription sheetSpring = SpringDescription(
    mass: 1.2,
    stiffness: 160.0,
    damping: 24.0,
  );

  // --- Stagger Timings ---
  /// Delay between staggered items in lists (30–60ms)
  static const int staggerDelayMs = 45;
}

