import 'package:flutter/widgets.dart';

/// Spacing scale (dp). Use these instead of ad-hoc numbers.
abstract final class Gap {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Corner radii (dp), following the Material 3 shape scale.
abstract final class Corner {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const extraLarge = 28.0;
}

/// Motion durations. Short for state changes, medium for container moves.
abstract final class Motion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const container = Duration(milliseconds: 300);

  /// [d], or zero when the user asked the system to reduce animations.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Minimum touch target on Android (dp). Material and WCAG 2.2 both ask for it.
const minTouchTarget = 48.0;
